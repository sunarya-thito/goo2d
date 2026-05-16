import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/src/physics/worker/engine/physics_engine.dart';

/// Direct global settings operations. `object → invocation`.
class DirectGlobalOps {
  DirectGlobalOps._();

  static Future<void> setGravity(PhysicsEngine e, Vector2 v) { e.gravity = v; return Future.value(); }
  static Future<Vector2> getGravity(PhysicsEngine e) => Future.value(e.gravity);
  static Future<void> setCallbacksOnDisable(PhysicsEngine e, bool v) { e.callbacksOnDisable = v; return Future.value(); }
  static Future<bool> getCallbacksOnDisable(PhysicsEngine e) => Future.value(e.callbacksOnDisable);
  static Future<void> setBounceThreshold(PhysicsEngine e, double v) { e.bounceThreshold = v; return Future.value(); }
  static Future<double> getBounceThreshold(PhysicsEngine e) => Future.value(e.bounceThreshold);
  static Future<void> setContactThreshold(PhysicsEngine e, double v) { e.contactThreshold = v; return Future.value(); }
  static Future<double> getContactThreshold(PhysicsEngine e) => Future.value(e.contactThreshold);
  static Future<void> setBaumgarteTOIScale(PhysicsEngine e, double v) { e.baumgarteTOIScale = v; return Future.value(); }
  static Future<double> getBaumgarteTOIScale(PhysicsEngine e) => Future.value(e.baumgarteTOIScale);
  static Future<void> setBaumgarteScale(PhysicsEngine e, double v) { e.baumgarteScale = v; return Future.value(); }
  static Future<double> getBaumgarteScale(PhysicsEngine e) => Future.value(e.baumgarteScale);
  static Future<void> setAngularSleepTolerance(PhysicsEngine e, double v) { e.angularSleepTolerance = v; return Future.value(); }
  static Future<double> getAngularSleepTolerance(PhysicsEngine e) => Future.value(e.angularSleepTolerance);
  static Future<void> setLinearSleepTolerance(PhysicsEngine e, double v) { e.linearSleepTolerance = v; return Future.value(); }
  static Future<double> getLinearSleepTolerance(PhysicsEngine e) => Future.value(e.linearSleepTolerance);
  static Future<void> setDefaultContactOffset(PhysicsEngine e, double v) { e.defaultContactOffset = v; return Future.value(); }
  static Future<double> getDefaultContactOffset(PhysicsEngine e) => Future.value(e.defaultContactOffset);
  static Future<void> setMaxAngularCorrection(PhysicsEngine e, double v) { e.maxAngularCorrection = v; return Future.value(); }
  static Future<double> getMaxAngularCorrection(PhysicsEngine e) => Future.value(e.maxAngularCorrection);
  static Future<void> setMaxLinearCorrection(PhysicsEngine e, double v) { e.maxLinearCorrection = v; return Future.value(); }
  static Future<double> getMaxLinearCorrection(PhysicsEngine e) => Future.value(e.maxLinearCorrection);
  static Future<void> setMaxRotationSpeed(PhysicsEngine e, double v) { e.maxRotationSpeed = v; return Future.value(); }
  static Future<double> getMaxRotationSpeed(PhysicsEngine e) => Future.value(e.maxRotationSpeed);
  static Future<void> setMaxTranslationSpeed(PhysicsEngine e, double v) { e.maxTranslationSpeed = v; return Future.value(); }
  static Future<double> getMaxTranslationSpeed(PhysicsEngine e) => Future.value(e.maxTranslationSpeed);
  static Future<void> setMinSubStepFPS(PhysicsEngine e, double v) { e.minSubStepFPS = v; return Future.value(); }
  static Future<double> getMinSubStepFPS(PhysicsEngine e) => Future.value(e.minSubStepFPS);
  static Future<void> setTimeToSleep(PhysicsEngine e, double v) { e.timeToSleep = v; return Future.value(); }
  static Future<double> getTimeToSleep(PhysicsEngine e) => Future.value(e.timeToSleep);
  static Future<void> setPositionIterations(PhysicsEngine e, int v) { e.positionIterations = v; return Future.value(); }
  static Future<int> getPositionIterations(PhysicsEngine e) => Future.value(e.positionIterations);
  static Future<void> setVelocityIterations(PhysicsEngine e, int v) { e.velocityIterations = v; return Future.value(); }
  static Future<int> getVelocityIterations(PhysicsEngine e) => Future.value(e.velocityIterations);
  static Future<void> setMaxSubStepCount(PhysicsEngine e, int v) { e.maxSubStepCount = v; return Future.value(); }
  static Future<int> getMaxSubStepCount(PhysicsEngine e) => Future.value(e.maxSubStepCount);
  static Future<int> getMaxPolygonShapeVertices(PhysicsEngine e) => Future.value(e.maxPolygonShapeVertices);
  static Future<int> getAllLayers(PhysicsEngine e) => Future.value(e.allLayers);
  static Future<int> getDefaultRaycastLayers(PhysicsEngine e) => Future.value(e.defaultRaycastLayers);
  static Future<int> getIgnoreRaycastLayer(PhysicsEngine e) => Future.value(e.ignoreRaycastLayer);
  static Future<void> setSimulationLayers(PhysicsEngine e, int v) { e.simulationLayers = v; return Future.value(); }
  static Future<int> getSimulationLayers(PhysicsEngine e) => Future.value(e.simulationLayers);
  static Future<void> setSimulationMode(PhysicsEngine e, int v) { e.simulationMode = v; return Future.value(); }
  static Future<int> getSimulationMode(PhysicsEngine e) => Future.value(e.simulationMode);
  static Future<void> setQueriesStartInColliders(PhysicsEngine e, bool v) { e.queriesStartInColliders = v; return Future.value(); }
  static Future<bool> getQueriesStartInColliders(PhysicsEngine e) => Future.value(e.queriesStartInColliders);
  static Future<void> setQueriesHitTriggers(PhysicsEngine e, bool v) { e.queriesHitTriggers = v; return Future.value(); }
  static Future<bool> getQueriesHitTriggers(PhysicsEngine e) => Future.value(e.queriesHitTriggers);
  static Future<void> setReuseCollisionCallbacks(PhysicsEngine e, bool v) { e.reuseCollisionCallbacks = v; return Future.value(); }
  static Future<bool> getReuseCollisionCallbacks(PhysicsEngine e) => Future.value(e.reuseCollisionCallbacks);
  static Future<void> setUseSubStepping(PhysicsEngine e, bool v) { e.useSubStepping = v; return Future.value(); }
  static Future<bool> getUseSubStepping(PhysicsEngine e) => Future.value(e.useSubStepping);
  static Future<void> setUseSubStepContacts(PhysicsEngine e, bool v) { e.useSubStepContacts = v; return Future.value(); }
  static Future<bool> getUseSubStepContacts(PhysicsEngine e) => Future.value(e.useSubStepContacts);

  // Layer collision
  static Future<bool> getIgnoreLayerCollision(PhysicsEngine e, int l1, int l2) =>
      Future.value((e.layerCollisionMask[l1] & (1 << l2)) == 0);
  static Future<void> setIgnoreLayerCollision(PhysicsEngine e, int l1, int l2, bool ignore) {
    if (ignore) {
      e.layerCollisionMask[l1] &= ~(1 << l2);
      e.layerCollisionMask[l2] &= ~(1 << l1);
    } else {
      e.layerCollisionMask[l1] |= (1 << l2);
      e.layerCollisionMask[l2] |= (1 << l1);
    }
    return Future.value();
  }
  static Future<int> getLayerCollisionMask(PhysicsEngine e, int l) => Future.value(e.layerCollisionMask[l]);
  static Future<void> setLayerCollisionMask(PhysicsEngine e, int l, int m) { e.layerCollisionMask[l] = m; return Future.value(); }
  static Future<void> ignoreCollision(PhysicsEngine e, int a, int b, bool v) {
    final pair = a < b ? (a, b) : (b, a);
    v ? e.ignoredColliderPairs.add(pair) : e.ignoredColliderPairs.remove(pair);
    return Future.value();
  }
  static Future<bool> getIgnoreCollision(PhysicsEngine e, int a, int b) {
    final pair = a < b ? (a, b) : (b, a);
    return Future.value(e.ignoredColliderPairs.contains(pair));
  }
}
