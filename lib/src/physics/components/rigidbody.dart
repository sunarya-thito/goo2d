import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/goo2d.dart';

/// Provides physics movement and other dynamics, and the ability to attach Collider2D to it.
/// 
/// Equivalent to Unity's `Rigidbody2D`.
class Rigidbody extends Component {
  /// The physical behaviour type of the Rigidbody2D.
  RigidbodyType get bodyType => throw UnimplementedError('Implemented via Physics Worker');
  set bodyType(RigidbodyType value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Physics interpolation used between updates.
  RigidbodyInterpolation get interpolation => throw UnimplementedError('Implemented via Physics Worker');
  set interpolation(RigidbodyInterpolation value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The linear velocity of the Rigidbody2D represents the rate of change over time of the Rigidbody2D position in world-units.
  Vector2 get linearVelocity => throw UnimplementedError('Implemented via Physics Worker');
  set linearVelocity(Vector2 value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The additional Layers that all Collider2D attached to this Rigidbody2D should exclude when deciding if a contact with another Collider2D should happen or not.
  int get excludeLayers => throw UnimplementedError('Implemented via Physics Worker');
  set excludeLayers(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Controls whether physics will change the rotation of the object.
  bool get freezeRotation => throw UnimplementedError('Implemented via Physics Worker');
  set freezeRotation(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The degree to which this object is affected by gravity.
  double get gravityScale => throw UnimplementedError('Implemented via Physics Worker');
  set gravityScale(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Angular velocity in degrees per second.
  double get angularVelocity => throw UnimplementedError('Implemented via Physics Worker');
  set angularVelocity(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The linear damping of the Rigidbody2D linear velocity.
  double get linearDamping => throw UnimplementedError('Implemented via Physics Worker');
  set linearDamping(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The method used by the physics engine to check if two objects have collided.
  CollisionDetectionMode get collisionDetectionMode => throw UnimplementedError('Implemented via Physics Worker');
  set collisionDetectionMode(CollisionDetectionMode value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Controls which degrees of freedom are allowed for the simulation of this Rigidbody2D.
  int get constraints => throw UnimplementedError('Implemented via Physics Worker');
  set constraints(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The angular damping of the Rigidbody2D angular velocity.
  double get angularDamping => throw UnimplementedError('Implemented via Physics Worker');
  set angularDamping(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Returns the number of Collider2D attached to this Rigidbody2D.
  int get attachedColliderCount => throw UnimplementedError('Implemented via Physics Worker');
  set attachedColliderCount(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The center of mass of the rigidBody in local space.
  Vector2 get centerOfMass => throw UnimplementedError('Implemented via Physics Worker');
  set centerOfMass(Vector2 value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The Rigidbody's resistance to changes in angular velocity (rotation).
  double get inertia => throw UnimplementedError('Implemented via Physics Worker');
  set inertia(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The additional Layers that all Collider2D attached to this Rigidbody2D should include when deciding if a contact with another Collider2D should happen or not.
  int get includeLayers => throw UnimplementedError('Implemented via Physics Worker');
  set includeLayers(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The Y component of the linear velocity of the Rigidbody2D in world-units per second.
  double get linearVelocityY => throw UnimplementedError('Implemented via Physics Worker');
  set linearVelocityY(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The transformation matrix used to transform the Rigidbody2D to world space.
  Matrix4 get localToWorldMatrix => throw UnimplementedError('Implemented via Physics Worker');
  set localToWorldMatrix(Matrix4 value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Mass of the Rigidbody.
  double get mass => throw UnimplementedError('Implemented via Physics Worker');
  set mass(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The X component of the linear velocity of the Rigidbody2D in world-units per second.
  double get linearVelocityX => throw UnimplementedError('Implemented via Physics Worker');
  set linearVelocityX(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The rotation of the rigidbody.
  double get rotation => throw UnimplementedError('Implemented via Physics Worker');
  set rotation(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The sleep state that the rigidbody will initially be in.
  RigidbodySleepMode get sleepMode => throw UnimplementedError('Implemented via Physics Worker');
  set sleepMode(RigidbodySleepMode value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The total amount of force that has been explicitly applied to this Rigidbody2D since the last physics simulation step.
  Vector2 get totalForce => throw UnimplementedError('Implemented via Physics Worker');
  set totalForce(Vector2 value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The PhysicsMaterial2D that is applied to all Collider2D attached to this Rigidbody2D.
  PhysicsMaterial get sharedMaterial => throw UnimplementedError('Implemented via Physics Worker');
  set sharedMaterial(PhysicsMaterial value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Should kinematic/kinematic and kinematic/static collisions be allowed?
  bool get useFullKinematicContacts => throw UnimplementedError('Implemented via Physics Worker');
  set useFullKinematicContacts(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Indicates whether the rigid body should be simulated or not by the physics system.
  bool get simulated => throw UnimplementedError('Implemented via Physics Worker');
  set simulated(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Gets the center of mass of the rigidBody in global space.
  Vector2 get worldCenterOfMass => throw UnimplementedError('Implemented via Physics Worker');
  set worldCenterOfMass(Vector2 value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Should the total rigid-body mass be automatically calculated from the Collider2D.density of attached colliders?
  bool get useAutoMass => throw UnimplementedError('Implemented via Physics Worker');
  set useAutoMass(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The total amount of torque that has been explicitly applied to this Rigidbody2D since the last physics simulation step.
  double get totalTorque => throw UnimplementedError('Implemented via Physics Worker');
  set totalTorque(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The position of the rigidbody.
  Vector2 get position => throw UnimplementedError('Implemented via Physics Worker');
  set position(Vector2 value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Apply a force to the rigidbody.
  /// - [force]: Components of the force in the X and Y axes.
  /// - [mode]: The method used to apply the specified force.
  void addForce(Vector2 force, ForceMode mode) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Apply a force at a given position in space.
  /// - [force]: Components of the force in the X and Y axes.
  /// - [position]: Position in world space to apply the force.
  /// - [mode]: The method used to apply the specified force.
  void addForceAtPosition(Vector2 force, Vector2 position, ForceMode mode) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Adds a force to the X component of the Rigidbody2D.linearVelocity only leaving the Y component of the world space Rigidbody2D.linearVelocity untouched.
  /// - [force]: The force to add to the X component of the Linear Velocity in the world space of the Rigidbody2D.
  /// - [mode]: The method used to apply the specified force.
  void addForceX(double force, ForceMode mode) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Adds a force to the Y component of the Rigidbody2D.linearVelocity only leaving the X component of the world space Rigidbody2D.linearVelocity untouched.
  /// - [force]: The force to add to the Y component of the Linear Velocity in the world space of the Rigidbody2D.
  /// - [mode]: The method used to apply the specified force.
  void addForceY(double force, ForceMode mode) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Apply a torque at the rigidbody's centre of mass.
  /// - [torque]: Torque to apply.
  /// - [mode]: The force mode to use.
  void addTorque(double torque, ForceMode mode) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// All the Collider2D shapes attached to the Rigidbody2D are cast into the Scene starting at each Collider position ignoring the Colliders attached to the same Rigidbody2D.
  /// - [direction]: Vector representing the direction to cast each Collider2D shape.
  /// - [results]: List to receive results.
  /// - [distance]: Maximum distance over which to cast the Collider(s).
  int cast(Vector2 direction, List<RaycastHit> results, double distance) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Returns a point on the perimeter of all enabled Colliders attached to this Rigidbody that is closest to the specified position.
  /// - [position]: The position from which to find the closest point on this Rigidbody.
  Vector2 closestPoint(Vector2 position) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Adds a force to the Y component of the Rigidbody2D.linearVelocity in the local space of the Rigidbody2D only leaving the X component of the local space Rigidbody2D.linearVelocity untouched.
  /// - [force]: The force to add to the Y component of the Linear Velocity in the local space of the Rigidbody2D.
  /// - [mode]: The method used to apply the specified force.
  void addRelativeForceY(double force, ForceMode mode) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Adds a force to the X component of the Rigidbody2D.linearVelocity in the local space of the Rigidbody2D only leaving the Y component of the local space Rigidbody2D.linearVelocity untouched.
  /// - [force]: The force to add to the X component of the Linear Velocity in the local space of the Rigidbody2D.
  /// - [mode]: The method used to apply the specified force.
  void addRelativeForceX(double force, ForceMode mode) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Adds a force to the local space Rigidbody2D.linearVelocity. In other words, the force is applied in the rotated coordinate space of the Rigidbody2D.
  /// - [relativeForce]: Components of the force in the X and Y axes.
  /// - [mode]: The method used to apply the specified force.
  void addRelativeForce(Vector2 relativeForce, ForceMode mode) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Retrieves all contact points for all of the Collider(s) attached to this Rigidbody.
  /// - [contactFilter]: The contact filter used to filter the results differently, such as by layer mask, Z depth, or normal angle.
  /// - [allocator]: The memory allocator to use for the results. This can only be Allocator.Temp, Allocator.TempJob or Allocator.Persistent.
  List<ContactPoint> getContacts(ContactFilter contactFilter, int allocator) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Retrieves all colliders in contact with this Rigidbody, with the results filtered by the contactFilter.
  /// - [contactFilter]: The contact filter used to filter the results differently, such as by layer mask, Z depth, or normal angle.
  /// - [allocator]: The contact filter used to filter the results differently, such as by layer mask, Z depth, or normal angle.
  List<Collider> getContactColliders(ContactFilter contactFilter, int allocator) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Get a local space point given the point point in rigidBody global space.
  /// - [point]: The global space point to transform into local space.
  Vector2 getPoint(Vector2 point) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Calculates the minimum distance of this collider against all Collider2D attached to this Rigidbody2D.
  /// - [collider]: A collider used to calculate the minimum distance against all colliders attached to this Rigidbody2D.
  double distance(Collider collider) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Returns all Collider2D that are attached to this Rigidbody2D.
  /// - [results]: An array of Collider2D used to receive the results.
  /// - [findTriggers]: Whether Collider2D that are triggers should be returned or not.
  int getAttachedColliders(List<Collider> results, bool findTriggers) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// The velocity of the rigidbody at the point Point in global space.
  /// - [point]: The global space point to calculate velocity for.
  Vector2 getPointVelocity(Vector2 point) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Get a global space point given the point relativePoint in rigidBody local space.
  /// - [relativePoint]: The local space point to transform into global space.
  Vector2 getRelativePoint(Vector2 relativePoint) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// The velocity of the rigidbody at the point Point in local space.
  /// - [relativePoint]: The local space point to calculate velocity for.
  Vector2 getRelativePointVelocity(Vector2 relativePoint) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Get a global space vector given the vector relativeVector in rigidBody local space.
  /// - [relativeVector]: The local space vector to transform into a global space vector.
  Vector2 getRelativeVector(Vector2 relativeVector) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Is the rigidbody "awake"?
  bool isAwake() {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Is the rigidbody "sleeping"?
  bool isSleeping() {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Checks whether the collider is touching any of the collider(s) attached to this rigidbody or not.
  /// - [collider]: The collider to check if it is touching any of the collider(s) attached to this rigidbody.
  bool isTouching(Collider collider) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Get a local space vector given the vector vector in rigidBody global space.
  /// - [vector]: The global space vector to transform into a local space vector.
  Vector2 getVector(Vector2 vector) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Gets all the PhysicsShape2D used by all Collider2D attached to the Rigidbody2D.
  /// - [physicsShapeGroup]: The PhysicsShapeGroup2D to store the retrieved PhysicsShape2D in.
  int getShapes(PhysicsShapeGroup physicsShapeGroup) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Moves the rigidbody to position.
  /// - [position]: The new position for the Rigidbody object.
  void movePosition(Vector2 position) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Get a list of all Colliders that overlap all Colliders attached to this Rigidbody2D.
  /// - [position]: The position to overlap the Rigidbody at.
  /// - [angle]: The angle to overlap the Rigidbody at.
  /// - [results]: The list to receive results.
  int overlap(Vector2 position, double angle, List<Collider> results) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Moves the rigidbody position to position and the rigidbody angle to angle.
  /// - [position]: The position to move the rigidbody to.
  /// - [angle]: The angle to move the rigidbody to.
  void movePositionAndRotation(Vector2 position, double angle) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Rotates the Rigidbody to angle (given in degrees).
  /// - [angle]: The new rotation angle for the Rigidbody object.
  void moveRotation(double angle) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Check if any of the Rigidbody2D colliders overlap a point in space.
  /// - [point]: A point in world space.
  bool overlapPoint(Vector2 point) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Slide the Rigidbody2D using the specified velocity integrated over deltaTime using the configuration specified by slideMovement.
  /// - [velocity]: The velocity to use when the Rigidbody2D is sliding.
  /// - [deltaTime]: The time to integrate the velocity over.
  /// - [slideMovement]: The configuration controlling of how the slide should be performed.
  SlideResults slide(Vector2 velocity, double deltaTime, SlideMovement slideMovement) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Disables the "sleeping" state of a rigidbody.
  void wakeUp() {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Checks whether any of the collider(s) attached to this rigidbody are touching any colliders on the specified layerMask or not.
  /// - [layerMask]: Any colliders on any of these layers count as touching.
  bool isTouchingLayers(int layerMask) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Sets the rotation of the Rigidbody2D to angle (given in degrees).
  /// - [angle]: The rotation of the Rigidbody (in degrees).
  void setRotation(double angle) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Make the rigidbody "sleep".
  void sleep() {
    throw UnimplementedError('Implemented via Physics Worker');
  }

}