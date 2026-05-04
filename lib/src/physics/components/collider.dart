import 'dart:ui' as ui;
import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/goo2d.dart';

/// The parent class for collider types used with 2D gameplay. Provides methods to defines the shape and physical behavior for 2D object interactions, used to detect collisions, and trigger events in 2D game environments.
/// 
/// Equivalent to Unity's `Collider2D`.
class Collider extends Component {
  /// The bounciness combine mode used by the Collider2D.
  PhysicsMaterialCombine get bounceCombine => throw UnimplementedError('Implemented via Physics Worker');
  set bounceCombine(PhysicsMaterialCombine value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The Layers that this Collider2D can receive forces from during a Collision contact with another Collider2D.
  int get forceReceiveLayers => throw UnimplementedError('Implemented via Physics Worker');
  set forceReceiveLayers(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The Layers that this Collider2D will report collision or trigger callbacks for during a contact with another Collider2D.
  int get callbackLayers => throw UnimplementedError('Implemented via Physics Worker');
  set callbackLayers(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The world space bounding area of the collider.
  ui.Rect get bounds => throw UnimplementedError('Implemented via Physics Worker');
  set bounds(ui.Rect value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The composite operation to be used by a CompositeCollider2D.
  CompositeOperation get compositeOperation => throw UnimplementedError('Implemented via Physics Worker');
  set compositeOperation(CompositeOperation value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The composite operation order to be used when a CompositeCollider2D is used.
  int get compositeOrder => throw UnimplementedError('Implemented via Physics Worker');
  set compositeOrder(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The layers of other Collider2D involved in contacts with this Collider2D that will be captured.
  int get contactCaptureLayers => throw UnimplementedError('Implemented via Physics Worker');
  set contactCaptureLayers(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The density of the collider used to calculate its mass (when auto mass is enabled).
  double get density => throw UnimplementedError('Implemented via Physics Worker');
  set density(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The error state that indicates the state of the physics shapes the 2D Collider tried to create. (Read Only)
  ColliderErrorState get errorState => throw UnimplementedError('Implemented via Physics Worker');
  set errorState(ColliderErrorState value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Get the CompositeCollider2D that is available to be attached to the collider.
  CompositeCollider get composite => throw UnimplementedError('Implemented via Physics Worker');
  set composite(CompositeCollider value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Calculates the effective LayerMask that the Collider2D will use when determining if it can contact another Collider2D.
  int get contactMask => throw UnimplementedError('Implemented via Physics Worker');
  set contactMask(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The bounciness used by the Collider2D.
  double get bounciness => throw UnimplementedError('Implemented via Physics Worker');
  set bounciness(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The additional Layers that this Collider2D should exclude when deciding if a contact with another Collider2D should happen or not.
  int get excludeLayers => throw UnimplementedError('Implemented via Physics Worker');
  set excludeLayers(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The Rigidbody2D attached to the Collider2D.
  Rigidbody get attachedRigidbody => throw UnimplementedError('Implemented via Physics Worker');
  set attachedRigidbody(Rigidbody value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Indicates if this Collider2D is capable of being composited by the CompositeCollider2D.
  bool get compositeCapable => throw UnimplementedError('Implemented via Physics Worker');
  set compositeCapable(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// A decision priority assigned to this Collider2D used when there is a conflicting decision on whether a contact between itself and another Collision2D should happen or not.
  int get layerOverridePriority => throw UnimplementedError('Implemented via Physics Worker');
  set layerOverridePriority(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The friction used by the Collider2D.
  double get friction => throw UnimplementedError('Implemented via Physics Worker');
  set friction(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Is this collider configured as a trigger?
  bool get isTrigger => throw UnimplementedError('Implemented via Physics Worker');
  set isTrigger(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The transformation matrix used to transform the Collider physics shapes to world space.
  Matrix4 get localToWorldMatrix => throw UnimplementedError('Implemented via Physics Worker');
  set localToWorldMatrix(Matrix4 value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The number of active PhysicsShape2D the Collider2D is currently using.
  int get shapeCount => throw UnimplementedError('Implemented via Physics Worker');
  set shapeCount(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The additional Layers that this Collider2D should include when deciding if a contact with another Collider2D should happen or not.
  int get includeLayers => throw UnimplementedError('Implemented via Physics Worker');
  set includeLayers(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Whether the collider is used by an attached effector or not.
  bool get usedByEffector => throw UnimplementedError('Implemented via Physics Worker');
  set usedByEffector(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The friction combine mode used by the Collider2D.
  PhysicsMaterialCombine get frictionCombine => throw UnimplementedError('Implemented via Physics Worker');
  set frictionCombine(PhysicsMaterialCombine value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The PhysicsMaterial2D that is applied to this collider.
  PhysicsMaterial get sharedMaterial => throw UnimplementedError('Implemented via Physics Worker');
  set sharedMaterial(PhysicsMaterial value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The local offset of the collider geometry.
  Vector2 get offset => throw UnimplementedError('Implemented via Physics Worker');
  set offset(Vector2 value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The Layers that this Collider2D is allowed to send forces to during a Collision contact with another Collider2D.
  int get forceSendLayers => throw UnimplementedError('Implemented via Physics Worker');
  set forceSendLayers(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Casts the Collider shape into the Scene starting at the Collider position ignoring the Collider itself.
  /// - [direction]: Vector representing the direction to cast the Collider.
  /// - [contactFilter]: Filter results defined by the contact filter.
  /// - [distance]: Maximum distance over which to cast the Collider.
  /// - [ignoreSiblingColliders]: Determines whether the cast should ignore other Colliders attached to the same Rigidbody2D (known as sibling colliders).
  /// - [allocator]: The memory allocator to use for the results. This can only be Allocator.Temp, Allocator.TempJob or Allocator.Persistent.
  List<RaycastHit> cast(Vector2 direction, ContactFilter contactFilter, double distance, bool ignoreSiblingColliders, int allocator) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// This method determines if both Colliders can ever come into contact.
  /// - [collider]: The other Collider that is to be checked to see if it can contact the current Collider.
  bool canContact(Collider collider) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Returns a point on the perimeter of this Collider that is closest to the specified position.
  /// - [position]: The position from which to find the closest point on this Collider.
  Vector2 closestPoint(Vector2 position) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Creates a planar Mesh that is identical to the area defined by the Collider2D geometry.
  /// - [useBodyPosition]: Should the mesh be transformed by the position of the attached Rigidbody2D?
  /// - [useBodyRotation]: Should the mesh be transformed by the rotation of the attached Rigidbody2D?
  /// - [useDelaunay]: When true, Delaunay triangulation is used to generate the mesh. This can reduce the number of vertices created in the Collider mesh and reduce the number of small triangle fans produced, both of which can improve overall mesh size and performance.
  SpriteMesh createMesh(bool useBodyPosition, bool useBodyRotation, bool useDelaunay) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Retrieves all colliders in contact with this Collider, with the results filtered by the contactFilter.
  /// - [contactFilter]: The contact filter used to filter the results differently, such as by layer mask, Z depth, or normal angle.
  /// - [allocator]: The memory allocator to use for the results. This can only be Allocator.Temp, Allocator.TempJob or Allocator.Persistent.
  List<Collider> getContactColliders(ContactFilter contactFilter, int allocator) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Calculates the minimum separation of this collider against another collider.
  /// - [collider]: A collider used to calculate the minimum separation against this collider.
  double distance(Collider collider) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Gets all the PhysicsShape2D used by the Collider2D.
  /// - [physicsShapeGroup]: The PhysicsShapeGroup2D to store the retrieved PhysicsShape2D in.
  int getShapes(PhysicsShapeGroup physicsShapeGroup) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Generates a simple hash value based upon the geometry of the Collider2D.
  int getShapeHash() {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Retrieves all contact points for this Collider, with the results filtered by the contactFilter.
  /// - [contactFilter]: The contact filter used to filter the results differently, such as by layer mask, Z depth, or normal angle.
  /// - [allocator]: The memory allocator to use for the results. This can only be Allocator.Temp, Allocator.TempJob or Allocator.Persistent.
  List<ContactPoint> getContacts(ContactFilter contactFilter, int allocator) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Retrieves a list of Bounds for all PhysicsShape2D created by this Collider2D, and returns the combined Bounds of the retrieved list.
  /// - [bounds]: The list used to store the returned Bounds.
  /// - [useRadii]: Whether the radius of each PhysicsShape2D should be used to calculate the Bounds or not.
  /// - [useWorldSpace]: Whether to transform all the returned Bounds to world space or leave them in their default local space.
  ui.Rect getShapeBounds(List<ui.Rect> bounds, bool useRadii, bool useWorldSpace) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Check if a collider overlaps a point in space.
  /// - [point]: A point in world space.
  bool overlapPoint(Vector2 point) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Casts a ray into the Scene that starts at the Collider position and ignores the Collider itself.
  /// - [direction]: Vector representing the direction of the ray.
  /// - [results]: Array to receive results.
  /// - [distance]: Maximum distance over which to cast the ray.
  /// - [layerMask]: Filter to check objects only on specific layers.
  /// - [minDepth]: Only include objects with a Z coordinate (depth) greater than this value.
  /// - [maxDepth]: Only include objects with a Z coordinate (depth) less than this value.
  int raycast(Vector2 direction, List<RaycastHit> results, double distance, int layerMask, double minDepth, double maxDepth) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Checks whether this collider is touching any colliders on the specified layerMask or not.
  /// - [layerMask]: Any colliders on any of these layers count as touching.
  bool isTouchingLayers(int layerMask) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// TODO.
  /// - [contactFilter]: The contact filter used to filter the results differently, such as by layer mask, Z depth. Note that normal angle is not used for overlap testing.
  /// - [results]: The list to receive results.
  List<Collider> overlap(ContactFilter contactFilter, int results) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Check whether this collider is touching the collider or not.
  /// - [collider]: The collider to check if it is touching this collider.
  bool isTouching(Collider collider) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

}