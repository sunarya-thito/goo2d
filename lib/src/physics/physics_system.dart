import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:goo2d/goo2d.dart';
import 'physics_bridge.dart';

/// The central system responsible for physical simulation and collision detection.
/// 
/// [PhysicsSystem] manages the lifecycle of rigidbodies and colliders, 
/// synchronizing their state with a background physics worker (or a 
/// direct bridge on the web). It handles the fixed-step update loop 
/// to ensure deterministic simulation results across different frame rates.
/// 
/// ```dart
/// // Access physics via the game instance
/// game.physics.gravity = const Offset(0, 9.8);
/// final hit = await game.physics.raycast(pos, dir);
/// ```
class PhysicsSystem implements GameSystem {
  late final PhysicsBridge _bridge;
  static int _nextWorldId = 1;

  final Map<int, Rigidbody> _rigidbodies = {};
  final Map<int, Collider> _colliders = {};
  final Map<GameObject, int> _standaloneBodyIds = {};
  final Map<int, int> _bodyColliderCount = {};
  final Map<int, Completer<RaycastHit?>> _raycastCompleters = {};

  // Set of shape ID pairs that were contacting in the last frame.
  final Set<String> _previousContacts = {};

  int _nextId = 1;
  int _nextRequestId = 1;

  /// The unique identifier for the physics world instance.
  /// 
  /// This ID is passed to the [PhysicsBridge] to manage multi-world 
  /// simulations in environments that support them.
  int worldId = 0;

  /// Returns all currently registered colliders in the system.
  /// 
  /// This provides a live view of the physical shapes currently 
  /// participating in the simulation.
  Iterable<Collider> get activeColliders => _colliders.values;

  /// The frequency of physics updates (default is 50Hz).
  /// 
  /// Smaller values result in higher precision but increase the 
  /// computational load on the worker.
  double fixedTimeStep = 1.0 / 50.0; 
  double _accumulator = 0.0;

  Offset _gravity = const Offset(0, 980);

  /// The global gravity vector applied to all dynamic rigidbodies.
  /// 
  /// The default value is (0, 980) pixels/sec², pointing downwards.
  Offset get gravity => _gravity;

  /// Sets the global gravity vector.
  /// 
  /// Updates the underlying physics world simulation immediately.
  /// 
  /// * [value]: The new gravity vector.
  set gravity(Offset value) {
    if (_gravity == value) return;
    _gravity = value;
    _bridge.setGravity(value);
  }

  GameEngine? _game;

  @override
  GameEngine get game => _game!;

  @override
  bool get gameAttached => _game != null;

  /// Optional override for the physics bridge (used in benchmarks).
  /// 
  /// Allows the injection of a custom [PhysicsBridge] for testing 
  /// or specialized simulation environments.
  @visibleForTesting
  PhysicsBridge? bridgeOverride;

  @override
  void attach(GameEngine game) {
    _game = game;
    worldId = _nextWorldId++;
    _bridge = bridgeOverride ?? (kIsWeb ? DirectPhysicsBridge() : WorkerPhysicsBridge());
    _bridge.init(worldId, _handleStepResult, _handleRaycastResult);
    _bridge.createWorld();
    _bridge.setGravity(_gravity);
  }

  /// Processes the results from a completed physics step.
  /// 
  /// This method performs two critical tasks:
  /// 1. Synchronizes the positions/rotations of [Rigidbody]s back 
  ///    to their parent [ObjectTransform]s.
  /// 2. Resolves contact events and broadcasts [CollisionEvent]s or 
  ///    [TriggerEvent]s to the relevant [GameObject]s.
  /// 
  /// * [result]: The data package containing body states and contacts.
  void _handleStepResult(PhysicsStepResult result) {
    for (final entry in result.dynamicBodies.entries) {
      final body = _rigidbodies[entry.key];
      if (body != null) {
        final state = entry.value;
        body.internalSetVelocity(state.velocity, state.angularVelocity);
        final t = body.tryTransform;
        if (t != null) {
          t.position = state.position;
          t.angle = state.rotation;
        }
      }
    }

    final Set<String> currentContactKeys = {};

    for (final contact in result.contacts) {
      final sAId = contact.shapeAId;
      final sBId = contact.shapeBId;
      final px = contact.contactPoint.dx;
      final py = contact.contactPoint.dy;
      final nx = contact.normal.dx;
      final ny = contact.normal.dy;
      final impulse = contact.impulse;

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

  /// Internal handler for raycast completion.
  /// 
  /// This bridges the asynchronous response from the [PhysicsBridge] 
  /// back to the [Future] returned to the user.
  /// 
  /// * [requestId]: The ID of the original request.
  /// * [hasHit]: Whether an intersection was found.
  /// * [data]: The raw hit data from the worker.
  void _handleRaycastResult(
    int requestId,
    bool hasHit,
    PhysicsRaycastHitData? data,
  ) {
    final completer = _raycastCompleters.remove(requestId);
    if (completer != null) {
      if (hasHit && data != null) {
        final collider = _colliders[data.shapeId];
        if (collider != null) {
          completer.complete(
            RaycastHit(
              collider: collider,
              point: data.point,
              normal: data.normal,
              distance: data.distance,
              fraction: data.fraction,
            ),
          );
        } else {
          completer.complete(null);
        }
      } else {
        completer.complete(null);
      }
    }
  }

  /// Registers a [Rigidbody] into the physical simulation.
  /// 
  /// This creates a corresponding body in the [PhysicsBridge] and 
  /// begins synchronizing its transform every step.
  /// 
  /// * [body]: The component to register.
  void registerRigidbody(Rigidbody body) {
    final t = body.tryTransform;
    if (t == null) return;

    final id = _nextId++;
    _rigidbodies[id] = body;

    _bridge.addBody(
      id,
      body.type,
      mass: body.mass,
      drag: body.drag,
      angularDrag: body.angularDrag,
      freezeRotation: body.freezeRotation,
      gravityScale: body.gravityScale,
      position: t.position,
      rotation: t.angle,
    );
  }

  /// Removes a [Rigidbody] from the simulation.
  /// 
  /// The body and all its attached shapes will be destroyed in the 
  /// underlying physics engine.
  /// 
  /// * [body]: The component to remove.
  void unregisterRigidbody(Rigidbody body) {
    final id = _rigidbodies.keys.firstWhere(
      (k) => _rigidbodies[k] == body,
      orElse: () => -1,
    );
    if (id != -1) {
      _rigidbodies.remove(id);
      _bridge.removeBody(id);
    }
  }

  /// Updates the physical properties of an existing [Rigidbody].
  /// 
  /// This should be called whenever mass, drag, or gravity scale properties 
  /// are modified on the [Rigidbody] component.
  /// 
  /// * [body]: The component whose properties changed.
  void updateRigidbody(Rigidbody body) {
    final id = _rigidbodies.keys.firstWhere(
      (k) => _rigidbodies[k] == body,
      orElse: () => -1,
    );
    if (id != -1) {
      _bridge.updateBody(
        id,
        mass: body.mass,
        drag: body.drag,
        angularDrag: body.angularDrag,
        freezeRotation: body.freezeRotation,
        gravityScale: body.gravityScale,
      );
    }
  }

  /// Synchronizes linear velocity from the engine to the physics worker.
  /// 
  /// This is an internal method used by the [Rigidbody.velocity] setter 
  /// to ensure the simulation stays in sync.
  /// 
  /// * [body]: The body to update.
  /// * [velocity]: The new world-space velocity.
  void internalSyncVelocity(Rigidbody body, Offset velocity) {
    final id = _rigidbodies.keys.firstWhere(
      (k) => _rigidbodies[k] == body,
      orElse: () => -1,
    );
    if (id != -1) {
      _bridge.syncVelocity(id, velocity);
    }
  }

  /// Synchronizes angular velocity from the engine to the physics worker.
  /// 
  /// * [body]: The body to update.
  /// * [angularVelocity]: The new rotational velocity in radians/sec.
  void internalSyncAngularVelocity(Rigidbody body, double angularVelocity) {
    final id = _rigidbodies.keys.firstWhere(
      (k) => _rigidbodies[k] == body,
      orElse: () => -1,
    );
    if (id != -1) {
      _bridge.syncAngularVelocity(id, angularVelocity);
    }
  }

  int _createStandaloneBody(GameObject go) {
    final id = _nextId++;
    final t = go.tryGetComponent<ObjectTransform>();

    _bridge.addBody(
      id,
      RigidbodyType.static,
      mass: 1.0,
      drag: 0.0,
      angularDrag: 0.05,
      freezeRotation: false,
      gravityScale: 1.0,
      position: t?.position ?? Offset.zero,
      rotation: t?.angle ?? 0.0,
    );

    return id;
  }

  void _removeStandaloneBody(int bodyId) {
    _bridge.removeBody(bodyId);
  }

  /// Registers a [Collider] and attaches it to its parent [Rigidbody].
  /// 
  /// If the [GameObject] does not have a [Rigidbody], a static 
  /// standalone body is created automatically to host the collider.
  /// 
  /// * [collider]: The shape to add to the simulation.
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
      rbId = _standaloneBodyIds[collider.gameObject] ??= _createStandaloneBody(
        collider.gameObject,
      );
      _bodyColliderCount[rbId] = (_bodyColliderCount[rbId] ?? 0) + 1;
    }

    _bridge.addShape(id, rbId, collider);
  }

  /// Removes a [Collider] from the simulation.
  /// 
  /// If this was the last collider on a standalone body, that body 
  /// is also destroyed.
  /// 
  /// * [collider]: The shape to remove.
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

      _bridge.removeShape(id);
    }
  }

  /// Advances the simulation by [dt].
  /// 
  /// Uses an accumulator pattern to ensure that the physics simulation 
  /// runs at a fixed frequency (determined by [fixedTimeStep]), 
  /// independent of the rendering frame rate.
  /// 
  /// * [dt]: The elapsed time since the last frame in seconds.
  void step(double dt) {
    _accumulator += dt;
    while (_accumulator >= fixedTimeStep) {
      _internalStep(fixedTimeStep);
      _accumulator -= fixedTimeStep;
    }
  }

  // Synchronizes static transforms and commands the bridge to step.
  void _internalStep(double dt) {
    final Map<int, PhysicsTransformSync> sync = {};

    for (final entry in _rigidbodies.entries) {
      if (entry.value.type != RigidbodyType.dynamic) {
        final t = entry.value.tryTransform;
        if (t != null) {
          sync[entry.key] = PhysicsTransformSync(t.position, t.angle);
        }
      }
    }

    for (final entry in _standaloneBodyIds.entries) {
      final t = entry.key.tryGetComponent<ObjectTransform>();
      if (t != null) {
        sync[entry.value] = PhysicsTransformSync(t.position, t.angle);
      }
    }

    _bridge.step(dt, sync);
  }

  /// Queues a force to be applied to a [Rigidbody] on the next physics step.
  /// 
  /// Forces are cumulative and are reset at the end of each physical 
  /// step resolution.
  /// 
  /// * [body]: The target body.
  /// * [force]: The force vector.
  void internalQueueForce(Rigidbody body, Offset force) {
    final id = _rigidbodies.keys.firstWhere(
      (k) => _rigidbodies[k] == body,
      orElse: () => -1,
    );
    if (id != -1) {
      _bridge.applyForce(id, force);
    }
  }

  /// Queues an instantaneous impulse to be applied to a [Rigidbody].
  /// 
  /// Impulses cause an immediate change in velocity without needing 
  /// a continuous force application.
  /// 
  /// * [body]: The target body.
  /// * [impulse]: The impulse vector.
  void internalQueueImpulse(Rigidbody body, Offset impulse) {
    final id = _rigidbodies.keys.firstWhere(
      (k) => _rigidbodies[k] == body,
      orElse: () => -1,
    );
    if (id != -1) {
      _bridge.applyImpulse(id, impulse);
    }
  }

  /// Queues a torque to be applied to a [Rigidbody].
  /// 
  /// Torques apply rotational acceleration to the body around its 
  /// center of mass.
  /// 
  /// * [body]: The target body.
  /// * [torque]: The rotational force magnitude.
  void internalQueueTorque(Rigidbody body, double torque) {
    final id = _rigidbodies.keys.firstWhere(
      (k) => _rigidbodies[k] == body,
      orElse: () => -1,
    );
    if (id != -1) {
      _bridge.applyTorque(id, torque);
    }
  }

  /// Queues an angular impulse to be applied to a [Rigidbody].
  /// 
  /// Rotational impulses cause an immediate change in angular velocity 
  /// without being affected by time steps.
  /// 
  /// * [body]: The target body.
  /// * [impulse]: The rotational impulse magnitude.
  void internalQueueAngularImpulse(Rigidbody body, double impulse) {
    final id = _rigidbodies.keys.firstWhere(
      (k) => _rigidbodies[k] == body,
      orElse: () => -1,
    );
    if (id != -1) {
      _bridge.applyAngularImpulse(id, impulse);
    }
  }

  /// Casts a ray into the physics world and returns the closest hit.
  /// 
  /// Since physics often runs in a separate Isolate, this operation 
  /// is asynchronous and returns a [Future].
  /// 
  /// * [origin]: The world-space starting point of the ray.
  /// * [direction]: The normalized vector defining the ray's path.
  /// * [maxDistance]: The maximum length of the ray.
  /// 
  /// ```dart
  /// final hit = await game.physics.raycast(pos, dir);
  /// if (hit != null) {
  ///   print('Hit object: ${hit.collider.gameObject.name}');
  /// }
  /// ```
  Future<RaycastHit?> raycast(
    Offset origin,
    Offset direction, [
    double maxDistance = double.infinity,
  ]) async {
    final requestId = _nextRequestId++;
    final completer = Completer<RaycastHit?>();
    _raycastCompleters[requestId] = completer;

    _bridge.raycast(requestId, origin, direction, maxDistance);

    return completer.future;
  }

  @override
  void dispose() {
    _bridge.destroyWorld();
    _rigidbodies.clear();
    _colliders.clear();
    _raycastCompleters.clear();
  }
}
