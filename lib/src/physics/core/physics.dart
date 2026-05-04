import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/goo2d.dart';

/// Provides utilities and global settings to manage and simulate 2D physics interactions, such as collision detection and raycasting.
/// 
/// Equivalent to Unity's `Physics2D`.
class Physics {
  /// Use this to control whether or not the appropriate OnCollisionExit2D or OnTriggerExit2D callbacks should be called when a Collider2D is disabled.
  static bool get callbacksOnDisable => throw UnimplementedError('Implemented via Physics Worker');
  static set callbacksOnDisable(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Acceleration due to gravity.
  static Vector2 get gravity => throw UnimplementedError('Implemented via Physics Worker');
  static set gravity(Vector2 value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Any collisions with a relative linear velocity below this threshold will be treated as inelastic so no bounce will occur.
  static double get bounceThreshold => throw UnimplementedError('Implemented via Physics Worker');
  static set bounceThreshold(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// A threshold below which a contact is automatically disabled.
  static double get contactThreshold => throw UnimplementedError('Implemented via Physics Worker');
  static set contactThreshold(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The scale factor that controls how fast TOI overlaps are resolved.
  static double get baumgarteTOIScale => throw UnimplementedError('Implemented via Physics Worker');
  static set baumgarteTOIScale(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// A set of options that control how physics operates when using the job system to multithread the physics simulation.
  static PhysicsJobOptions get jobOptions => throw UnimplementedError('Implemented via Physics Worker');
  static set jobOptions(PhysicsJobOptions value) => throw UnimplementedError('Implemented via Physics Worker');

  /// A Rigidbody cannot sleep if its angular velocity is above this tolerance threshold.
  static double get angularSleepTolerance => throw UnimplementedError('Implemented via Physics Worker');
  static set angularSleepTolerance(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// A rigid-body cannot sleep if its linear velocity is above this tolerance.
  static double get linearSleepTolerance => throw UnimplementedError('Implemented via Physics Worker');
  static set linearSleepTolerance(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The scale factor that controls how fast overlaps are resolved.
  static double get baumgarteScale => throw UnimplementedError('Implemented via Physics Worker');
  static set baumgarteScale(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Layer mask constant that includes all layers.
  static int get allLayers => throw UnimplementedError('Implemented via Physics Worker');
  static set allLayers(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The maximum angular position correction used when solving constraints. This helps to prevent overshoot.
  static double get maxAngularCorrection => throw UnimplementedError('Implemented via Physics Worker');
  static set maxAngularCorrection(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Layer mask constant that includes all layers participating in raycasts by default.
  static int get defaultRaycastLayers => throw UnimplementedError('Implemented via Physics Worker');
  static set defaultRaycastLayers(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Layer mask constant for the default layer that ignores raycasts.
  static int get ignoreRaycastLayer => throw UnimplementedError('Implemented via Physics Worker');
  static set ignoreRaycastLayer(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The default contact offset of the newly created Colliders.
  static double get defaultContactOffset => throw UnimplementedError('Implemented via Physics Worker');
  static set defaultContactOffset(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The PhysicsScene2D automatically created when Unity starts.
  static PhysicsScene get defaultPhysicsScene => throw UnimplementedError('Implemented via Physics Worker');
  static set defaultPhysicsScene(PhysicsScene value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The maximum linear position correction used when solving constraints. This helps to prevent overshoot.
  static double get maxLinearCorrection => throw UnimplementedError('Implemented via Physics Worker');
  static set maxLinearCorrection(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The maximum number of vertices allowed per primitive polygon shape type (PhysicsShapeType2D.Polygon). (Read Only)
  static int get maxPolygonShapeVertices => throw UnimplementedError('Implemented via Physics Worker');
  static set maxPolygonShapeVertices(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The maximum angular speed of a rigid-body per physics update. Increasing this can cause numerical problems.
  static double get maxRotationSpeed => throw UnimplementedError('Implemented via Physics Worker');
  static set maxRotationSpeed(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The maximum number of simulation sub-steps allowed per-frame when simulation sub-stepping is enabled.
  static int get maxSubStepCount => throw UnimplementedError('Implemented via Physics Worker');
  static set maxSubStepCount(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The maximum linear speed of a rigid-body per physics update. Increasing this can cause numerical problems.
  static double get maxTranslationSpeed => throw UnimplementedError('Implemented via Physics Worker');
  static set maxTranslationSpeed(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The minimum FPS allowed for a simulation step before sub-stepping will be used.
  static double get minSubStepFPS => throw UnimplementedError('Implemented via Physics Worker');
  static set minSubStepFPS(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The number of iterations of the physics solver when considering objects' positions.
  static int get positionIterations => throw UnimplementedError('Implemented via Physics Worker');
  static set positionIterations(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The time in seconds that a rigid-body must be still before it will go to sleep.
  static double get timeToSleep => throw UnimplementedError('Implemented via Physics Worker');
  static set timeToSleep(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Whether to calculate contacts for all simulation sub-steps or only the first sub-step.
  static bool get useSubStepContacts => throw UnimplementedError('Implemented via Physics Worker');
  static set useSubStepContacts(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The Rigidbody2D and Collider2D layers to simulate.
  static int get simulationLayers => throw UnimplementedError('Implemented via Physics Worker');
  static set simulationLayers(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Determines whether the garbage collector should reuse only a single instance of a Collision2D type for all collision callbacks.
  static bool get reuseCollisionCallbacks => throw UnimplementedError('Implemented via Physics Worker');
  static set reuseCollisionCallbacks(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Whether to use simulation sub-stepping during a simulation step.
  static bool get useSubStepping => throw UnimplementedError('Implemented via Physics Worker');
  static set useSubStepping(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Controls when Unity executes the 2D physics simulation.
  static SimulationMode get simulationMode => throw UnimplementedError('Implemented via Physics Worker');
  static set simulationMode(SimulationMode value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Set the raycasts or linecasts that start inside Colliders to detect or not detect those Colliders.
  static bool get queriesStartInColliders => throw UnimplementedError('Implemented via Physics Worker');
  static set queriesStartInColliders(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The number of iterations of the physics solver when considering objects' velocities.
  static int get velocityIterations => throw UnimplementedError('Implemented via Physics Worker');
  static set velocityIterations(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Do raycasts detect Colliders configured as triggers?
  static bool get queriesHitTriggers => throw UnimplementedError('Implemented via Physics Worker');
  static set queriesHitTriggers(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Casts a capsule against Colliders in the Scene, returning all Colliders that contact with it.
  /// - [origin]: The point in 2D space where the capsule originates.
  /// - [size]: The size of the capsule.
  /// - [capsuleDirection]: The direction of the capsule.
  /// - [angle]: The angle of the capsule (in degrees).
  /// - [direction]: Vector representing the direction to cast the capsule.
  /// - [distance]: The maximum distance over which to cast the capsule.
  /// - [layerMask]: Filter to detect Colliders only on certain layers.
  /// - [minDepth]: Only include objects with a Z coordinate (depth) greater than this value.
  /// - [maxDepth]: Only include objects with a Z coordinate (depth) less than this value.
  static List<RaycastHit> capsuleCastAll(Vector2 origin, Vector2 size, CapsuleDirection capsuleDirection, double angle, Vector2 direction, double distance, int layerMask, double minDepth, double maxDepth) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Casts a box against Colliders in the Scene, returning all Colliders that contact with it.
  /// - [origin]: The point in 2D space where the box originates.
  /// - [size]: The size of the box.
  /// - [angle]: The angle of the box (in degrees).
  /// - [direction]: A vector representing the direction of the box.
  /// - [distance]: The maximum distance over which to cast the box.
  /// - [layerMask]: Filter to detect Colliders only on certain layers.
  /// - [minDepth]: Only include objects with a Z coordinate (depth) greater than or equal to this value.
  /// - [maxDepth]: Only include objects with a Z coordinate (depth) less than or equal to this value.
  static List<RaycastHit> boxCastAll(Vector2 origin, Vector2 size, double angle, Vector2 direction, double distance, int layerMask, double minDepth, double maxDepth) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Casts a capsule against the Colliders in the Scene and returns all Colliders that are in contact with it.
  /// - [origin]: The point in 2D space where the capsule originates.
  /// - [size]: The size of the capsule.
  /// - [capsuleDirection]: The direction of the capsule.
  /// - [angle]: The angle of the capsule (in degrees).
  /// - [direction]: A vector representing the direction to cast the capsule.
  /// - [contactFilter]: The contact filter used to filter the results differently, such as by layer mask, Z depth, or normal angle.
  /// - [distance]: The maximum distance over which to cast the capsule.
  /// - [allocator]: The memory allocator to use for the results. This can only be Allocator.Temp, Allocator.TempJob or Allocator.Persistent.
  static List<RaycastHit> capsuleCast(Vector2 origin, Vector2 size, CapsuleDirection capsuleDirection, double angle, Vector2 direction, ContactFilter contactFilter, double distance, int allocator) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Casts a circle against Colliders in the Scene, returning all Colliders that contact with it.
  /// - [origin]: The point in 2D space where the circle originates.
  /// - [radius]: The radius of the circle.
  /// - [direction]: A vector representing the direction of the circle.
  /// - [distance]: The maximum distance over which to cast the circle.
  /// - [layerMask]: Filter to detect Colliders only on certain layers.
  /// - [minDepth]: Only include objects with a Z coordinate (depth) greater than or equal to this value.
  /// - [maxDepth]: Only include objects with a Z coordinate (depth) less than or equal to this value.
  static List<RaycastHit> circleCastAll(Vector2 origin, double radius, Vector2 direction, double distance, int layerMask, double minDepth, double maxDepth) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Returns a point on the perimeter of the Collider that is closest to the specified position.
  /// - [position]: The position from which to find the closest point on the specified Collider.
  /// - [Collider]: The Collider on which to find the closest specified position.
  static Vector2 closestPoint(Vector2 position, Collider Collider) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Casts a circle against Colliders in the Scene, returning all Colliders that contact with it.
  /// - [origin]: The point in 2D space where the circle originates.
  /// - [radius]: The radius of the circle.
  /// - [direction]: A vector representing the direction to cast the circle.
  /// - [contactFilter]: The contact filter used to filter the results differently, such as by layer mask, Z depth, or normal angle.
  /// - [distance]: The maximum distance over which to cast the circle.
  /// - [allocator]: The memory allocator to use for the results. This can only be Allocator.Temp, Allocator.TempJob or Allocator.Persistent.
  static List<RaycastHit> circleCast(Vector2 origin, double radius, Vector2 direction, ContactFilter contactFilter, double distance, int allocator) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Calculates the minimum distance between two Colliders.
  /// - [colliderA]: A Collider used to calculate the minimum distance against colliderB.
  /// - [colliderB]: A Collider used to calculate the minimum distance against colliderA.
  static double distance(Collider colliderA, Collider colliderB) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Checks whether collisions between the specified layers be ignored or not.
  /// - [layer1]: ID of first layer.
  /// - [layer2]: ID of second layer.
  static bool getIgnoreLayerCollision(int layer1, int layer2) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Get the collision layer mask that indicates which layer(s) the specified layer can collide with.
  /// - [layer]: The layer to retrieve the collision layer mask for.
  static int getLayerCollisionMask(int layer) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Cast a 3D ray against the 2D Colliders in the Scene.
  /// - [ray]: The 3D ray defining origin and direction to test.
  /// - [distance]: The maximum distance over which to cast the ray.
  /// - [layerMask]: The LayerMask filter used to select which layers to detect Colliders for.
  /// - [allocator]: The memory allocator to use for the results. This can only be Allocator.Temp, Allocator.TempJob or Allocator.Persistent.
  static List<RaycastHit> getRayIntersection(Ray ray, double distance, int layerMask, int allocator) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Makes the collision detection system ignore all collisions/triggers between collider1 and collider2.
  /// - [collider1]: The first Collider to compare to collider2.
  /// - [collider2]: The second Collider to compare to collider1.
  /// - [ignore]: Whether collisions/triggers between collider1 and collider2 should be ignored or not.
  static void ignoreCollision(Collider collider1, Collider collider2, bool ignore) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Cast a 3D ray against the 2D Colliders in the Scene.
  /// - [ray]: The 3D ray defining origin and direction to test.
  /// - [distance]: The maximum distance over which to cast the ray.
  /// - [layerMask]: The LayerMask filter used to select which layers to detect Colliders for.
  static List<RaycastHit> getRayIntersectionAll(Ray ray, double distance, int layerMask) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Choose whether to detect or ignore collisions between a specified pair of layers.
  /// - [layer1]: ID of the first layer.
  /// - [layer2]: ID of the second layer.
  /// - [ignore]: Should collisions between these layers be ignored?
  static void ignoreLayerCollision(int layer1, int layer2, bool ignore) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Casts a line against Colliders in the Scene.
  /// - [start]: The start point of the line in world space.
  /// - [end]: The end point of the line in world space.
  /// - [layerMask]: Filter to detect Colliders only on certain layers.
  /// - [minDepth]: Only include objects with a Z coordinate (depth) greater than or equal to this value.
  /// - [maxDepth]: Only include objects with a Z coordinate (depth) less than or equal to this value.
  static List<RaycastHit> linecastAll(Vector2 start, Vector2 end, int layerMask, double minDepth, double maxDepth) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Casts a line segment against Colliders in the Scene with results filtered by ContactFilter2D.
  /// - [start]: The start point of the line in world space.
  /// - [end]: The end point of the line in world space.
  /// - [contactFilter]: The contact filter used to filter the results differently, such as by layer mask, Z depth, or normal angle.
  /// - [allocator]: The memory allocator to use for the results. This can only be Allocator.Temp, Allocator.TempJob or Allocator.Persistent.
  static List<RaycastHit> linecast(Vector2 start, Vector2 end, ContactFilter contactFilter, int allocator) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Checks whether the Collider is touching any Colliders on the specified layerMask or not.
  /// - [Collider]: The Collider to check if it is touching Colliders on the layerMask.
  /// - [layerMask]: Any Colliders on any of these layers count as touching.
  static bool isTouchingLayers(Collider Collider, int layerMask) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Finds Colliders that intersect a rectangular area.
  /// - [pointA]: One corner of the rectangle.
  /// - [pointB]: Diagonally opposite the point A corner of the rectangle.
  /// - [contactFilter]: The contact filter used to filter the results differently, such as by layer mask, Z depth. Note that normal angle is not used for overlap testing.
  /// - [allocator]: The memory allocator to use for the results. This can only be Allocator.Temp, Allocator.TempJob or Allocator.Persistent.
  static List<Collider> overlapArea(Vector2 pointA, Vector2 pointB, ContactFilter contactFilter, int allocator) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Get a list of all Colliders that fall within a rectangular area.
  /// - [pointA]: One corner of the rectangle.
  /// - [pointB]: Diagonally opposite the point A corner of the rectangle.
  /// - [layerMask]: Filter to check objects only on specific layers.
  /// - [minDepth]: Only include objects with a Z coordinate (depth) greater than or equal to this value.
  /// - [maxDepth]: Only include objects with a Z coordinate (depth) less than or equal to this value.
  static List<Collider> overlapAreaAll(Vector2 pointA, Vector2 pointB, int layerMask, double minDepth, double maxDepth) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Checks a box against Colliders in the scene, returning all intersections.
  /// - [point]: The center of the box.
  /// - [size]: The full size of the box.
  /// - [angle]: The angle of the box (in degrees).
  /// - [contactFilter]: The contact filter used to filter the results differently, such as by layer mask, Z depth. Note that normal angle is not used for overlap testing.
  /// - [allocator]: The memory allocator to use for the results. This can only be Allocator.Temp, Allocator.TempJob or Allocator.Persistent.
  static List<Collider> overlapBox(Vector2 point, Vector2 size, double angle, ContactFilter contactFilter, int allocator) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Casts a box against the Colliders in the Scene and returns all Colliders that are in contact with it.
  /// - [origin]: The point in 2D space where the box originates.
  /// - [size]: The size of the box.
  /// - [angle]: The angle of the box (in degrees).
  /// - [direction]: A vector representing the direction to cast the box.
  /// - [contactFilter]: The contact filter used to filter the results differently, such as by layer mask, Z depth, or normal angle.
  /// - [distance]: The maximum distance over which to cast the box.
  /// - [allocator]: The memory allocator to use for the results. This can only be Allocator.Temp, Allocator.TempJob or Allocator.Persistent.
  static List<RaycastHit> boxCast(Vector2 origin, Vector2 size, double angle, Vector2 direction, ContactFilter contactFilter, double distance, int allocator) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Get a list of all Colliders that fall within a box area.
  /// - [point]: The center of the box.
  /// - [size]: The size of the box.
  /// - [angle]: The angle of the box.
  /// - [layerMask]: Filter to check objects only on specific layers.
  /// - [minDepth]: Only include objects with a Z coordinate (depth) greater than this value.
  /// - [maxDepth]: Only include objects with a Z coordinate (depth) less than this value.
  static List<Collider> overlapBoxAll(Vector2 point, Vector2 size, double angle, int layerMask, double minDepth, double maxDepth) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Checks a circle against Colliders in the PhysicsScene2D, returning all intersections.
  /// - [point]: Centre of the circle.
  /// - [radius]: The radius of the circle.
  /// - [contactFilter]: The contact filter used to filter the results differently, such as by layer mask, Z depth. Note that normal angle is not used for overlap testing.
  /// - [allocator]: The memory allocator to use for the results. This can only be Allocator.Temp, Allocator.TempJob or Allocator.Persistent.
  static List<Collider> overlapCircle(Vector2 point, double radius, ContactFilter contactFilter, int allocator) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Checks whether the collision detection system will ignore all collisions/triggers between collider1 and collider2 or not.
  /// - [collider1]: The first Collider to compare to collider2.
  /// - [collider2]: The second Collider to compare to collider1.
  static bool getIgnoreCollision(Collider collider1, Collider collider2) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Retrieves all colliders in contact with this Collider, with the results filtered by the contactFilter.
  /// - [collider]: The Collider to retrieve contacts for.
  /// - [contactFilter]: The contact filter used to filter the results differently, such as by layer mask, Z depth, or normal angle.
  /// - [allocator]: The memory allocator to use for the results. This can only be Allocator.Temp, Allocator.TempJob or Allocator.Persistent.
  static List<Collider> getContactColliders(Collider collider, ContactFilter contactFilter, int allocator) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Gets a list of all Colliders that overlap the given Collider.
  /// - [collider]: The Collider that defines the area used to query for other Collider overlaps.
  /// - [contactFilter]: The contact filter used to filter the results differently, such as by layer mask, Z depth. Note that normal angle is not used for overlap testing.
  /// - [allocator]: The memory allocator to use for the results. This can only be Allocator.Temp, Allocator.TempJob or Allocator.Persistent.
  static List<Collider> overlapCollider(Collider collider, ContactFilter contactFilter, int allocator) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Checks a point against Colliders in the scene, returning all intersections.
  /// - [point]: A point in world space.
  /// - [contactFilter]: The contact filter used to filter the results differently, such as by layer mask, Z depth. Note that normal angle is not used for overlap testing.
  /// - [allocator]: The memory allocator to use for the results. This can only be Allocator.Temp, Allocator.TempJob or Allocator.Persistent.
  static List<Collider> overlapPoint(Vector2 point, ContactFilter contactFilter, int allocator) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Get a list of all Colliders that fall within a circular area.
  /// - [point]: The center of the circle.
  /// - [radius]: The radius of the circle.
  /// - [layerMask]: Filter to check objects only on specified layers.
  /// - [minDepth]: Only include objects with a Z coordinate (depth) greater than or equal to this value.
  /// - [maxDepth]: Only include objects with a Z coordinate (depth) less than or equal to this value.
  static List<Collider> overlapCircleAll(Vector2 point, double radius, int layerMask, double minDepth, double maxDepth) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Retrieves all contact points in contact with the Collider, with the results filtered by the contactFilter2D.
  /// - [collider]: The Collider to retrieve contacts for.
  /// - [contactFilter]: The contact filter used to filter the results differently, such as by layer mask, Z depth, or normal angle.
  /// - [allocator]: The memory allocator to use for the results. This can only be Allocator.Temp, Allocator.TempJob or Allocator.Persistent.
  static List<ContactPoint> getContacts(Collider collider, ContactFilter contactFilter, int allocator) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Casts a ray against Colliders in the Scene, returning all Colliders that contact with it.
  /// - [origin]: The point in 2D space where the ray originates.
  /// - [direction]: A vector representing the direction of the ray.
  /// - [distance]: The maximum distance over which to cast the ray.
  /// - [layerMask]: Filter to detect Colliders only on certain layers.
  /// - [minDepth]: Only include objects with a Z coordinate (depth) greater than or equal to this value.
  /// - [maxDepth]: Only include objects with a Z coordinate (depth) less than or equal to this value.
  static List<RaycastHit> raycastAll(Vector2 origin, Vector2 direction, double distance, int layerMask, double minDepth, double maxDepth) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Set the collision layer mask that indicates which layer(s) the specified layer can collide with.
  /// - [layer]: The layer to set the collision layer mask for.
  /// - [layerMask]: A mask where each bit indicates a layer and whether it can collide with layer or not.
  static void setLayerCollisionMask(int layer, int layerMask) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Checks whether the passed Colliders are in contact or not.
  /// - [collider1]: The Collider to check if it is touching collider2.
  /// - [collider2]: The Collider to check if it is touching collider1.
  static bool isTouching(Collider collider1, Collider collider2) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Synchronizes.
  static void syncTransforms() {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Checks a capsule against Colliders in the scene, returning all intersections.
  /// - [point]: The center of the capsule.
  /// - [size]: The size of the capsule.
  /// - [direction]: The direction of the capsule.
  /// - [angle]: The angle of the capsule (in degrees).
  /// - [contactFilter]: The contact filter used to filter the results differently, such as by layer mask, Z depth. Note that normal angle is not used for overlap testing.
  /// - [allocator]: The memory allocator to use for the results. This can only be Allocator.Temp, Allocator.TempJob or Allocator.Persistent.
  static List<Collider> overlapCapsule(Vector2 point, Vector2 size, CapsuleDirection direction, double angle, ContactFilter contactFilter, int allocator) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Get a list of all Colliders that fall within a capsule area.
  /// - [point]: The center of the capsule.
  /// - [size]: The size of the capsule.
  /// - [direction]: The direction of the capsule.
  /// - [angle]: The angle of the capsule.
  /// - [layerMask]: Filter to check objects only on specific layers.
  /// - [minDepth]: Only include objects with a Z coordinate (depth) greater than this value.
  /// - [maxDepth]: Only include objects with a Z coordinate (depth) less than this value.
  static List<Collider> overlapCapsuleAll(Vector2 point, Vector2 size, CapsuleDirection direction, double angle, int layerMask, double minDepth, double maxDepth) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Get a list of all Colliders that overlap a point in space.
  /// - [minDepth]: Only include objects with a Z coordinate (depth) greater than or equal to this value.
  /// - [maxDepth]: Only include objects with a Z coordinate (depth) less than or equal to this value.
  /// - [point]: A point in space.
  /// - [layerMask]: Filter to check objects only on specific layers.
  static List<Collider> overlapPointAll(Vector2 minDepth, int maxDepth, double point, double layerMask) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Casts a ray against Colliders in the Scene.
  /// - [origin]: The point in 2D space where the ray originates.
  /// - [direction]: A vector representing the direction of the ray.
  /// - [contactFilter]: The contact filter used to filter the results differently, such as by layer mask, Z depth, or normal angle.
  /// - [distance]: The maximum distance over which to cast the ray.
  /// - [allocator]: The memory allocator to use for the results. This can only be Allocator.Temp, Allocator.TempJob or Allocator.Persistent.
  static List<RaycastHit> raycast(Vector2 origin, Vector2 direction, ContactFilter contactFilter, double distance, int allocator) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Simulate physics in the default physics scene.
  /// - [deltaTime]: The time to advance physics by.
  /// - [simulationLayers]: The Rigidbody2D and Collider2D layers to simulate.
  static bool simulate(double deltaTime, int simulationLayers) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

}