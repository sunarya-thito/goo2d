import 'dart:async';
import 'package:vector_math/vector_math_64.dart';
import 'package:meta/meta.dart';
import 'package:goo2d/src/physics/worker/physics_worker.dart';
import 'package:goo2d/src/physics/worker/direct/direct_body_ops.dart';
import 'package:goo2d/src/physics/worker/data/contact_point_data.dart';
import 'package:goo2d/goo2d.dart';

/// Provides physics movement and other dynamics, and the ability to attach Collider2D to it.
/// 
/// Equivalent to Unity's `Rigidbody2D`.
class Rigidbody extends Component {
  Future<int>? _handleFuture;

  /// The internal physics handle for this rigidbody.
  Future<int> get handle {
    if (_handleFuture == null) {
      throw StateError('Rigidbody must be attached to a GameObject before accessing handle.');
    }
    return _handleFuture!;
  }

  @protected
  PhysicsWorker get worker => game.getSystem<PhysicsSystem>()!.worker;

  @override
  void internalAttach(GameObject gameObject) {
    super.internalAttach(gameObject);
    _handleFuture = worker.createBody();
    syncProperties();
  }

  @override
  void internalDetach() {
    _handleFuture?.then((h) => worker.destroyBody(h));
    _handleFuture = null;
    super.internalDetach();
  }

  /// Synchronizes properties with the physics worker.
  @protected
  void syncProperties() {
    _handleFuture?.then((h) {
      worker.setBodyProperty(h, BodyProp.bodyType, _bodyType.index);
      worker.setBodyProperty(h, BodyProp.interpolation, _interpolation.index);
      worker.setBodyProperty(h, BodyProp.linearDamping, _linearDamping);
      worker.setBodyProperty(h, BodyProp.angularDamping, _angularDamping);
      worker.setBodyProperty(h, BodyProp.gravityScale, _gravityScale);
      worker.setBodyProperty(h, BodyProp.mass, _mass);
      worker.setBodyProperty(h, BodyProp.inertia, _inertia);
      worker.setBodyProperty(h, BodyProp.freezeRotation, _freezeRotation);
      worker.setBodyProperty(h, BodyProp.simulated, _simulated);
      worker.setBodyProperty(h, BodyProp.useAutoMass, _useAutoMass);
      worker.setBodyProperty(h, BodyProp.useFullKinematicContacts, _useFullKinematicContacts);
      worker.setBodyProperty(h, BodyProp.constraints, _constraints);
      worker.setBodyProperty(h, BodyProp.collisionDetectionMode, _collisionDetectionMode.index);
      worker.setBodyProperty(h, BodyProp.sleepMode, _sleepMode.index);
      worker.setBodyProperty(h, BodyProp.excludeLayers, _excludeLayers);
      worker.setBodyProperty(h, BodyProp.includeLayers, _includeLayers);
      worker.setBodyProperty(h, BodyProp.centerOfMass, _centerOfMass);
    });
  }

  // --- Configuration Properties (Sync) ---

  RigidbodyType _bodyType = RigidbodyType.dynamic;
  /// The physical behaviour type of the Rigidbody2D.
  RigidbodyType get bodyType => _bodyType;
  set bodyType(RigidbodyType value) {
    _bodyType = value;
    _handleFuture?.then((h) => worker.setBodyProperty(h, BodyProp.bodyType, value.index));
  }

  RigidbodyInterpolation _interpolation = RigidbodyInterpolation.none;
  /// Physics interpolation used between updates.
  RigidbodyInterpolation get interpolation => _interpolation;
  set interpolation(RigidbodyInterpolation value) {
    _interpolation = value;
    _handleFuture?.then((h) => worker.setBodyProperty(h, BodyProp.interpolation, value.index));
  }

  double _linearDamping = 0;
  /// The linear damping of the Rigidbody2D linear velocity.
  double get linearDamping => _linearDamping;
  set linearDamping(double value) {
    _linearDamping = value;
    _handleFuture?.then((h) => worker.setBodyProperty(h, BodyProp.linearDamping, value));
  }

  double _angularDamping = 0.05;
  /// The angular damping of the Rigidbody2D angular velocity.
  double get angularDamping => _angularDamping;
  set angularDamping(double value) {
    _angularDamping = value;
    _handleFuture?.then((h) => worker.setBodyProperty(h, BodyProp.angularDamping, value));
  }

  double _gravityScale = 1.0;
  /// The degree to which this object is affected by gravity.
  double get gravityScale => _gravityScale;
  set gravityScale(double value) {
    _gravityScale = value;
    _handleFuture?.then((h) => worker.setBodyProperty(h, BodyProp.gravityScale, value));
  }

  double _mass = 1.0;
  /// Mass of the Rigidbody.
  double get mass => _mass;
  set mass(double value) {
    _mass = value;
    _handleFuture?.then((h) => worker.setBodyProperty(h, BodyProp.mass, value));
  }

  double _inertia = 0;
  /// The Rigidbody's resistance to changes in angular velocity (rotation).
  double get inertia => _inertia;
  set inertia(double value) {
    _inertia = value;
    _handleFuture?.then((h) => worker.setBodyProperty(h, BodyProp.inertia, value));
  }

  bool _freezeRotation = false;
  /// Controls whether physics will change the rotation of the object.
  bool get freezeRotation => _freezeRotation;
  set freezeRotation(bool value) {
    _freezeRotation = value;
    _handleFuture?.then((h) => worker.setBodyProperty(h, BodyProp.freezeRotation, value));
  }

  bool _simulated = true;
  /// Indicates whether the rigid body should be simulated or not by the physics system.
  bool get simulated => _simulated;
  set simulated(bool value) {
    _simulated = value;
    _handleFuture?.then((h) => worker.setBodyProperty(h, BodyProp.simulated, value));
  }

  bool _useAutoMass = false;
  /// Should the total rigid-body mass be automatically calculated from the Collider2D.density of attached colliders?
  bool get useAutoMass => _useAutoMass;
  set useAutoMass(bool value) {
    _useAutoMass = value;
    _handleFuture?.then((h) => worker.setBodyProperty(h, BodyProp.useAutoMass, value));
  }

  bool _useFullKinematicContacts = false;
  /// Should kinematic/kinematic and kinematic/static collisions be allowed?
  bool get useFullKinematicContacts => _useFullKinematicContacts;
  set useFullKinematicContacts(bool value) {
    _useFullKinematicContacts = value;
    _handleFuture?.then((h) => worker.setBodyProperty(h, BodyProp.useFullKinematicContacts, value));
  }

  int _constraints = 0;
  /// Controls which degrees of freedom are allowed for the simulation of this Rigidbody2D.
  int get constraints => _constraints;
  set constraints(int value) {
    _constraints = value;
    _handleFuture?.then((h) => worker.setBodyProperty(h, BodyProp.constraints, value));
  }

  CollisionDetectionMode _collisionDetectionMode = CollisionDetectionMode.discrete;
  /// The method used by the physics engine to check if two objects have collided.
  CollisionDetectionMode get collisionDetectionMode => _collisionDetectionMode;
  set collisionDetectionMode(CollisionDetectionMode value) {
    _collisionDetectionMode = value;
    _handleFuture?.then((h) => worker.setBodyProperty(h, BodyProp.collisionDetectionMode, value.index));
  }

  RigidbodySleepMode _sleepMode = RigidbodySleepMode.startAwake;
  /// The sleep state that the rigidbody will initially be in.
  RigidbodySleepMode get sleepMode => _sleepMode;
  set sleepMode(RigidbodySleepMode value) {
    _sleepMode = value;
    _handleFuture?.then((h) => worker.setBodyProperty(h, BodyProp.sleepMode, value.index));
  }

  int _excludeLayers = 0;
  /// The additional Layers that all Collider2D attached to this Rigidbody2D should exclude when deciding if a contact with another Collider2D should happen or not.
  int get excludeLayers => _excludeLayers;
  set excludeLayers(int value) {
    _excludeLayers = value;
    _handleFuture?.then((h) => worker.setBodyProperty(h, BodyProp.excludeLayers, value));
  }

  int _includeLayers = 0;
  /// The additional Layers that all Collider2D attached to this Rigidbody2D should include when deciding if a contact with another Collider2D should happen or not.
  int get includeLayers => _includeLayers;
  set includeLayers(int value) {
    _includeLayers = value;
    _handleFuture?.then((h) => worker.setBodyProperty(h, BodyProp.includeLayers, value));
  }

  Vector2 _centerOfMass = Vector2.zero();
  /// The center of mass of the rigidBody in local space.
  Vector2 get centerOfMass => _centerOfMass;
  set centerOfMass(Vector2 value) {
    _centerOfMass.setFrom(value);
    _handleFuture?.then((h) => worker.setBodyProperty(h, BodyProp.centerOfMass, value));
  }

  // --- Simulated State Properties (Async) ---

  /// The linear velocity of the Rigidbody2D represents the rate of change over time of the Rigidbody2D position in world-units.
  Future<Vector2> get linearVelocity async => (await worker.getBodyProperty(await handle, BodyProp.linearVelocity)) as Vector2;
  set linearVelocity(Vector2 value) {
    handle.then((h) => worker.setBodyProperty(h, BodyProp.linearVelocity, value));
  }

  /// Angular velocity in degrees per second.
  Future<double> get angularVelocity async => (await worker.getBodyProperty(await handle, BodyProp.angularVelocity)) as double;
  set angularVelocity(double value) {
    handle.then((h) => worker.setBodyProperty(h, BodyProp.angularVelocity, value));
  }

  /// The position of the rigidbody.
  Future<Vector2> get position async => (await worker.getBodyProperty(await handle, BodyProp.position)) as Vector2;
  set position(Vector2 value) {
    handle.then((h) => worker.setBodyProperty(h, BodyProp.position, value));
  }

  /// The rotation of the rigidbody.
  Future<double> get rotation async => (await worker.getBodyProperty(await handle, BodyProp.rotation)) as double;
  set rotation(double value) {
    handle.then((h) => worker.setBodyProperty(h, BodyProp.rotation, value));
  }

  /// The total amount of force that has been explicitly applied to this Rigidbody2D since the last physics simulation step.
  Future<Vector2> get totalForce async => (await worker.getBodyProperty(await handle, BodyProp.totalForce)) as Vector2;

  /// The total amount of torque that has been explicitly applied to this Rigidbody2D since the last physics simulation step.
  Future<double> get totalTorque async => (await worker.getBodyProperty(await handle, BodyProp.totalTorque)) as double;

  /// Gets the center of mass of the rigidBody in global space.
  Future<Vector2> get worldCenterOfMass async => (await worker.getBodyProperty(await handle, BodyProp.worldCenterOfMass)) as Vector2;

  /// The X component of the linear velocity of the Rigidbody2D in world-units per second.
  Future<double> get linearVelocityX async => (await linearVelocity).x;

  /// The Y component of the linear velocity of the Rigidbody2D in world-units per second.
  Future<double> get linearVelocityY async => (await linearVelocity).y;

  // --- Local/Computed Properties ---

  /// Returns the number of Collider2D attached to this Rigidbody2D.
  int get attachedColliderCount => gameObject.getComponents<Collider>().length;

  /// The transformation matrix used to transform the Rigidbody2D to world space.
  Matrix4 get worldMatrix => gameObject.getComponent<ObjectTransform>().worldMatrix;

  /// The transformation matrix used to transform the Rigidbody2D to world space.
  Matrix4 get localToWorldMatrix => worldMatrix;

  /// The PhysicsMaterial2D that is applied to all Colliders attached to this Rigidbody2D.
  Object? get sharedMaterial => null; // TODO: Implement PhysicsMaterial

  // --- Methods ---

  /// Casts the Rigidbody2D shape into the Scene starting at the Rigidbody2D position.
  Future<List<RaycastHit>> cast(Vector2 direction, double distance, [int layerMask = Physics.defaultRaycastLayers]) async {
    final results = await worker.raycast(await position, direction, distance, layerMask, -double.infinity, double.infinity);
    return results.map((d) => RaycastHit.fromData(d)).whereType<RaycastHit>().toList();
  }

  /// Calculates the minimum distance between all the Colliders attached to this Rigidbody2D and the collider.
  Future<double> distance(Collider collider) async => worker.colliderDistance(await handle, await collider.handle);

  /// Returns all the Collider2D attached to this Rigidbody2D.
  List<Collider> getAttachedColliders() => gameObject.getComponents<Collider>().toList();

  /// Gets all the physics shapes used by all the Colliders attached to this Rigidbody2D.
  Future<List<Object>> getShapes() async => []; // TODO: Implement PhysicsShape

  /// Checks whether any of the Colliders attached to this Rigidbody2D overlap the area in the Scene.
  Future<List<Collider>> overlap(int layerMask, double minDepth, double maxDepth) async => []; // TODO: Implement overlap

  /// Checks whether any of the Colliders attached to this Rigidbody2D overlap the point in the Scene.
  Future<bool> overlapPoint(Vector2 point) async => worker.colliderIsTouchingLayers(await handle, ~0); // Simplified

  /// Moves the Rigidbody2D by the given displacement, but only if it does not collide with anything.
  Future<void> slide(Vector2 displacement) async => movePosition(await position + displacement); // Simplified

  /// Apply a force to the rigidbody.
  Future<void> addForce(Vector2 force, ForceMode mode) async => worker.bodyAddForce(await handle, force, mode.index);

  /// Apply a force at a given position in space.
  Future<void> addForceAtPosition(Vector2 force, Vector2 position, ForceMode mode) async => worker.bodyAddForceAtPosition(await handle, force, position, mode.index);

  /// Adds a force to the X component of the Rigidbody2D.linearVelocity only leaving the Y component of the world space Rigidbody2D.linearVelocity untouched.
  Future<void> addForceX(double force, ForceMode mode) => addForce(Vector2(force, 0), mode);

  /// Adds a force to the Y component of the Rigidbody2D.linearVelocity only leaving the X component of the world space Rigidbody2D.linearVelocity untouched.
  Future<void> addForceY(double force, ForceMode mode) => addForce(Vector2(0, force), mode);

  /// Apply a torque at the rigidbody's centre of mass.
  Future<void> addTorque(double torque, ForceMode mode) async => worker.bodyAddTorque(await handle, torque, mode.index);

  /// Adds a force to the local space Rigidbody2D.linearVelocity. In other words, the force is applied in the rotated coordinate space of the Rigidbody2D.
  Future<void> addRelativeForce(Vector2 relativeForce, ForceMode mode) async => worker.bodyAddRelativeForce(await handle, relativeForce, mode.index);

  /// Adds a force to the X component of the Rigidbody2D.linearVelocity in the local space of the Rigidbody2D only leaving the Y component of the local space Rigidbody2D.linearVelocity untouched.
  Future<void> addRelativeForceX(double force, ForceMode mode) => addRelativeForce(Vector2(force, 0), mode);

  /// Adds a force to the Y component of the Rigidbody2D.linearVelocity in the local space of the Rigidbody2D only leaving the X component of the local space Rigidbody2D.linearVelocity untouched.
  Future<void> addRelativeForceY(double force, ForceMode mode) => addRelativeForce(Vector2(0, force), mode);

  /// Moves the rigidbody to position.
  Future<void> movePosition(Vector2 position) async => worker.bodyMovePosition(await handle, position);

  /// Moves the rigidbody position to position and the rigidbody angle to angle.
  Future<void> movePositionAndRotation(Vector2 position, double angle) async => worker.bodyMovePositionAndRotation(await handle, position, angle);

  /// Rotates the Rigidbody to angle (given in degrees).
  Future<void> moveRotation(double angle) async => worker.bodyMoveRotation(await handle, angle);

  /// Sets the rotation of the Rigidbody2D to angle (given in degrees).
  Future<void> setRotation(double angle) async => worker.bodySetRotation(await handle, angle);

  /// Disables the "sleeping" state of a rigidbody.
  Future<void> wakeUp() async => worker.bodyWakeUp(await handle);

  /// Make the rigidbody "sleep".
  Future<void> sleep() async => worker.bodySleep(await handle);

  /// Is the rigidbody "awake"?
  Future<bool> isAwake() async => worker.bodyIsAwake(await handle);

  /// Is the rigidbody "sleeping"?
  Future<bool> isSleeping() async => worker.bodyIsSleeping(await handle);

  /// Get a local space point given the point point in rigidBody global space.
  Future<Vector2> getPoint(Vector2 point) async => worker.bodyGetPoint(await handle, point);

  /// Get a global space point given the point relativePoint in rigidBody local space.
  Future<Vector2> getRelativePoint(Vector2 relativePoint) async => worker.bodyGetRelativePoint(await handle, relativePoint);

  /// Get a local space vector given the vector vector in rigidBody global space.
  Future<Vector2> getVector(Vector2 vector) async => worker.bodyGetVector(await handle, vector);

  /// Get a global space vector given the vector relativeVector in rigidBody local space.
  Future<Vector2> getRelativeVector(Vector2 relativeVector) async => worker.bodyGetRelativeVector(await handle, relativeVector);

  /// The velocity of the rigidbody at the point Point in global space.
  Future<Vector2> getPointVelocity(Vector2 point) async => worker.bodyGetPointVelocity(await handle, point);

  /// The velocity of the rigidbody at the point Point in local space.
  Future<Vector2> getRelativePointVelocity(Vector2 relativePoint) async => worker.bodyGetRelativePointVelocity(await handle, relativePoint);

  /// Returns a point on the perimeter of all enabled Colliders attached to this Rigidbody that is closest to the specified position.
  Future<Vector2> closestPoint(Vector2 position) async => worker.bodyClosestPoint(await handle, position);

  /// Checks whether the collider is touching any of the collider(s) attached to this rigidbody or not.
  Future<bool> isTouching(Collider collider) async => worker.colliderIsTouching(await handle, await collider.handle);

  /// Checks whether any of the collider(s) attached to this rigidbody are touching any colliders on the specified layerMask or not.
  Future<bool> isTouchingLayers(int layerMask) async => worker.colliderIsTouchingLayers(await handle, layerMask);

  /// Retrieves all contact points for all of the Collider(s) attached to this Rigidbody.
  Future<List<ContactPoint>> getContacts() async {
    final data = await worker.getContacts(await handle);
    return data.map((d) => ContactPoint.fromData(d)).whereType<ContactPoint>().toList();
  }

  /// Retrieves all colliders in contact with this Rigidbody.
  Future<List<Collider>> getContactColliders() async {
    final handles = await worker.getContactColliders(await handle);
    return handles.map((h) => PhysicsSystem.getCollider(h)).whereType<Collider>().toList();
  }
}
