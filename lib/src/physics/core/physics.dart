import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/goo2d.dart';
import 'package:goo2d/src/physics/worker/physics_worker.dart';

/// Provides utilities and global settings to manage and simulate 2D physics interactions, such as collision detection and raycasting.
/// 
/// Equivalent to Unity's `Physics2D`.
class Physics {
  static PhysicsWorker? _worker;

  /// Initializes the physics system with a worker.
  static void initialize(PhysicsWorker worker) {
    _worker = worker;
    // Push initial global settings to worker if needed
    _worker?.setGravity(_gravity);
  }

  static PhysicsWorker get _safeWorker {
    if (_worker == null) {
      throw StateError('Physics has not been initialized. Ensure PhysicsSystem is attached to the engine.');
    }
    return _worker!;
  }

  static bool _callbacksOnDisable = true;
  /// Use this to control whether or not the appropriate OnCollisionExit2D or OnTriggerExit2D callbacks should be called when a Collider2D is disabled.
  static bool get callbacksOnDisable => _callbacksOnDisable;
  static set callbacksOnDisable(bool value) {
    _callbacksOnDisable = value;
    _worker?.setCallbacksOnDisable(value);
  }

  static Vector2 _gravity = Vector2(0, -9.81);
  /// Acceleration due to gravity.
  static Vector2 get gravity => _gravity;
  static set gravity(Vector2 value) {
    _gravity = value;
    _worker?.setGravity(value);
  }

  static double _bounceThreshold = 0.2;
  /// Any collisions with a relative linear velocity below this threshold will be treated as inelastic so no bounce will occur.
  static double get bounceThreshold => _bounceThreshold;
  static set bounceThreshold(double value) {
    _bounceThreshold = value;
    _worker?.setBounceThreshold(value);
  }

  static double _contactThreshold = 0.01;
  /// A threshold below which a contact is automatically disabled.
  static double get contactThreshold => _contactThreshold;
  static set contactThreshold(double value) {
    _contactThreshold = value;
    _worker?.setContactThreshold(value);
  }

  static double _baumgarteTOIScale = 0.75;
  /// The scale factor that controls how fast TOI overlaps are resolved.
  static double get baumgarteTOIScale => _baumgarteTOIScale;
  static set baumgarteTOIScale(double value) {
    _baumgarteTOIScale = value;
    _worker?.setBaumgarteTOIScale(value);
  }

  static double _angularSleepTolerance = 0.01;
  /// A Rigidbody cannot sleep if its angular velocity is above this tolerance threshold.
  static double get angularSleepTolerance => _angularSleepTolerance;
  static set angularSleepTolerance(double value) {
    _angularSleepTolerance = value;
    _worker?.setAngularSleepTolerance(value);
  }

  static double _linearSleepTolerance = 0.01;
  /// A rigid-body cannot sleep if its linear velocity is above this tolerance.
  static double get linearSleepTolerance => _linearSleepTolerance;
  static set linearSleepTolerance(double value) {
    _linearSleepTolerance = value;
    _worker?.setLinearSleepTolerance(value);
  }

  static double _baumgarteScale = 0.2;
  /// The scale factor that controls how fast overlaps are resolved.
  static double get baumgarteScale => _baumgarteScale;
  static set baumgarteScale(double value) {
    _baumgarteScale = value;
    _worker?.setBaumgarteScale(value);
  }

  /// Layer mask constant that includes all layers.
  static const int allLayers = ~0;

  static double _maxAngularCorrection = 8.0;
  /// The maximum angular position correction used when solving constraints. This helps to prevent overshoot.
  static double get maxAngularCorrection => _maxAngularCorrection;
  static set maxAngularCorrection(double value) {
    _maxAngularCorrection = value;
    _worker?.setMaxAngularCorrection(value);
  }

  /// Layer mask constant that includes all layers participating in raycasts by default.
  static const int defaultRaycastLayers = ~0;

  /// Layer mask constant used to specify that raycasts should ignore any Colliders on this layer.
  static const int ignoreRaycastLayer = 1 << 2;

  /// Returns the maximum number of vertices allowed for a PolygonCollider2D.
  static int get maxPolygonShapeVertices => 8;

  static double _defaultContactOffset = 0.01;
  /// The default contact offset of the newly created Colliders.
  static double get defaultContactOffset => _defaultContactOffset;
  static set defaultContactOffset(double value) {
    _defaultContactOffset = value;
    _worker?.setDefaultContactOffset(value);
  }

  static double _maxLinearCorrection = 0.2;
  /// The maximum linear position correction used when solving constraints. This helps to prevent overshoot.
  static double get maxLinearCorrection => _maxLinearCorrection;
  static set maxLinearCorrection(double value) {
    _maxLinearCorrection = value;
    _worker?.setMaxLinearCorrection(value);
  }

  // ===================== Scene Queries =====================

  /// Casts a capsule against Colliders in the Scene.
  static Future<RaycastHit?> capsuleCast(Vector2 origin, Vector2 size, CapsuleDirection capsuleDirection, double angle, Vector2 direction, [double distance = double.infinity, int layerMask = defaultRaycastLayers, double minDepth = -double.infinity, double maxDepth = double.infinity]) async {
    final results = await capsuleCastAll(origin, size, capsuleDirection, angle, direction, distance, layerMask, minDepth, maxDepth);
    return results.isNotEmpty ? results.first : null;
  }

  /// Casts a circle against Colliders in the Scene.
  static Future<RaycastHit?> circleCast(Vector2 origin, double radius, Vector2 direction, [double distance = double.infinity, int layerMask = defaultRaycastLayers, double minDepth = -double.infinity, double maxDepth = double.infinity]) async {
    final results = await circleCastAll(origin, radius, direction, distance, layerMask, minDepth, maxDepth);
    return results.isNotEmpty ? results.first : null;
  }

  /// Returns the first RaycastHit2D for the first Collider intersected by the ray.
  static Future<RaycastHit?> getRayIntersection(Vector2 origin, Vector2 direction, [double distance = double.infinity, int layerMask = defaultRaycastLayers]) async {
    final results = await getRayIntersectionAll(origin, direction, distance, layerMask);
    return results.isNotEmpty ? results.first : null;
  }

  /// Returns all the RaycastHit2D for all the Colliders intersected by the ray.
  static Future<List<RaycastHit>> getRayIntersectionAll(Vector2 origin, Vector2 direction, [double distance = double.infinity, int layerMask = defaultRaycastLayers]) async {
    return raycastAll(origin, direction, distance, layerMask, -double.infinity, double.infinity);
  }

  /// Returns the first RaycastHit2D for the first Collider intersected by the line.
  static Future<RaycastHit?> linecast(Vector2 start, Vector2 end, [int layerMask = defaultRaycastLayers, double minDepth = -double.infinity, double maxDepth = double.infinity]) async {
    final results = await linecastAll(start, end, layerMask, minDepth, maxDepth);
    return results.isNotEmpty ? results.first : null;
  }

  /// Checks whether a Collider overlaps an area in the Scene.
  static Future<Collider?> overlapArea(Vector2 topLeft, Vector2 bottomRight, [int layerMask = defaultRaycastLayers, double minDepth = -double.infinity, double maxDepth = double.infinity]) async {
    final results = await overlapAreaAll(topLeft, bottomRight, layerMask, minDepth, maxDepth);
    return results.isNotEmpty ? results.first : null;
  }

  /// Checks whether a Collider overlaps a box in the Scene.
  static Future<Collider?> overlapBox(Vector2 point, Vector2 size, double angle, [int layerMask = defaultRaycastLayers, double minDepth = -double.infinity, double maxDepth = double.infinity]) async {
    final results = await overlapBoxAll(point, size, angle, layerMask, minDepth, maxDepth);
    return results.isNotEmpty ? results.first : null;
  }

  /// Casts a box against Colliders in the Scene.
  static Future<RaycastHit?> boxCast(Vector2 origin, Vector2 size, double angle, Vector2 direction, [double distance = double.infinity, int layerMask = defaultRaycastLayers, double minDepth = -double.infinity, double maxDepth = double.infinity]) async {
    final results = await boxCastAll(origin, size, angle, direction, distance, layerMask, minDepth, maxDepth);
    return results.isNotEmpty ? results.first : null;
  }

  /// Checks whether a Collider overlaps a circle in the Scene.
  static Future<Collider?> overlapCircle(Vector2 point, double radius, [int layerMask = defaultRaycastLayers, double minDepth = -double.infinity, double maxDepth = double.infinity]) async {
    final results = await overlapCircleAll(point, radius, layerMask, minDepth, maxDepth);
    return results.isNotEmpty ? results.first : null;
  }

  /// Checks whether a Collider overlaps a point in the Scene.
  static Future<Collider?> overlapPoint(Vector2 point, [int layerMask = defaultRaycastLayers, double minDepth = -double.infinity, double maxDepth = double.infinity]) async {
    final results = await overlapPointAll(point, layerMask, minDepth, maxDepth);
    return results.isNotEmpty ? results.first : null;
  }

  /// Checks whether a Collider overlaps a capsule in the Scene.
  static Future<Collider?> overlapCapsule(Vector2 point, Vector2 size, CapsuleDirection capsuleDirection, double angle, [int layerMask = defaultRaycastLayers, double minDepth = -double.infinity, double maxDepth = double.infinity]) async {
    final results = await overlapCapsuleAll(point, size, capsuleDirection, angle, layerMask, minDepth, maxDepth);
    return results.isNotEmpty ? results.first : null;
  }

  /// Casts a ray against Colliders in the Scene.
  static Future<RaycastHit?> raycast(Vector2 origin, Vector2 direction, [double distance = double.infinity, int layerMask = defaultRaycastLayers, double minDepth = -double.infinity, double maxDepth = double.infinity]) async {
    final results = await raycastAll(origin, direction, distance, layerMask, minDepth, maxDepth);
    return results.isNotEmpty ? results.first : null;
  }

  static double _maxRotationSpeed = 360.0;
  /// The maximum angular speed of a rigid-body per physics update. Increasing this can cause numerical problems.
  static double get maxRotationSpeed => _maxRotationSpeed;
  static set maxRotationSpeed(double value) {
    _maxRotationSpeed = value;
    _worker?.setMaxRotationSpeed(value);
  }

  static int _maxSubStepCount = 8;
  /// The maximum number of simulation sub-steps allowed per-frame when simulation sub-stepping is enabled.
  static int get maxSubStepCount => _maxSubStepCount;
  static set maxSubStepCount(int value) {
    _maxSubStepCount = value;
    _worker?.setMaxSubStepCount(value);
  }

  static double _maxTranslationSpeed = 100.0;
  /// The maximum linear speed of a rigid-body per physics update. Increasing this can cause numerical problems.
  static double get maxTranslationSpeed => _maxTranslationSpeed;
  static set maxTranslationSpeed(double value) {
    _maxTranslationSpeed = value;
    _worker?.setMaxTranslationSpeed(value);
  }

  static double _minSubStepFPS = 1.0;
  /// The minimum FPS allowed for a simulation step before sub-stepping will be used.
  static double get minSubStepFPS => _minSubStepFPS;
  static set minSubStepFPS(double value) {
    _minSubStepFPS = value;
    _worker?.setMinSubStepFPS(value);
  }

  static int _positionIterations = 3;
  /// The number of iterations of the physics solver when considering objects' positions.
  static int get positionIterations => _positionIterations;
  static set positionIterations(int value) {
    _positionIterations = value;
    _worker?.setPositionIterations(value);
  }

  static double _timeToSleep = 0.5;
  /// The time in seconds that a rigid-body must be still before it will go to sleep.
  static double get timeToSleep => _timeToSleep;
  static set timeToSleep(double value) {
    _timeToSleep = value;
    _worker?.setTimeToSleep(value);
  }

  static bool _useSubStepContacts = false;
  /// Whether to calculate contacts for all simulation sub-steps or only the first sub-step.
  static bool get useSubStepContacts => _useSubStepContacts;
  static set useSubStepContacts(bool value) {
    _useSubStepContacts = value;
    _worker?.setUseSubStepContacts(value);
  }

  static int _simulationLayers = ~0;
  /// The Rigidbody2D and Collider2D layers to simulate.
  static int get simulationLayers => _simulationLayers;
  static set simulationLayers(int value) {
    _simulationLayers = value;
    _worker?.setSimulationLayers(value);
  }

  static bool _reuseCollisionCallbacks = true;
  /// Determines whether the garbage collector should reuse only a single instance of a Collision2D type for all collision callbacks.
  static bool get reuseCollisionCallbacks => _reuseCollisionCallbacks;
  static set reuseCollisionCallbacks(bool value) {
    _reuseCollisionCallbacks = value;
    _worker?.setReuseCollisionCallbacks(value);
  }

  static bool _useSubStepping = false;
  /// Whether to use simulation sub-stepping during a simulation step.
  static bool get useSubStepping => _useSubStepping;
  static set useSubStepping(bool value) {
    _useSubStepping = value;
    _worker?.setUseSubStepping(value);
  }

  static SimulationMode _simulationMode = SimulationMode.fixedUpdate;
  /// Controls when Unity executes the 2D physics simulation.
  static SimulationMode get simulationMode => _simulationMode;
  static set simulationMode(SimulationMode value) {
    _simulationMode = value;
    _worker?.setSimulationMode(value.index);
  }

  static bool _queriesStartInColliders = true;
  /// Set the raycasts or linecasts that start inside Colliders to detect or not detect those Colliders.
  static bool get queriesStartInColliders => _queriesStartInColliders;
  static set queriesStartInColliders(bool value) {
    _queriesStartInColliders = value;
    _worker?.setQueriesStartInColliders(value);
  }

  static int _velocityIterations = 8;
  /// The number of iterations of the physics solver when considering objects' velocities.
  static int get velocityIterations => _velocityIterations;
  static set velocityIterations(int value) {
    _velocityIterations = value;
    _worker?.setVelocityIterations(value);
  }

  static bool _queriesHitTriggers = true;
  /// Do raycasts detect Colliders configured as triggers?
  static bool get queriesHitTriggers => _queriesHitTriggers;
  static set queriesHitTriggers(bool value) {
    _queriesHitTriggers = value;
    _worker?.setQueriesHitTriggers(value);
  }

  /// Casts a capsule against Colliders in the Scene, returning all Colliders that contact with it.
  static Future<List<RaycastHit>> capsuleCastAll(Vector2 origin, Vector2 size, CapsuleDirection capsuleDirection, double angle, Vector2 direction, double distance, int layerMask, double minDepth, double maxDepth) async {
    final results = await _safeWorker.capsuleCast(origin, size, capsuleDirection.index, angle, direction, distance, layerMask, minDepth, maxDepth);
    return results.map((d) => RaycastHit.fromData(d)).whereType<RaycastHit>().toList();
  }

  /// Casts a box against Colliders in the Scene, returning all Colliders that contact with it.
  static Future<List<RaycastHit>> boxCastAll(Vector2 origin, Vector2 size, double angle, Vector2 direction, double distance, int layerMask, double minDepth, double maxDepth) async {
    final results = await _safeWorker.boxCast(origin, size, angle, direction, distance, layerMask, minDepth, maxDepth);
    return results.map((d) => RaycastHit.fromData(d)).whereType<RaycastHit>().toList();
  }

  /// Casts a circle against Colliders in the Scene, returning all Colliders that contact with it.
  static Future<List<RaycastHit>> circleCastAll(Vector2 origin, double radius, Vector2 direction, double distance, int layerMask, double minDepth, double maxDepth) async {
    final results = await _safeWorker.circleCast(origin, radius, direction, distance, layerMask, minDepth, maxDepth);
    return results.map((d) => RaycastHit.fromData(d)).whereType<RaycastHit>().toList();
  }

  /// Returns a point on the perimeter of the Collider that is closest to the specified position.
  static Future<Vector2> closestPoint(Vector2 position, Collider collider) async {
    return _safeWorker.closestPoint(position, await collider.handle);
  }

  /// Calculates the minimum distance between two Colliders.
  static Future<double> distance(Collider colliderA, Collider colliderB) async {
    return _safeWorker.colliderDistance(await colliderA.handle, await colliderB.handle);
  }

  /// Checks whether collisions between the specified layers be ignored or not.
  static Future<bool> getIgnoreLayerCollision(int layer1, int layer2) => _safeWorker.getIgnoreLayerCollision(layer1, layer2);

  /// Get the collision layer mask that indicates which layer(s) the specified layer can collide with.
  static Future<int> getLayerCollisionMask(int layer) => _safeWorker.getLayerCollisionMask(layer);

  /// Makes the collision detection system ignore all collisions/triggers between collider1 and collider2.
  static void ignoreCollision(Collider collider1, Collider collider2, bool ignore) async {
    _safeWorker.ignoreCollision(await collider1.handle, await collider2.handle, ignore);
  }

  /// Choose whether to detect or ignore collisions between a specified pair of layers.
  static void ignoreLayerCollision(int layer1, int layer2, bool ignore) {
    _safeWorker.setIgnoreLayerCollision(layer1, layer2, ignore);
  }

  /// Casts a line against Colliders in the Scene.
  static Future<List<RaycastHit>> linecastAll(Vector2 start, Vector2 end, int layerMask, double minDepth, double maxDepth) async {
    final results = await _safeWorker.linecast(start, end, layerMask, minDepth, maxDepth);
    return results.map((d) => RaycastHit.fromData(d)).whereType<RaycastHit>().toList();
  }

  /// Checks whether the Collider is touching any Colliders on the specified layerMask or not.
  static Future<bool> isTouchingLayers(Collider collider, int layerMask) async {
    return _safeWorker.colliderIsTouchingLayers(await collider.handle, layerMask);
  }

  /// Get a list of all Colliders that fall within a rectangular area.
  static Future<List<Collider>> overlapAreaAll(Vector2 pointA, Vector2 pointB, int layerMask, double minDepth, double maxDepth) async {
    // b2AABB search is basically overlapBox with 0 angle or similar
    final center = (pointA + pointB) * 0.5;
    final size = Vector2((pointA.x - pointB.x).abs(), (pointA.y - pointB.y).abs());
    final handles = await _safeWorker.overlapBox(center, size, 0, layerMask, minDepth, maxDepth);
    return handles.map((h) => PhysicsSystem.getCollider(h)).whereType<Collider>().toList();
  }

  /// Get a list of all Colliders that fall within a box area.
  static Future<List<Collider>> overlapBoxAll(Vector2 point, Vector2 size, double angle, int layerMask, double minDepth, double maxDepth) async {
    final handles = await _safeWorker.overlapBox(point, size, angle, layerMask, minDepth, maxDepth);
    return handles.map((h) => PhysicsSystem.getCollider(h)).whereType<Collider>().toList();
  }

  /// Checks whether the collision detection system will ignore all collisions/triggers between collider1 and collider2 or not.
  static Future<bool> getIgnoreCollision(Collider collider1, Collider collider2) async {
    return _safeWorker.getIgnoreCollision(await collider1.handle, await collider2.handle);
  }

  /// Retrieves all colliders in contact with this Collider.
  static Future<List<Collider>> getContactColliders(Collider collider) async {
    final handles = await _safeWorker.getContactColliders(await collider.handle);
    return handles.map((h) => PhysicsSystem.getCollider(h)).whereType<Collider>().toList();
  }

  /// Gets a list of all Colliders that overlap the given Collider.
  static Future<List<Collider>> overlapCollider(Collider collider) async {
    final handles = await _safeWorker.overlapCollider(await collider.handle);
    return handles.map((h) => PhysicsSystem.getCollider(h)).whereType<Collider>().toList();
  }

  /// Get a list of all Colliders that fall within a circular area.
  static Future<List<Collider>> overlapCircleAll(Vector2 point, double radius, int layerMask, double minDepth, double maxDepth) async {
    final handles = await _safeWorker.overlapCircle(point, radius, layerMask, minDepth, maxDepth);
    return handles.map((h) => PhysicsSystem.getCollider(h)).whereType<Collider>().toList();
  }

  /// Retrieves all contact points in contact with the Collider.
  static Future<List<ContactPoint>> getContacts(Collider collider) async {
    final data = await _safeWorker.getContacts(await collider.handle);
    return data.map((d) => ContactPoint.fromData(d)).whereType<ContactPoint>().toList();
  }

  /// Casts a ray against Colliders in the Scene, returning all Colliders that contact with it.
  static Future<List<RaycastHit>> raycastAll(Vector2 origin, Vector2 direction, double distance, int layerMask, double minDepth, double maxDepth) async {
    final results = await _safeWorker.raycast(origin, direction, distance, layerMask, minDepth, maxDepth);
    return results.map((d) => RaycastHit.fromData(d)).whereType<RaycastHit>().toList();
  }

  /// Set the collision layer mask that indicates which layer(s) the specified layer can collide with.
  static void setLayerCollisionMask(int layer, int layerMask) {
    _safeWorker.setLayerCollisionMask(layer, layerMask);
  }

  /// Checks whether the passed Colliders are in contact or not.
  static Future<bool> isTouching(Collider collider1, Collider collider2) async {
    return _safeWorker.colliderIsTouching(await collider1.handle, await collider2.handle);
  }

  /// Synchronizes transforms from the physics engine back to the GameObjects.
  static Future<void> syncTransforms() => _safeWorker.syncTransforms();

  /// Get a list of all Colliders that fall within a capsule area.
  static Future<List<Collider>> overlapCapsuleAll(Vector2 point, Vector2 size, CapsuleDirection direction, double angle, int layerMask, double minDepth, double maxDepth) async {
    final rad = angle * math.pi / 180.0;
    final cosA = math.cos(rad);
    final sinA = math.sin(rad);
    final handles = <int>{};

    if (direction == CapsuleDirection.vertical) {
      final radius = size.x / 2;
      final halfBody = (size.y - size.x) / 2;
      if (halfBody > 0) {
        handles.addAll(await _safeWorker.overlapBox(point, Vector2(size.x, size.y - size.x), angle, layerMask, minDepth, maxDepth));
      }
      handles.addAll(await _safeWorker.overlapCircle(point + Vector2(-halfBody * sinA, halfBody * cosA), radius, layerMask, minDepth, maxDepth));
      handles.addAll(await _safeWorker.overlapCircle(point + Vector2(halfBody * sinA, -halfBody * cosA), radius, layerMask, minDepth, maxDepth));
    } else {
      final radius = size.y / 2;
      final halfBody = (size.x - size.y) / 2;
      if (halfBody > 0) {
        handles.addAll(await _safeWorker.overlapBox(point, Vector2(size.x - size.y, size.y), angle, layerMask, minDepth, maxDepth));
      }
      handles.addAll(await _safeWorker.overlapCircle(point + Vector2(halfBody * cosA, halfBody * sinA), radius, layerMask, minDepth, maxDepth));
      handles.addAll(await _safeWorker.overlapCircle(point + Vector2(-halfBody * cosA, -halfBody * sinA), radius, layerMask, minDepth, maxDepth));
    }

    return handles.map((h) => PhysicsSystem.getCollider(h)).whereType<Collider>().toList();
  }

  /// Get a list of all Colliders that overlap a point in space.
  static Future<List<Collider>> overlapPointAll(Vector2 point, int layerMask, double minDepth, double maxDepth) async {
    final handles = await _safeWorker.overlapPoint(point, layerMask, minDepth, maxDepth);
    return handles.map((h) => PhysicsSystem.getCollider(h)).whereType<Collider>().toList();
  }

  /// Simulate physics in the default physics scene.
  static void simulate(double deltaTime) {
    _safeWorker.step(deltaTime);
  }
}