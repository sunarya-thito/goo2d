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
/// 
/// This structure encapsulates the mathematical results of a collision resolution
/// between two [PhysicsShape]s. It is used by the engine to trigger collision 
/// events and play sound effects or spawn particles at the contact point.
/// 
/// ```dart
/// void onCollision(PhysicsContactData contact) {
///   print('Hit at ${contact.contactPoint}');
/// }
/// ```
class PhysicsContactData {
  /// The ID of the first shape in the contact.
  /// 
  /// Usually corresponds to the [PhysicsShape.id] of the body that was 
  /// processed first in the collision pair.
  final int shapeAId;
  
  /// The ID of the second shape in the contact.
  /// 
  /// Usually corresponds to the [PhysicsShape.id] of the body that was 
  /// processed second in the collision pair.
  final int shapeBId;
  
  /// The world-space point of contact.
  /// 
  /// This is the exact position where the two shapes touched or overlapped.
  final Offset contactPoint;
  
  /// The contact normal vector.
  /// 
  /// A normalized vector pointing from [shapeAId] towards [shapeBId] that 
  /// defines the direction of the impact.
  final Offset normal;
  
  /// The penetration depth of the collision.
  /// 
  /// Measured in world units; represents how far the shapes overlapped 
  /// before resolution.
  final double depth;
  
  /// The impulse applied to resolve the collision.
  /// 
  /// This scalar value represents the change in momentum applied along 
  /// the [normal] to separate the bodies.
  final double impulse;

  /// Creates a [PhysicsContactData] object.
  /// 
  /// * [shapeAId]: ID of the first shape.
  /// * [shapeBId]: ID of the second shape.
  /// * [contactPoint]: World-space position of the hit.
  /// * [normal]: Normalized impact direction.
  /// * [depth]: Overlap distance.
  /// * [impulse]: Magnitude of the resolution force.
  PhysicsContactData({
    required this.shapeAId,
    required this.shapeBId,
    required this.contactPoint,
    required this.normal,
    required this.depth,
    required this.impulse,
  });
}

/// Result of a single physics simulation step.
/// 
/// This record is produced by a [PhysicsBridge] after every [PhysicsBridge.step] 
/// and contains all state updates required to synchronize the game engine 
/// with the simulation.
/// 
/// ```dart
/// void handleStep(PhysicsStepResult result) {
///   for (final contact in result.contacts) {
///     // Handle collisions
///   }
/// }
/// ```
class PhysicsStepResult {
  /// A list of all contacts detected during the step.
  /// 
  /// Includes both resolved physical collisions and trigger overlaps.
  final List<PhysicsContactData> contacts;
  
  /// A map of body IDs to their updated physical state.
  /// 
  /// Only contains bodies that moved or changed state during this step.
  final Map<int, PhysicsBodyState> dynamicBodies;

  /// Creates a [PhysicsStepResult].
  /// 
  /// * [contacts]: List of collision records.
  /// * [dynamicBodies]: Map of updated body states.
  PhysicsStepResult({
    required this.contacts,
    required this.dynamicBodies,
  });
}

/// The runtime state of a physics body.
/// 
/// Represents a snapshot of a [PhysicsBody]'s transform and velocities in 
/// the simulation. This is used to update [GameObject] transforms.
/// 
/// ```dart
/// final state = result.dynamicBodies[id]!;
/// gameObject.position = state.position;
/// ```
class PhysicsBodyState {
  /// The world-space position.
  /// 
  /// Calculated by the integrator during the simulation step.
  final Offset position;
  
  /// The rotation in radians.
  /// 
  /// Calculated by the angular integrator during the simulation step.
  final double rotation;
  
  /// The linear velocity.
  /// 
  /// Represents the change in [position] over time (units/sec).
  final Offset velocity;
  
  /// The angular velocity.
  /// 
  /// Represents the change in [rotation] over time (rad/sec).
  final double angularVelocity;

  /// Creates a [PhysicsBodyState].
  /// 
  /// * [position]: New world position.
  /// * [rotation]: New rotation in radians.
  /// * [velocity]: New linear velocity.
  /// * [angularVelocity]: New angular velocity.
  PhysicsBodyState({
    required this.position,
    required this.rotation,
    required this.velocity,
    required this.angularVelocity,
  });
}

/// Data used to synchronize transform changes from the engine back 
/// to the physics simulation.
/// 
/// When a [GameObject] is moved manually via code or animation, this 
/// structure carries that "teleportation" data to the [PhysicsWorld] so 
/// that collisions can be correctly calculated.
/// 
/// ```dart
/// bridge.step(dt, { id: PhysicsTransformSync(pos, rot) });
/// ```
class PhysicsTransformSync {
  /// The current engine position.
  /// 
  /// This will overwrite the body's internal position in the simulation.
  final Offset position;
  
  /// The current engine rotation.
  /// 
  /// This will overwrite the body's internal rotation in the simulation.
  final double rotation;
  
  /// Creates a [PhysicsTransformSync].
  /// 
  /// * [position]: The target position for the body.
  /// * [rotation]: The target rotation for the body.
  PhysicsTransformSync(this.position, this.rotation);
}

/// Abstract bridge between the game engine and the physics simulation.
/// 
/// This interface allows the engine to swap between different simulation 
/// environments. The [DirectPhysicsBridge] is used for synchronous main-thread 
/// execution (required for Web), while [WorkerPhysicsBridge] offloads calculations 
/// to a background Isolate for native platforms.
/// 
/// ```dart
/// final bridge = kIsWeb ? DirectPhysicsBridge() : WorkerPhysicsBridge();
/// await bridge.init(0, (res) => handleResult(res), (id, hit, data) => {});
/// ```
abstract class PhysicsBridge {
  /// Initializes the bridge and sets up result callbacks.
  /// 
  /// The [worldId] must be unique if multiple simulations are running. 
  /// [onStepResult] is called after every simulation step with updated transforms.
  /// [onRaycastResult] is called when a raycast request completes.
  /// 
  /// * [worldId]: Unique identifier for the physics world.
  /// * [onStepResult]: Callback for physics step updates.
  /// * [onRaycastResult]: Callback for raycast completion.
  Future<void> init(int worldId, void Function(PhysicsStepResult) onStepResult,
      void Function(int, bool, PhysicsRaycastHitData?) onRaycastResult);

  /// Creates a new physics world instance in the simulation environment.
  /// 
  /// This should be called once the bridge is initialized but before any 
  /// bodies or shapes are added.
  void createWorld();
  
  /// Destroys the current physics world and releases all resources.
  /// 
  /// This will clear all bodies, shapes, and simulation state from the 
  /// worker or main-thread world instance.
  void destroyWorld();

  /// Adds a new [PhysicsBody] to the simulation.
  /// 
  /// * [id]: Unique ID for the body.
  /// * [type]: Physics behavior (static, kinematic, or dynamic).
  /// * [mass]: Total mass of the body.
  /// * [drag]: Linear friction applied to movement.
  /// * [angularDrag]: Rotational friction.
  /// * [freezeRotation]: If true, prevents rotation via forces.
  /// * [gravityScale]: Multiplier for global gravity.
  /// * [position]: Starting world-space position.
  /// * [rotation]: Starting rotation in radians.
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

  /// Removes a body and all its associated shapes from the simulation.
  /// 
  /// * [id]: The ID of the body to remove.
  void removeBody(int id);

  /// Updates the physical properties of an existing body.
  /// 
  /// * [id]: The body to update.
  /// * [mass]: New mass value.
  /// * [drag]: New linear drag.
  /// * [angularDrag]: New angular drag.
  /// * [freezeRotation]: Updated rotation lock.
  /// * [gravityScale]: Updated gravity multiplier.
  void updateBody(
    int id, {
    double mass = 1.0,
    double drag = 0.0,
    double angularDrag = 0.05,
    bool freezeRotation = false,
    double gravityScale = 1.0,
  });

  /// Adds a [PhysicsShape] to a specific body.
  /// 
  /// Shapes define the volume of the body used for collision detection.
  /// 
  /// * [id]: Unique ID for the shape.
  /// * [bodyId]: The body to attach this shape to.
  /// * [collider]: The configuration for the shape (box, circle, etc).
  void addShape(int id, int bodyId, Collider collider);
  
  /// Removes a shape from its parent body.
  /// 
  /// * [id]: The ID of the shape to remove.
  void removeShape(int id);

  /// Applies a continuous force vector to a body.
  /// 
  /// * [bodyId]: Target body.
  /// * [force]: Force vector in world units/sec^2.
  void applyForce(int bodyId, Offset force);
  
  /// Applies an instantaneous impulse vector to a body.
  /// 
  /// * [bodyId]: Target body.
  /// * [impulse]: Impulse vector in world units/sec.
  void applyImpulse(int bodyId, Offset impulse);
  
  /// Applies a rotational force (torque) to a body.
  /// 
  /// * [bodyId]: Target body.
  /// * [torque]: Rotational force in rad/sec^2.
  void applyTorque(int bodyId, double torque);
  
  /// Applies an instantaneous rotational impulse to a body.
  /// 
  /// * [bodyId]: Target body.
  /// * [impulse]: Rotational impulse in rad/sec.
  void applyAngularImpulse(int bodyId, double impulse);

  /// Sets the global gravity vector for the world.
  /// 
  /// * [gravity]: Gravity vector (default is [0, 9.8]).
  void setGravity(Offset gravity);
  
  /// Manually sets the linear velocity of a body.
  /// 
  /// * [bodyId]: Target body.
  /// * [velocity]: New velocity vector.
  void syncVelocity(int bodyId, Offset velocity);
  
  /// Manually sets the angular velocity of a body.
  /// 
  /// * [bodyId]: Target body.
  /// * [velocity]: New angular velocity.
  void syncAngularVelocity(int bodyId, double velocity);

  /// Commands the simulation to advance by [dt].
  /// 
  /// This is the primary simulation loop entry point. The [sync] map is used 
  /// to update the positions of non-dynamic bodies that were moved by 
  /// the engine since the last step.
  /// 
  /// * [dt]: Time delta since last step.
  /// * [sync]: Map of bodies requiring transform synchronization.
  void step(double dt, Map<int, PhysicsTransformSync> sync);
  
  /// Commands the simulation to perform a raycast.
  /// 
  /// Results will be returned asynchronously via the [onRaycastResult] 
  /// callback provided in [init].
  /// 
  /// * [requestId]: Unique ID for this request to track results.
  /// * [origin]: Ray start point.
  /// * [direction]: Normalized ray direction.
  /// * [maxDistance]: Maximum ray length.
  void raycast(
      int requestId, Offset origin, Offset direction, double maxDistance);
}

/// Raw hit data returned from the physics simulation for a raycast.
/// 
/// Contains detailed information about where and what a raycast hit 
/// in the [PhysicsWorld].
/// 
/// ```dart
/// void handleHit(PhysicsRaycastHitData hit) {
///   print('Hit shape ${hit.shapeId} at ${hit.point}');
/// }
/// ```
class PhysicsRaycastHitData {
  /// The ID of the [PhysicsShape] that was hit.
  /// 
  /// This ID can be used to retrieve the [GameObject] associated with the 
  /// collider or to apply impulses to its parent [PhysicsBody].
  final int shapeId;
  
  /// The world-space intersection point.
  /// 
  /// This is the exact position on the shape's boundary where the ray 
  /// first encountered a solid pixel or geometry.
  final Offset point;
  
  /// The surface normal vector at the point of impact.
  /// 
  /// This vector points directly away from the surface and can be used 
  /// to calculate reflection vectors or to orient decals.
  final Offset normal;
  
  /// The distance from the origin to the hit point.
  /// 
  /// Measured in world units along the ray's trajectory. This is 
  /// always less than or equal to the [maxDistance] specified in the request.
  final double distance;
  
  /// The normalized fraction (0.0 to 1.0) along the ray's maximum length.
  /// 
  /// A value of 0.0 means the hit occurred at the origin, while 1.0 
  /// means it occurred at exactly [maxDistance].
  final double fraction;

  /// Creates a [PhysicsRaycastHitData] snapshot.
  /// 
  /// Encapsulates the results of a raycast intersection for transmission 
  /// between the simulation and the engine.
  /// 
  /// * [shapeId]: ID of the hit shape.
  /// * [point]: Intersection position.
  /// * [normal]: Surface normal.
  /// * [distance]: Length of ray until hit.
  /// * [fraction]: Percentage of maxDistance until hit.
  PhysicsRaycastHitData({
    required this.shapeId,
    required this.point,
    required this.normal,
    required this.distance,
    required this.fraction,
  });
}

/// Implementation of [PhysicsBridge] that calls [PhysicsWorld] directly.
/// 
/// This bridge is designed for environments where [Isolate]s are either 
/// unavailable (Flutter Web) or where the overhead of message serialization 
/// outweighs the benefits of parallel execution. It executes all physics 
/// logic on the caller's thread.
/// 
/// ```dart
/// final bridge = DirectPhysicsBridge();
/// bridge.init(0, (res) => updateUI(res), (id, hit, data) => {});
/// ```
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

/// Implementation of [PhysicsBridge] that uses an [Isolate] worker.
/// 
/// This bridge is the preferred implementation for high-performance native 
/// applications. It offloads the entire simulation (integration, collision 
/// detection, and resolution) to a background thread to prevent "jank" on 
/// the UI thread. Data is synchronized via high-performance binary serialization.
/// 
/// ```dart
/// final bridge = WorkerPhysicsBridge();
/// await bridge.init(0, (res) => handlePhysicsStep(res), (id, hit, data) => {});
/// ```
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
