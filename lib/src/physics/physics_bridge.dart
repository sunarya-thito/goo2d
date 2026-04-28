import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'physics_world.dart';
import 'physics_protocol.dart';
import 'rigidbody.dart';
import 'collider.dart';
import 'physics_worker.dart';

/// Standardized contact data returned by all bridges.
class PhysicsContactData {
  final int shapeAId;
  final int shapeBId;
  final Offset contactPoint;
  final Offset normal;
  final double depth;
  final double impulse;

  PhysicsContactData({
    required this.shapeAId,
    required this.shapeBId,
    required this.contactPoint,
    required this.normal,
    required this.depth,
    required this.impulse,
  });
}

/// Result of a physics step.
class PhysicsStepResult {
  final List<PhysicsContactData> contacts;
  final Map<int, PhysicsBodyState> dynamicBodies;

  PhysicsStepResult({
    required this.contacts,
    required this.dynamicBodies,
  });
}

class PhysicsBodyState {
  final Offset position;
  final double rotation;
  final Offset velocity;
  final double angularVelocity;

  PhysicsBodyState({
    required this.position,
    required this.rotation,
    required this.velocity,
    required this.angularVelocity,
  });
}

class PhysicsTransformSync {
  final Offset position;
  final double rotation;
  PhysicsTransformSync(this.position, this.rotation);
}

/// Abstract bridge between PhysicsSystem and the PhysicsWorld.
abstract class PhysicsBridge {
  Future<void> init(int worldId, void Function(PhysicsStepResult) onStepResult,
      void Function(int, bool, PhysicsRaycastHitData?) onRaycastResult);

  void createWorld();
  void destroyWorld();

  void addBody(
    int id,
    RigidbodyType type, {
    double mass = 1.0,
    double drag = 0.0,
    double angularDrag = 0.05,
    bool freezeRotation = false,
    double gravityScale = 1.0,
    Offset position = Offset.zero,
    double rotation = 0.0,
  });

  void removeBody(int id);

  void updateBody(
    int id, {
    double mass = 1.0,
    double drag = 0.0,
    double angularDrag = 0.05,
    bool freezeRotation = false,
    double gravityScale = 1.0,
  });

  void addShape(int id, int bodyId, Collider collider);
  void removeShape(int id);

  void applyForce(int bodyId, Offset force);
  void applyImpulse(int bodyId, Offset impulse);
  void applyTorque(int bodyId, double torque);
  void applyAngularImpulse(int bodyId, double impulse);

  void setGravity(Offset gravity);
  void syncVelocity(int bodyId, Offset velocity);
  void syncAngularVelocity(int bodyId, double velocity);

  void step(double dt, Map<int, PhysicsTransformSync> sync);
  void raycast(
      int requestId, Offset origin, Offset direction, double maxDistance);
}

class PhysicsRaycastHitData {
  final int shapeId;
  final Offset point;
  final Offset normal;
  final double distance;
  final double fraction;

  PhysicsRaycastHitData({
    required this.shapeId,
    required this.point,
    required this.normal,
    required this.distance,
    required this.fraction,
  });
}

/// Implementation of PhysicsBridge that calls PhysicsWorld directly.
/// Used on Web and for debugging.
class DirectPhysicsBridge implements PhysicsBridge {
  late final PhysicsWorld _world;
  late void Function(PhysicsStepResult) _onStepResult;
  late void Function(int, bool, PhysicsRaycastHitData?) _onRaycastResult;

  @override
  Future<void> init(
      int worldId,
      void Function(PhysicsStepResult) onStepResult,
      void Function(int, bool, PhysicsRaycastHitData?) onRaycastResult) {
    _onStepResult = onStepResult;
    _onRaycastResult = onRaycastResult;
    _world = PhysicsWorld();
    return Future.value();
  }

  @override
  void createWorld() {
    // Already created in init
  }

  @override
  void destroyWorld() {
    _world.bodies.clear();
  }

  @override
  void addBody(int id, RigidbodyType type,
      {double mass = 1.0,
      double drag = 0.0,
      double angularDrag = 0.05,
      bool freezeRotation = false,
      double gravityScale = 1.0,
      Offset position = Offset.zero,
      double rotation = 0.0}) {
    final body = PhysicsBody(id: id, type: type.index);
    body.setMass(mass);
    body.drag = drag;
    body.angularDrag = angularDrag;
    body.freezeRotation = freezeRotation;
    body.gravityScale = gravityScale;
    body.position = position;
    body.rotation = rotation;
    _world.bodies[id] = body;
  }

  @override
  void removeBody(int id) {
    _world.bodies.remove(id);
  }

  @override
  void updateBody(int id,
      {double mass = 1.0,
      double drag = 0.0,
      double angularDrag = 0.05,
      bool freezeRotation = false,
      double gravityScale = 1.0}) {
    final body = _world.bodies[id];
    if (body != null) {
      body.setMass(mass);
      body.drag = drag;
      body.angularDrag = angularDrag;
      body.freezeRotation = freezeRotation;
      body.gravityScale = gravityScale;
    }
  }

  @override
  void addShape(int id, int bodyId, Collider collider) {
    final body = _world.bodies[bodyId];
    if (body == null) return;

    PhysicsShape shape;
    if (collider is BoxCollider) {
      shape = PhysicsBox(collider.size.width, collider.size.height);
    } else if (collider is CircleCollider) {
      shape = PhysicsCircle(collider.radius);
    } else if (collider is PolygonCollider) {
      shape = PhysicsPolygon(collider.vertices);
    } else if (collider is CapsuleCollider) {
      shape = PhysicsCapsule(
          collider.radius, collider.height, collider.direction == CapsuleDirection.vertical);
    } else {
      return;
    }

    shape.id = id;
    shape.isTrigger = collider.isTrigger;
    shape.localOffset = collider.offset;
    shape.bounciness = collider.material.bounciness;
    shape.friction = collider.material.friction;
    shape.body = body;
  }

  @override
  void removeShape(int id) {
    for (final body in _world.bodies.values) {
      body.shapes.removeWhere((s) => s.id == id);
    }
  }

  @override
  void applyForce(int bodyId, Offset force) {
    _world.bodies[bodyId]?.applyForce(force);
  }

  @override
  void applyImpulse(int bodyId, Offset impulse) {
    _world.bodies[bodyId]?.applyImpulse(impulse);
  }

  @override
  void applyTorque(int bodyId, double torque) {
    _world.bodies[bodyId]?.applyTorque(torque);
  }

  @override
  void applyAngularImpulse(int bodyId, double impulse) {
    _world.bodies[bodyId]?.applyAngularImpulse(impulse);
  }

  @override
  void setGravity(Offset gravity) {
    _world.gravity = gravity;
  }

  @override
  void syncVelocity(int bodyId, Offset velocity) {
    final body = _world.bodies[bodyId];
    if (body != null) {
      body.velocity = velocity;
    }
  }

  @override
  void syncAngularVelocity(int bodyId, double velocity) {
    final body = _world.bodies[bodyId];
    if (body != null) {
      body.angularVelocity = velocity;
    }
  }

  @override
  void step(double dt, Map<int, PhysicsTransformSync> sync) {
    // 1. Sync transforms
    for (final entry in sync.entries) {
      final body = _world.bodies[entry.key];
      if (body != null) {
        body.position = entry.value.position;
        body.rotation = entry.value.rotation;
      }
    }

    // 2. Perform step
    final result = _world.step(dt);

    // 3. Prepare response
    final contacts = result.contacts
        .map((c) => PhysicsContactData(
              shapeAId: c.shapeAId,
              shapeBId: c.shapeBId,
              contactPoint: c.manifold.contactPoint,
              normal: c.manifold.normal,
              depth: c.manifold.depth,
              impulse: c.impulse,
            ))
        .toList();

    final dynamicBodies = <int, PhysicsBodyState>{};
    for (final body in _world.bodies.values) {
      if (body.type == 0) {
        // dynamic
        dynamicBodies[body.id] = PhysicsBodyState(
          position: body.position,
          rotation: body.rotation,
          velocity: body.velocity,
          angularVelocity: body.angularVelocity,
        );
      }
    }

    _onStepResult(PhysicsStepResult(
      contacts: contacts,
      dynamicBodies: dynamicBodies,
    ));
  }

  @override
  void raycast(
      int requestId, Offset origin, Offset direction, double maxDistance) {
    final hit = _world.raycast(origin, direction, maxDistance);
    if (hit != null) {
      _onRaycastResult(
          requestId,
          true,
          PhysicsRaycastHitData(
            shapeId: hit.shapeId,
            point: hit.point,
            normal: hit.normal,
            distance: hit.distance,
            fraction: hit.fraction,
          ));
    } else {
      _onRaycastResult(requestId, false, null);
    }
  }
}

/// Implementation of PhysicsBridge that uses an Isolate worker.
/// Used on Native platforms.
class WorkerPhysicsBridge extends PhysicsBridge {
  late int _worldId;
  late void Function(PhysicsStepResult) _onStepResult;
  late void Function(int, bool, PhysicsRaycastHitData?) _onRaycastResult;

  final ReceivePort _receivePort = ReceivePort();
  SendPort? _sendPort;
  bool _initialized = false;
  final List<ByteData> _pendingMessages = [];

  @override
  Future<void> init(int worldId, void Function(PhysicsStepResult) onStepResult,
      void Function(int, bool, PhysicsRaycastHitData?) onRaycastResult) async {
    _worldId = worldId;
    _onStepResult = onStepResult;
    _onRaycastResult = onRaycastResult;

    _receivePort.listen(_handleMessage);

    await Isolate.spawn(physicsWorkerEntry, _receivePort.sendPort);
  }

  void _handleMessage(dynamic message) {
    if (message is SendPort) {
      _sendPort = message;
      _initialized = true;
      for (final msg in _pendingMessages) {
        _sendPort!.send(msg);
      }
      _pendingMessages.clear();
      return;
    }

    if (message is ByteData) {
      final buffer = PhysicsBuffer(message);
      final packetId = buffer.readUint8();
      final wId = buffer.readInt32();

      if (wId != _worldId) return;

      if (packetId == PhysicsPacket.stepResult) {
        _handleStepResult(buffer);
      } else if (packetId == PhysicsPacket.raycastResult) {
        _handleRaycastResult(buffer);
      }
    }
  }

  void _handleStepResult(PhysicsBuffer buffer) {
    final bodyCount = buffer.readInt32();
    final dynamicBodies = <int, PhysicsBodyState>{};
    for (int i = 0; i < bodyCount; i++) {
      final id = buffer.readInt32();
      final px = buffer.readFloat32();
      final py = buffer.readFloat32();
      final rot = buffer.readFloat32();
      final vx = buffer.readFloat32();
      final vy = buffer.readFloat32();
      final av = buffer.readFloat32();
      dynamicBodies[id] = PhysicsBodyState(
        position: Offset(px, py),
        rotation: rot,
        velocity: Offset(vx, vy),
        angularVelocity: av,
      );
    }

    final contactCount = buffer.readInt32();
    final contacts = <PhysicsContactData>[];
    for (int i = 0; i < contactCount; i++) {
      final sAId = buffer.readInt32();
      final sBId = buffer.readInt32();
      final px = buffer.readFloat32();
      final py = buffer.readFloat32();
      final nx = buffer.readFloat32();
      final ny = buffer.readFloat32();
      final impulse = buffer.readFloat32();
      contacts.add(PhysicsContactData(
        shapeAId: sAId,
        shapeBId: sBId,
        contactPoint: Offset(px, py),
        normal: Offset(nx, ny),
        depth: 0, // Not currently sent back by worker, but could be added
        impulse: impulse,
      ));
    }

    _onStepResult(PhysicsStepResult(
      contacts: contacts,
      dynamicBodies: dynamicBodies,
    ));
  }

  void _handleRaycastResult(PhysicsBuffer buffer) {
    final requestId = buffer.readInt32();
    final hasHit = buffer.readBool();
    if (hasHit) {
      final shapeId = buffer.readInt32();
      final px = buffer.readFloat32();
      final py = buffer.readFloat32();
      final nx = buffer.readFloat32();
      final ny = buffer.readFloat32();
      final dist = buffer.readFloat32();
      final frac = buffer.readFloat32();
      _onRaycastResult(
          requestId,
          true,
          PhysicsRaycastHitData(
            shapeId: shapeId,
            point: Offset(px, py),
            normal: Offset(nx, ny),
            distance: dist,
            fraction: frac,
          ));
    } else {
      _onRaycastResult(requestId, false, null);
    }
  }

  void _send(ByteData data) {
    if (!_initialized) {
      _pendingMessages.add(data);
    } else {
      _sendPort!.send(data);
    }
  }

  @override
  void createWorld() {
    final buf = PhysicsBuffer.fixed(5);
    buf.writeUint8(PhysicsPacket.createWorld);
    buf.writeInt32(_worldId);
    _send(buf.data);
  }

  @override
  void destroyWorld() {
    final buf = PhysicsBuffer.fixed(5);
    buf.writeUint8(PhysicsPacket.destroyWorld);
    buf.writeInt32(_worldId);
    _send(buf.data);
  }

  @override
  void addBody(int id, RigidbodyType type,
      {double mass = 1.0,
      double drag = 0.0,
      double angularDrag = 0.05,
      bool freezeRotation = false,
      double gravityScale = 1.0,
      Offset position = Offset.zero,
      double rotation = 0.0}) {
    final buf = PhysicsBuffer.fixed(42);
    buf.writeUint8(PhysicsPacket.addBody);
    buf.writeInt32(_worldId);
    buf.writeInt32(id);
    buf.writeUint8(type.index);
    buf.writeFloat32(mass);
    buf.writeFloat32(drag);
    buf.writeFloat32(angularDrag);
    buf.writeBool(freezeRotation);
    buf.writeFloat32(gravityScale);
    buf.writeFloat32(position.dx);
    buf.writeFloat32(position.dy);
    buf.writeFloat32(rotation);
    _send(buf.data);
  }

  @override
  void removeBody(int id) {
    final buf = PhysicsBuffer.fixed(9);
    buf.writeUint8(PhysicsPacket.removeBody);
    buf.writeInt32(_worldId);
    buf.writeInt32(id);
    _send(buf.data);
  }

  @override
  void updateBody(int id,
      {double mass = 1.0,
      double drag = 0.0,
      double angularDrag = 0.05,
      bool freezeRotation = false,
      double gravityScale = 1.0}) {
    final buf = PhysicsBuffer.fixed(26);
    buf.writeUint8(PhysicsPacket.updateBody);
    buf.writeInt32(_worldId);
    buf.writeInt32(id);
    buf.writeFloat32(mass);
    buf.writeFloat32(drag);
    buf.writeFloat32(angularDrag);
    buf.writeBool(freezeRotation);
    buf.writeFloat32(gravityScale);
    _send(buf.data);
  }

  @override
  void addShape(int id, int bodyId, Collider collider) {
    // Calculate required size
    int size = 1 + 4 + 4 + 4 + 1 + 4 + 4 + 4 + 4 + 1; // Base fields + shape type
    if (collider is BoxCollider) {
      size += 8;
    } else if (collider is CircleCollider) {
      size += 4;
    } else if (collider is PolygonCollider) {
      size += 4 + (collider.vertices.length * 8);
    } else if (collider is CapsuleCollider) {
      size += 4 + 4 + 1;
    }

    final buf = PhysicsBuffer.fixed(size);
    buf.writeUint8(PhysicsPacket.addShape);
    buf.writeInt32(_worldId);
    buf.writeInt32(id);
    buf.writeInt32(bodyId);
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
      buf.writeUint8(collider.direction == CapsuleDirection.vertical ? 1 : 0);
    }
    _send(buf.data);
  }

  @override
  void removeShape(int id) {
    final buf = PhysicsBuffer.fixed(9);
    buf.writeUint8(PhysicsPacket.removeShape);
    buf.writeInt32(_worldId);
    buf.writeInt32(id);
    _send(buf.data);
  }

  @override
  void applyForce(int bodyId, Offset force) {
    final buf = PhysicsBuffer.fixed(17);
    buf.writeUint8(PhysicsPacket.applyForce);
    buf.writeInt32(_worldId);
    buf.writeInt32(bodyId);
    buf.writeFloat32(force.dx);
    buf.writeFloat32(force.dy);
    _send(buf.data);
  }

  @override
  void applyImpulse(int bodyId, Offset impulse) {
    final buf = PhysicsBuffer.fixed(17);
    buf.writeUint8(PhysicsPacket.applyImpulse);
    buf.writeInt32(_worldId);
    buf.writeInt32(bodyId);
    buf.writeFloat32(impulse.dx);
    buf.writeFloat32(impulse.dy);
    _send(buf.data);
  }

  @override
  void applyTorque(int bodyId, double torque) {
    final buf = PhysicsBuffer.fixed(13);
    buf.writeUint8(PhysicsPacket.applyTorque);
    buf.writeInt32(_worldId);
    buf.writeInt32(bodyId);
    buf.writeFloat32(torque);
    _send(buf.data);
  }

  @override
  void applyAngularImpulse(int bodyId, double impulse) {
    final buf = PhysicsBuffer.fixed(13);
    buf.writeUint8(PhysicsPacket.applyAngularImpulse);
    buf.writeInt32(_worldId);
    buf.writeInt32(bodyId);
    buf.writeFloat32(impulse);
    _send(buf.data);
  }

  @override
  void setGravity(Offset gravity) {
    final buf = PhysicsBuffer.fixed(13);
    buf.writeUint8(PhysicsPacket.setGravity);
    buf.writeInt32(_worldId);
    buf.writeFloat32(gravity.dx);
    buf.writeFloat32(gravity.dy);
    _send(buf.data);
  }

  @override
  void syncVelocity(int bodyId, Offset velocity) {
    final buf = PhysicsBuffer.fixed(17);
    buf.writeUint8(PhysicsPacket.syncVelocity);
    buf.writeInt32(_worldId);
    buf.writeInt32(bodyId);
    buf.writeFloat32(velocity.dx);
    buf.writeFloat32(velocity.dy);
    _send(buf.data);
  }

  @override
  void syncAngularVelocity(int bodyId, double velocity) {
    final buf = PhysicsBuffer.fixed(13);
    buf.writeUint8(PhysicsPacket.syncAngularVelocity);
    buf.writeInt32(_worldId);
    buf.writeInt32(bodyId);
    buf.writeFloat32(velocity);
    _send(buf.data);
  }

  @override
  void step(double dt, Map<int, PhysicsTransformSync> sync) {
    final buf =
        PhysicsBuffer.fixed(13 + (sync.length * 16));
    buf.writeUint8(PhysicsPacket.step);
    buf.writeInt32(_worldId);
    buf.writeFloat32(dt);
    buf.writeInt32(sync.length);
    for (final entry in sync.entries) {
      buf.writeInt32(entry.key);
      buf.writeFloat32(entry.value.position.dx);
      buf.writeFloat32(entry.value.position.dy);
      buf.writeFloat32(entry.value.rotation);
    }
    _send(buf.data);
  }

  @override
  void raycast(
      int requestId, Offset origin, Offset direction, double maxDistance) {
    final buf = PhysicsBuffer.fixed(25);
    buf.writeUint8(PhysicsPacket.raycast);
    buf.writeInt32(_worldId);
    buf.writeInt32(requestId);
    buf.writeFloat32(origin.dx);
    buf.writeFloat32(origin.dy);
    buf.writeFloat32(direction.dx);
    buf.writeFloat32(direction.dy);
    buf.writeFloat32(maxDistance);
    _send(buf.data);
  }
}
