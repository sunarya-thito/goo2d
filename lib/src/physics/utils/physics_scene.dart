import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/goo2d.dart';

/// Represents a single instance of a 2D physics Scene.
/// 
/// Equivalent to Unity's `PhysicsScene2D`.
class PhysicsScene {
  /// Checks a Collider against Colliders in the PhysicsScene2D, returning all intersections.
  /// - [collider]: The Collider that defines the area used to query for other Collider overlaps.
  /// - [contactFilter]: The contact filter used to filter the results differently, such as by layer mask and Z depth. Note that the normal angle is not used for overlap testing.
  /// - [allocator]: The memory allocator to use for the results. This can only be Allocator.Temp, Allocator.TempJob or Allocator.Persistent.
  static List<Collider> overlapCollider(Collider collider, ContactFilter contactFilter, int allocator) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// The amount of simulation time that has been "lost" due to simulation sub-stepping hitting the maximum number of allowed sub-steps.
  double get subStepLostTime => throw UnimplementedError('Implemented via Physics Worker');
  set subStepLostTime(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The number of simulation sub-steps that occurred during the last simulation step.
  int get subStepCount => throw UnimplementedError('Implemented via Physics Worker');
  set subStepCount(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Checks a capsule against Colliders in the PhysicsScene2D, returning all intersections.
  /// - [point]: The center of the capsule.
  /// - [size]: The full size of the capsule.
  /// - [direction]: The direction of the capsule.
  /// - [angle]: The angle of the capsule (in degrees).
  /// - [contactFilter]: The contact filter used to filter the results differently, such as by layer mask and Z depth. Note that the normal angle is not used for overlap testing.
  /// - [allocator]: The memory allocator to use for the results. This can only be Allocator.Temp, Allocator.TempJob or Allocator.Persistent.
  List<Collider> overlapCapsule(Vector2 point, Vector2 size, CapsuleDirection direction, double angle, ContactFilter contactFilter, int allocator) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Casts a circle against the Colliders in the PhysicsScene2D, returning all intersections.
  /// - [origin]: The point in 2D space where the circle originates.
  /// - [radius]: The radius of the circle.
  /// - [direction]: Vector representing the direction to cast the circle.
  /// - [distance]: Maximum distance over which to cast the circle.
  /// - [contactFilter]: The contact filter used to filter the results differently, such as by layer mask, Z depth, or normal angle.
  /// - [allocator]: The memory allocator to use for the results. This can only be Allocator.Temp, Allocator.TempJob or Allocator.Persistent.
  List<RaycastHit> circleCast(Vector2 origin, double radius, Vector2 direction, double distance, ContactFilter contactFilter, int allocator) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Determines whether the physics Scene is empty or not.
  bool isEmpty() {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Checks an area (non-rotated box) against Colliders in the PhysicsScene2D, returning all intersections.
  /// - [pointA]: One corner of the rectangle.
  /// - [pointB]: The corner of the rectangle diagonally opposite the pointA corner.
  /// - [contactFilter]: The contact filter used to filter the results differently, such as by layer mask and Z depth. Note that the normal angle is not used for overlap testing.
  /// - [allocator]: The memory allocator to use for the results. This can only be Allocator.Temp, Allocator.TempJob or Allocator.Persistent.
  List<Collider> overlapArea(Vector2 pointA, Vector2 pointB, ContactFilter contactFilter, int allocator) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Casts a capsule against the Colliders in the PhysicsScene2D, returning all intersections.
  /// - [origin]: The point in 2D space where the capsule originates.
  /// - [size]: The size of the capsule.
  /// - [capsuleDirection]: The direction of the capsule.
  /// - [angle]: The angle of the capsule (in degrees).
  /// - [direction]: Vector representing the direction to cast the capsule.
  /// - [distance]: Maximum distance over which to cast the capsule.
  /// - [contactFilter]: The contact filter used to filter the results differently, such as by layer mask, Z depth, or normal angle.
  /// - [allocator]: The memory allocator to use for the results. This can only be Allocator.Temp, Allocator.TempJob or Allocator.Persistent.
  List<RaycastHit> capsuleCast(Vector2 origin, Vector2 size, CapsuleDirection capsuleDirection, double angle, Vector2 direction, double distance, ContactFilter contactFilter, int allocator) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Cast a 3D ray against the 2D Colliders in the Scene.
  /// - [ray]: The 3D ray defining origin and direction to test.
  /// - [distance]: The maximum distance over which to cast the ray.
  /// - [layerMask]: The LayerMask filter used to select which layers to detect Colliders for.
  /// - [allocator]: The memory allocator to use for the results. This can only be Allocator.Temp, Allocator.TempJob or Allocator.Persistent.
  List<RaycastHit> getRayIntersection(Ray ray, double distance, int layerMask, int allocator) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Casts a ray against Colliders the PhysicsScene2D, returning all intersections.
  /// - [origin]: The point in 2D space where the ray originates.
  /// - [direction]: The vector representing the direction of the ray.
  /// - [distance]: Maximum distance over which to cast the ray.
  /// - [contactFilter]: The contact filter used to filter the results differently, such as by layer mask and Z depth, or normal angle.
  /// - [allocator]: The memory allocator to use for the results. This can only be Allocator.Temp, Allocator.TempJob or Allocator.Persistent.
  List<RaycastHit> raycast(Vector2 origin, Vector2 direction, double distance, ContactFilter contactFilter, int allocator) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Checks a point against Colliders in the PhysicsScene2D, returning all intersections.
  /// - [point]: A point in world space.
  /// - [contactFilter]: The contact filter used to filter the results differently, such as by layer mask and Z depth. Note that the normal angle is not used for overlap testing.
  /// - [allocator]: The memory allocator to use for the results. This can only be Allocator.Temp, Allocator.TempJob or Allocator.Persistent.
  List<Collider> overlapPoint(Vector2 point, ContactFilter contactFilter, int allocator) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Casts a line segment against Colliders in the PhysicsScene2D.
  /// - [start]: The start point of the line in world space.
  /// - [end]: The end point of the line in world space.
  /// - [contactFilter]: The contact filter used to filter the results differently, such as by layer mask, Z depth, or normal angle.
  /// - [allocator]: The memory allocator to use for the results. This can only be Allocator.Temp, Allocator.TempJob or Allocator.Persistent.
  List<RaycastHit> linecast(Vector2 start, Vector2 end, ContactFilter contactFilter, int allocator) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Checks a circle against Colliders in the PhysicsScene2D, returning all intersections.
  /// - [point]: The centre of the circle.
  /// - [radius]: The radius of the circle.
  /// - [contactFilter]: The contact filter used to filter the results differently, such as by layer mask and Z depth. Note that the normal angle is not used for overlap testing.
  /// - [allocator]: The memory allocator to use for the results. This can only be Allocator.Temp, Allocator.TempJob or Allocator.Persistent.
  List<Collider> overlapCircle(Vector2 point, double radius, ContactFilter contactFilter, int allocator) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Casts a box against the Colliders in the PhysicsScene2D, returning all intersections.
  /// - [origin]: The point in 2D space where the box originates.
  /// - [size]: The size of the box.
  /// - [angle]: The angle of the box (in degrees).
  /// - [direction]: Vector representing the direction to cast the box.
  /// - [distance]: Maximum distance over which to cast the box.
  /// - [contactFilter]: The contact filter used to filter the results differently, such as by layer mask, Z depth, or normal angle.
  /// - [allocator]: The memory allocator to use for the results. This can only be Allocator.Temp, Allocator.TempJob or Allocator.Persistent.
  List<RaycastHit> boxCast(Vector2 origin, Vector2 size, double angle, Vector2 direction, double distance, ContactFilter contactFilter, int allocator) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Simulate physics associated with this PhysicsScene.
  /// - [deltaTime]: The time to advance physics by.
  /// - [simulationLayers]: The Rigidbody2D and Collider2D layers to simulate.
  bool simulate(double deltaTime, int simulationLayers) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Determines whether the physics Scene is valid or not.
  bool isValid() {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Checks a box against Colliders in the PhysicsScene2D, returning all intersections.
  /// - [point]: The center of the box.
  /// - [size]: The full size of the box.
  /// - [angle]: The angle of the box (in degrees).
  /// - [contactFilter]: The contact filter used to filter the results differently, such as by layer mask and Z depth. Note that the normal angle is not used for overlap testing.
  /// - [allocator]: The memory allocator to use for the results. This can only be Allocator.Temp, Allocator.TempJob or Allocator.Persistent.
  List<Collider> overlapBox(Vector2 point, Vector2 size, double angle, ContactFilter contactFilter, int allocator) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

}