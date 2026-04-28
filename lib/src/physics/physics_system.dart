import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/painting.dart';
import 'package:goo2d/goo2d.dart';
import 'physics_worker.dart';
import 'physics_protocol.dart';

class PhysicsSystem implements GameSystem {
  static final _workerReceivePort = ReceivePort();
  static SendPort? _workerSendPort;
  static bool _workerInitializing = false;
  static bool _isListening = false;
  static int _nextWorldId = 1;
  static final Map<int, PhysicsSystem> _instances = {};

  final Map<int, Rigidbody> _rigidbodies = {};
  final Map<int, Collider> _colliders = {};
  final Map<GameObject, int> _standaloneBodyIds = {};
  final Map<int, int> _bodyColliderCount = {};
  final Map<int, Completer<RaycastHit?>> _raycastCompleters = {};
  final List<ByteData> _pendingMessages = [];

  /// Set of shape ID pairs that were contacting in the last frame.
  final Set<String> _previousContacts = {};

  int _nextId = 1;
  int _nextRequestId = 1;
  int worldId = 0;

  Iterable<Collider> get activeColliders => _colliders.values;

  double fixedTimeStep = 1.0 / 50.0; // 50Hz default
  double _accumulator = 0.0;

  Offset _gravity = const Offset(0, 980);
  Offset get gravity => _gravity;
  set gravity(Offset value) {
    if (_gravity == value) return;
    _gravity = value;
    final buf = PhysicsBuffer.fixed(13);
    buf.writeUint8(PhysicsPacket.setGravity);
    buf.writeInt32(worldId);
    buf.writeFloat32(value.dx);
    buf.writeFloat32(value.dy);
    _sendToWorker(buf.data);
  }

  GameEngine? _game;
  @override
  GameEngine get game => _game!;
  @override
  bool get gameAttached => _game != null;

  @override
  void attach(GameEngine game) {
    _game = game;
    worldId = _nextWorldId++;
    _instances[worldId] = this;
    _ensureWorkerStarted();
  }

  Future<void> _ensureWorkerStarted() async {
    if (_workerSendPort != null) {
      _sendCreateWorld();
      return;
    }

    if (_workerInitializing) {
      // Worker is already starting, just send createWorld (it will be buffered)
      _sendCreateWorld();
      return;
    }

    _workerInitializing = true;
    _sendCreateWorld(); // Buffer it

    if (!_isListening) {
      _isListening = true;
      _workerReceivePort.listen((message) {
        if (message is SendPort) {
          _workerSendPort = message;
          _workerInitializing = false;
          // Flush pending messages for all instances
          for (final system in _instances.values) {
            system._flushPendingMessages();
          }
          return;
        }

        if (message is ByteData) {
          final buffer = PhysicsBuffer(message);
          final packetId = buffer.readUint8();
          final wId = buffer.readInt32();

          final system = _instances[wId];
          if (system != null) {
            if (packetId == PhysicsPacket.stepResult) {
              system._handleBinaryStepResult(buffer);
            } else if (packetId == PhysicsPacket.raycastResult) {
              system._handleBinaryRaycastResult(buffer);
            }
          }
        }
      });
    }

    await Isolate.spawn(physicsWorkerEntry, _workerReceivePort.sendPort);
  }

  void _sendCreateWorld() {
    final buf = PhysicsBuffer.fixed(5);
    buf.writeUint8(PhysicsPacket.createWorld);
    buf.writeInt32(worldId);
    _sendToWorker(buf.data);
  }

  void _flushPendingMessages() {
    if (_workerSendPort == null) return;
    for (final data in _pendingMessages) {
      _workerSendPort!.send(data);
    }
    _pendingMessages.clear();
  }

  void _handleBinaryStepResult(PhysicsBuffer buffer) {
    final bodyCount = buffer.readInt32();
    for (int i = 0; i < bodyCount; i++) {
      final id = buffer.readInt32();
      final px = buffer.readFloat32();
      final py = buffer.readFloat32();
      final rot = buffer.readFloat32();
      final vx = buffer.readFloat32();
      final vy = buffer.readFloat32();
      final av = buffer.readFloat32();
      final body = _rigidbodies[id];
      if (body != null) {
        body.internalSetVelocity(Offset(vx, vy), av);
        final t = body.tryTransform;
        if (t != null) {
          t.position = Offset(px, py);
          t.angle = rot;
        }
      }
    }

    final contactCount = buffer.readInt32();
    final Set<String> currentContactKeys = {};

    for (int i = 0; i < contactCount; i++) {
      final sAId = buffer.readInt32();
      final sBId = buffer.readInt32();
      final px = buffer.readFloat32();
      final py = buffer.readFloat32();
      final nx = buffer.readFloat32();
      final ny = buffer.readFloat32();
      final impulse = buffer.readFloat32();

      final key = sAId < sBId ? '$sAId:$sBId' : '$sBId:$sAId';
      currentContactKeys.add(key);

      final sA = _colliders[sAId];
      final sB = _colliders[sBId];
      if (sA == null || sB == null) continue;

      final isTrigger = sA.isTrigger || sB.isTrigger;
      final isNew = !_previousContacts.contains(key);

      if (isTrigger) {
        final state = isNew ? CollisionState.enter : CollisionState.stay;
        sA.gameObject.broadcastEvent(TriggerEvent(sA, sB, state));
        sB.gameObject.broadcastEvent(TriggerEvent(sB, sA, state));
      } else {
        final state = isNew ? CollisionState.enter : CollisionState.stay;
        final colA = Collision(
          collider: sA,
          otherCollider: sB,
          gameObject: sB.gameObject,
          rigidbody: sB.gameObject.tryGetComponent<Rigidbody>(),
          contactPoint: Offset(px, py),
          normal: Offset(nx, ny),
          impulse: impulse,
        );
        final colB = Collision(
          collider: sB,
          otherCollider: sA,
          gameObject: sA.gameObject,
          rigidbody: sA.gameObject.tryGetComponent<Rigidbody>(),
          contactPoint: Offset(px, py),
          normal: Offset(-nx, -ny),
          impulse: impulse,
        );
        sA.gameObject.broadcastEvent(CollisionEvent(colA, state));
        sB.gameObject.broadcastEvent(CollisionEvent(colB, state));
      }
    }

    // Check for exits
    for (final key in _previousContacts) {
      if (!currentContactKeys.contains(key)) {
        final ids = key.split(':');
        final sAId = int.parse(ids[0]);
        final sBId = int.parse(ids[1]);
        final sA = _colliders[sAId];
        final sB = _colliders[sBId];
        if (sA == null || sB == null) continue;

        if (sA.isTrigger || sB.isTrigger) {
          sA.gameObject.broadcastEvent(
            TriggerEvent(sA, sB, CollisionState.exit),
          );
          sB.gameObject.broadcastEvent(
            TriggerEvent(sB, sA, CollisionState.exit),
          );
        } else {
          final colA = Collision(
            collider: sA,
            otherCollider: sB,
            gameObject: sB.gameObject,
            rigidbody: sB.gameObject.tryGetComponent<Rigidbody>(),
            contactPoint: Offset.zero,
            normal: Offset.zero,
            impulse: 0,
          );
          final colB = Collision(
            collider: sB,
            otherCollider: sA,
            gameObject: sA.gameObject,
            rigidbody: sA.gameObject.tryGetComponent<Rigidbody>(),
            contactPoint: Offset.zero,
            normal: Offset.zero,
            impulse: 0,
          );
          sA.gameObject.broadcastEvent(
            CollisionEvent(colA, CollisionState.exit),
          );
          sB.gameObject.broadcastEvent(
            CollisionEvent(colB, CollisionState.exit),
          );
        }
      }
    }

    _previousContacts.clear();
    _previousContacts.addAll(currentContactKeys);
  }

  void _handleBinaryRaycastResult(PhysicsBuffer buffer) {
    final requestId = buffer.readInt32();
    final hasHit = buffer.readBool();
    final completer = _raycastCompleters.remove(requestId);
    if (completer == null) return;

    if (!hasHit) {
      completer.complete(null);
    } else {
      final colliderId = buffer.readInt32();
      final px = buffer.readFloat32();
      final py = buffer.readFloat32();
      final nx = buffer.readFloat32();
      final ny = buffer.readFloat32();
      final dist = buffer.readFloat32();
      final frac = buffer.readFloat32();

      final collider = _colliders[colliderId];
      if (collider != null) {
        completer.complete(
          RaycastHit(
            collider: collider,
            point: Offset(px, py),
            normal: Offset(nx, ny),
            distance: dist,
            fraction: frac,
          ),
        );
      } else {
        completer.complete(null);
      }
    }
  }

  void registerRigidbody(Rigidbody body) {
    final t = body.tryTransform;
    if (t == null) return;

    final id = _nextId++;
    _rigidbodies[id] = body;

    final buf = PhysicsBuffer.fixed(42);
    buf.writeUint8(PhysicsPacket.addBody);
    buf.writeInt32(worldId);
    buf.writeInt32(id);
    buf.writeUint8(body.type.index);
    buf.writeFloat32(body.mass);
    buf.writeFloat32(body.drag);
    buf.writeFloat32(body.angularDrag);
    buf.writeBool(body.freezeRotation);
    buf.writeFloat32(body.gravityScale);
    buf.writeFloat32(t.position.dx);
    buf.writeFloat32(t.position.dy);
    buf.writeFloat32(t.angle);
    _sendToWorker(buf.data);
  }

  void unregisterRigidbody(Rigidbody body) {
    final id = _rigidbodies.keys.firstWhere(
      (k) => _rigidbodies[k] == body,
      orElse: () => -1,
    );
    if (id != -1) {
      _rigidbodies.remove(id);
      final buf = PhysicsBuffer.fixed(9);
      buf.writeUint8(PhysicsPacket.removeBody);
      buf.writeInt32(worldId);
      buf.writeInt32(id);
      _sendToWorker(buf.data);
    }
  }

  void updateRigidbody(Rigidbody body) {
    final id = _rigidbodies.keys.firstWhere(
      (k) => _rigidbodies[k] == body,
      orElse: () => -1,
    );
    if (id != -1) {
      final buf = PhysicsBuffer.fixed(30);
      buf.writeUint8(PhysicsPacket.updateBody);
      buf.writeInt32(worldId);
      buf.writeInt32(id);
      buf.writeFloat32(body.mass);
      buf.writeFloat32(body.drag);
      buf.writeFloat32(body.angularDrag);
      buf.writeBool(body.freezeRotation);
      buf.writeFloat32(body.gravityScale);
      _sendToWorker(buf.data);
    }
  }

  void internalSyncVelocity(Rigidbody body, Offset velocity) {
    final id = _rigidbodies.keys.firstWhere(
      (k) => _rigidbodies[k] == body,
      orElse: () => -1,
    );
    if (id != -1) {
      final buf = PhysicsBuffer.fixed(17);
      buf.writeUint8(PhysicsPacket.syncVelocity);
      buf.writeInt32(worldId);
      buf.writeInt32(id);
      buf.writeFloat32(velocity.dx);
      buf.writeFloat32(velocity.dy);
      _sendToWorker(buf.data);
    }
  }

  void internalSyncAngularVelocity(Rigidbody body, double angularVelocity) {
    final id = _rigidbodies.keys.firstWhere(
      (k) => _rigidbodies[k] == body,
      orElse: () => -1,
    );
    if (id != -1) {
      final buf = PhysicsBuffer.fixed(13);
      buf.writeUint8(PhysicsPacket.syncAngularVelocity);
      buf.writeInt32(worldId);
      buf.writeInt32(id);
      buf.writeFloat32(angularVelocity);
      _sendToWorker(buf.data);
    }
  }

  int _createStandaloneBody(GameObject go) {
    final id = _nextId++;
    final t = go.tryGetComponent<ObjectTransform>();

    final buf = PhysicsBuffer.fixed(42);
    buf.writeUint8(PhysicsPacket.addBody);
    buf.writeInt32(worldId);
    buf.writeInt32(id);
    buf.writeUint8(2); // Static type
    buf.writeFloat32(1.0); // Mass
    buf.writeFloat32(0.0); // Drag
    buf.writeFloat32(0.05); // Angular drag
    buf.writeBool(false); // Freeze rotation
    buf.writeFloat32(1.0); // Gravity scale
    buf.writeFloat32(t?.position.dx ?? 0.0);
    buf.writeFloat32(t?.position.dy ?? 0.0);
    buf.writeFloat32(t?.angle ?? 0.0);
    _sendToWorker(buf.data);

    return id;
  }

  void _removeStandaloneBody(int bodyId) {
    final buf = PhysicsBuffer.fixed(9);
    buf.writeUint8(PhysicsPacket.removeBody);
    buf.writeInt32(worldId);
    buf.writeInt32(bodyId);
    _sendToWorker(buf.data);
  }

  void registerCollider(Collider collider) {
    final id = _nextId++;
    _colliders[id] = collider;

    final rb = collider.gameObject.tryGetComponent<Rigidbody>();
    int rbId = -1;
    if (rb != null) {
      rbId = _rigidbodies.keys.firstWhere(
        (k) => _rigidbodies[k] == rb,
        orElse: () => -1,
      );
    }

    if (rbId == -1) {
      // Use or create a standalone static body for this GameObject
      rbId = _standaloneBodyIds[collider.gameObject] ??=
          _createStandaloneBody(collider.gameObject);
      _bodyColliderCount[rbId] = (_bodyColliderCount[rbId] ?? 0) + 1;
    }

    // Use a larger buffer for polygons
    int bufferSize = 100;
    if (collider is PolygonCollider) {
      bufferSize += collider.vertices.length * 8;
    }

    final buf = PhysicsBuffer.fixed(bufferSize);
    buf.writeUint8(PhysicsPacket.addShape);
    buf.writeInt32(worldId);
    buf.writeInt32(id);
    buf.writeInt32(rbId);
    buf.writeBool(collider.isTrigger);
    buf.writeFloat32(collider.offset.dx);
    buf.writeFloat32(collider.offset.dy);
    buf.writeFloat32(collider.material.bounciness);
    buf.writeFloat32(collider.material.friction);

    if (collider is BoxCollider) {
      buf.writeUint8(0);
      buf.writeFloat32(collider.size.width);
      buf.writeFloat32(collider.size.height);
    } else if (collider is CircleCollider) {
      buf.writeUint8(1);
      buf.writeFloat32(collider.radius);
    } else if (collider is PolygonCollider) {
      buf.writeUint8(2);
      buf.writeInt32(collider.vertices.length);
      for (final v in collider.vertices) {
        buf.writeFloat32(v.dx);
        buf.writeFloat32(v.dy);
      }
    } else if (collider is CapsuleCollider) {
      buf.writeUint8(3);
      buf.writeFloat32(collider.radius);
      buf.writeFloat32(collider.height);
      buf.writeUint8(collider.direction.index);
    }

    _sendToWorker(buf.data);
  }

  void unregisterCollider(Collider collider) {
    final id = _colliders.keys.firstWhere(
      (k) => _colliders[k] == collider,
      orElse: () => -1,
    );
    if (id != -1) {
      _colliders.remove(id);

      // Cleanup standalone body if it's no longer used
      final bodyId = _standaloneBodyIds[collider.gameObject];
      if (bodyId != null) {
        final count = (_bodyColliderCount[bodyId] ?? 0) - 1;
        if (count <= 0) {
          _standaloneBodyIds.remove(collider.gameObject);
          _bodyColliderCount.remove(bodyId);
          _removeStandaloneBody(bodyId);
        } else {
          _bodyColliderCount[bodyId] = count;
        }
      }

      final buf = PhysicsBuffer.fixed(9);
      buf.writeUint8(PhysicsPacket.removeShape);
      buf.writeInt32(worldId);
      buf.writeInt32(id);
      _sendToWorker(buf.data);
    }
  }

  void step(double dt) {
    _accumulator += dt;
    while (_accumulator >= fixedTimeStep) {
      _internalStep(fixedTimeStep);
      _accumulator -= fixedTimeStep;
    }
  }

  void _internalStep(double dt) {
    final kinematics = _rigidbodies.entries.where((e) {
      if (!e.value.isKinematic) return false;
      return e.value.tryTransform != null;
    }).toList();

    final standalones = _standaloneBodyIds.entries.toList();

    final buf = PhysicsBuffer.fixed(
      13 + (kinematics.length + standalones.length) * 16,
    );
    buf.writeUint8(PhysicsPacket.step);
    buf.writeInt32(worldId);
    buf.writeFloat32(dt);
    buf.writeInt32(kinematics.length + standalones.length);

    for (final e in kinematics) {
      final t = e.value.transform;
      buf.writeInt32(e.key);
      buf.writeFloat32(t.position.dx);
      buf.writeFloat32(t.position.dy);
      buf.writeFloat32(t.angle);
    }

    for (final e in standalones) {
      final t = e.key.tryGetComponent<ObjectTransform>();
      buf.writeInt32(e.value);
      buf.writeFloat32(t?.position.dx ?? 0.0);
      buf.writeFloat32(t?.position.dy ?? 0.0);
      buf.writeFloat32(t?.angle ?? 0.0);
    }

    _sendToWorker(buf.data);
  }

  void _sendToWorker(ByteData data) {
    if (_workerSendPort != null) {
      _workerSendPort!.send(data);
    } else {
      _pendingMessages.add(data);
    }
  }

  void internalQueueForce(Rigidbody body, Offset force) {
    final id = _rigidbodies.keys.firstWhere(
      (k) => _rigidbodies[k] == body,
      orElse: () => -1,
    );
    if (id != -1) {
      final buf = PhysicsBuffer.fixed(17);
      buf.writeUint8(PhysicsPacket.applyForce);
      buf.writeInt32(worldId);
      buf.writeInt32(id);
      buf.writeFloat32(force.dx);
      buf.writeFloat32(force.dy);
      _sendToWorker(buf.data);
    }
  }

  void internalQueueImpulse(Rigidbody body, Offset impulse) {
    final id = _rigidbodies.keys.firstWhere(
      (k) => _rigidbodies[k] == body,
      orElse: () => -1,
    );
    if (id != -1) {
      final buf = PhysicsBuffer.fixed(17);
      buf.writeUint8(PhysicsPacket.applyImpulse);
      buf.writeInt32(worldId);
      buf.writeInt32(id);
      buf.writeFloat32(impulse.dx);
      buf.writeFloat32(impulse.dy);
      _sendToWorker(buf.data);
    }
  }

  void internalQueueTorque(Rigidbody body, double torque) {
    final id = _rigidbodies.keys.firstWhere(
      (k) => _rigidbodies[k] == body,
      orElse: () => -1,
    );
    if (id != -1) {
      final buf = PhysicsBuffer.fixed(13);
      buf.writeUint8(PhysicsPacket.applyTorque);
      buf.writeInt32(worldId);
      buf.writeInt32(id);
      buf.writeFloat32(torque);
      _sendToWorker(buf.data);
    }
  }

  void internalQueueAngularImpulse(Rigidbody body, double impulse) {
    final id = _rigidbodies.keys.firstWhere(
      (k) => _rigidbodies[k] == body,
      orElse: () => -1,
    );
    if (id != -1) {
      final buf = PhysicsBuffer.fixed(13);
      buf.writeUint8(PhysicsPacket.applyAngularImpulse);
      buf.writeInt32(worldId);
      buf.writeInt32(id);
      buf.writeFloat32(impulse);
      _sendToWorker(buf.data);
    }
  }

  Future<RaycastHit?> raycast(
    Offset origin,
    Offset direction, [
    double maxDistance = double.infinity,
  ]) async {
    final requestId = _nextRequestId++;
    final completer = Completer<RaycastHit?>();
    _raycastCompleters[requestId] = completer;

    final buf = PhysicsBuffer.fixed(29);
    buf.writeUint8(PhysicsPacket.raycast);
    buf.writeInt32(worldId);
    buf.writeInt32(requestId);
    buf.writeFloat32(origin.dx);
    buf.writeFloat32(origin.dy);
    buf.writeFloat32(direction.dx);
    buf.writeFloat32(direction.dy);
    buf.writeFloat32(maxDistance);
    _sendToWorker(buf.data);

    return completer.future;
  }

  @override
  void dispose() {
    _instances.remove(worldId);
    final buf = PhysicsBuffer.fixed(5);
    buf.writeUint8(PhysicsPacket.destroyWorld);
    buf.writeInt32(worldId);
    _sendToWorker(buf.data);
    _rigidbodies.clear();
    _colliders.clear();
    _raycastCompleters.clear();
    _pendingMessages.clear();
  }
}
