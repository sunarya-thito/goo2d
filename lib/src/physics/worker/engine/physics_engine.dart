import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/src/physics/worker/engine/physics_body.dart';
import 'package:goo2d/src/physics/worker/engine/physics_collider.dart';
import 'package:goo2d/src/physics/worker/engine/physics_joint.dart';
import 'package:goo2d/src/physics/worker/engine/physics_effector.dart';
import 'package:goo2d/src/physics/worker/engine/engine_queries.dart';
import 'package:goo2d/src/physics/worker/engine/engine_step.dart';
import 'package:goo2d/src/physics/worker/data/collider_shape_type.dart';
import 'package:goo2d/src/physics/worker/data/raycast_hit_data.dart';
import 'package:goo2d/src/physics/worker/data/contact_point_data.dart';

import 'package:goo2d/src/physics/worker/engine/collision/narrowphase.dart';
import 'package:goo2d/src/physics/worker/engine/collision/contact_tracker.dart';

/// The core 2D physics simulation engine.
///
/// Both [DirectPhysicsWorker] and [IsolatePhysicsWorker] delegate to this.
/// Matches Unity's Physics2D simulation behavior.
class PhysicsEngine {
  // --- Global Settings ---
  Vector2 gravity = Vector2(0, -9.81);
  bool callbacksOnDisable = true;
  double bounceThreshold = 1.0;
  double contactThreshold = 0.01;
  double baumgarteTOIScale = 0.75;
  double baumgarteScale = 0.2;
  double angularSleepTolerance = 2.0;
  double linearSleepTolerance = 0.01;
  double defaultContactOffset = 0.01;
  double maxAngularCorrection = 8.0;
  double maxLinearCorrection = 0.2;
  double maxRotationSpeed = 360.0;
  double maxTranslationSpeed = 100.0;
  double minSubStepFPS = 50.0;
  double timeToSleep = 0.5;
  int positionIterations = 3;
  int velocityIterations = 8;
  int maxSubStepCount = 8;
  int maxPolygonShapeVertices = 8;
  int allLayers = ~0;
  int defaultRaycastLayers = ~0;
  int ignoreRaycastLayer = 1 << 2;
  int simulationLayers = ~0;
  int simulationMode = 0;
  bool queriesStartInColliders = true;
  bool queriesHitTriggers = true;
  bool reuseCollisionCallbacks = true;
  bool useSubStepping = false;
  bool useSubStepContacts = false;

  // --- Layer collision matrix (32×32) ---
  final List<int> layerCollisionMask = List.filled(32, ~0);

  // --- Handle storage ---
  int _nextHandle = 1;
  final Map<int, PhysicsBody> bodies = {};
  final Map<int, PhysicsCollider> colliders = {};
  final Map<int, PhysicsJoint> joints = {};
  final Map<int, PhysicsEffector> effectors = {};

  // --- Collision ignore pairs ---
  final Set<(int, int)> ignoredColliderPairs = {};

  // --- Active contacts from last step ---
  final List<NarrowphaseContact> activeContacts = [];

  // --- Contact/trigger state tracker ---
  final ContactTracker contactTracker = ContactTracker();

  int allocHandle() => _nextHandle++;

  // ===================== Body CRUD =====================

  int createBody() {
    final h = allocHandle();
    bodies[h] = PhysicsBody(h);
    return h;
  }

  void destroyBody(int handle) {
    final body = bodies.remove(handle);
    if (body != null) {
      for (final ch in body.colliderHandles) {
        colliders.remove(ch);
      }
    }
  }

  PhysicsBody getBody(int handle) => bodies[handle]!;

  // ===================== Collider CRUD =====================

  int createCollider(ColliderShapeType type, int bodyHandle) {
    final h = allocHandle();
    colliders[h] = PhysicsCollider(h, type, bodyHandle);
    bodies[bodyHandle]?.colliderHandles.add(h);
    return h;
  }

  void destroyCollider(int handle) {
    final c = colliders.remove(handle);
    if (c != null) {
      bodies[c.bodyHandle]?.colliderHandles.remove(handle);
    }
  }

  PhysicsCollider getCollider(int handle) => colliders[handle]!;

  // ===================== Joint CRUD =====================

  int createJoint(int type, int bodyHandleA) {
    final h = allocHandle();
    joints[h] = PhysicsJoint(h, type, bodyHandleA);
    return h;
  }

  void destroyJoint(int handle) => joints.remove(handle);
  PhysicsJoint getJoint(int handle) => joints[handle]!;

  // ===================== Effector CRUD =====================

  int createEffector(int type) {
    final h = allocHandle();
    effectors[h] = PhysicsEffector(h, type);
    return h;
  }

  void destroyEffector(int handle) => effectors.remove(handle);
  PhysicsEffector getEffector(int handle) => effectors[handle]!;

  // ===================== Delegated Operations =====================

  /// Steps the physics simulation. See [engineStep].
  bool step(double dt, {int layers = -1}) => engineStep(this, dt, layers);

  /// Queries delegated to [EngineQueries].
  List<RaycastHitData> raycast(Vector2 origin, Vector2 direction,
          double distance, int layerMask, double minDepth, double maxDepth) =>
      EngineQueries.raycast(this, origin, direction, distance, layerMask,
          minDepth, maxDepth);

  List<RaycastHitData> linecast(Vector2 start, Vector2 end, int layerMask,
          double minDepth, double maxDepth) =>
      EngineQueries.linecast(this, start, end, layerMask, minDepth, maxDepth);

  List<int> overlapCircle(Vector2 point, double radius, int layerMask,
          double minDepth, double maxDepth) =>
      EngineQueries.overlapCircle(
          this, point, radius, layerMask, minDepth, maxDepth);

  List<int> overlapBox(Vector2 point, Vector2 size, double angle, int layerMask,
          double minDepth, double maxDepth) =>
      EngineQueries.overlapBox(
          this, point, size, angle, layerMask, minDepth, maxDepth);

  List<int> overlapPoint(
          Vector2 point, int layerMask, double minDepth, double maxDepth) =>
      EngineQueries.overlapPoint(this, point, layerMask, minDepth, maxDepth);

  Vector2 closestPoint(Vector2 position, int colliderHandle) =>
      EngineQueries.closestPoint(this, position, colliderHandle);

  double distanceBetween(int colliderA, int colliderB) =>
      EngineQueries.distanceBetween(this, colliderA, colliderB);

  bool isTouching(int colliderA, int colliderB) =>
      EngineQueries.isTouching(this, colliderA, colliderB);

  bool isTouchingLayers(int colliderHandle, int layerMask) =>
      EngineQueries.isTouchingLayers(this, colliderHandle, layerMask);

  List<RaycastHitData> boxCast(Vector2 origin, Vector2 size, double angle,
          Vector2 direction, double distance, int layerMask,
          double minDepth, double maxDepth) =>
      EngineQueries.boxCast(this, origin, size, angle, direction, distance,
          layerMask, minDepth, maxDepth);

  List<RaycastHitData> circleCast(Vector2 origin, double radius,
          Vector2 direction, double distance, int layerMask,
          double minDepth, double maxDepth) =>
      EngineQueries.circleCast(this, origin, radius, direction, distance,
          layerMask, minDepth, maxDepth);

  List<RaycastHitData> capsuleCast(Vector2 origin, Vector2 size,
          int capsuleDirection, double angle, Vector2 direction,
          double distance, int layerMask, double minDepth, double maxDepth) =>
      EngineQueries.capsuleCast(this, origin, size, capsuleDirection, angle,
          direction, distance, layerMask, minDepth, maxDepth);

  List<ContactPointData> getContacts(int colliderHandle) =>
      EngineQueries.getContacts(this, colliderHandle);

  List<int> getContactColliders(int colliderHandle) =>
      EngineQueries.getContactColliders(this, colliderHandle);

  List<int> overlapCollider(int colliderHandle) =>
      EngineQueries.overlapCollider(this, colliderHandle);

  void syncTransforms() {
    // TODO: Sync transform changes from GameObjects to physics bodies
  }
}
