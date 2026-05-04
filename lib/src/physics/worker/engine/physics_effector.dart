/// Internal effector representation matching Unity's Effector2D state.
class PhysicsEffector {
  final int handle;
  final int effectorType;
  int colliderMask = ~0;
  bool useColliderMask = false;

  // Area
  double forceAngle = 0.0;
  double forceMagnitude = 0.0;
  double forceVariation = 0.0;
  double drag = 0.0;
  double angularDrag = 0.0;
  int forceTarget = 0;
  bool useGlobalAngle = false;
  int areaForceMode = 2;

  // Buoyancy
  double surfaceLevel = 0.0;
  double buoyancyDensity = 1.0;
  double flowAngle = 0.0;
  double flowMagnitude = 0.0;
  double flowVariation = 0.0;
  double linearDrag = 1.0;
  double angularDragBuoyancy = 1.0;

  // Platform
  bool useOneWay = true;
  bool useOneWayGrouping = false;
  bool useSideFriction = true;
  bool useSideBounce = true;
  double surfaceArc = 180.0;
  double sideArc = 0.0;
  int rotationalOffset = 0;

  // Point
  double pointForceMagnitude = 0.0;
  double pointForceVariation = 0.0;
  double distanceScale = 1.0;
  double pointDrag = 0.0;
  double pointAngularDrag = 0.0;
  int pointForceSource = 0;
  int pointForceTarget = 0;
  int pointForceMode = 2;

  // Surface
  double speed = 0.0;
  double speedVariation = 0.0;
  double forceScale = 0.0;
  bool useContactForce = false;
  bool useFriction = false;
  bool useBounce = false;

  PhysicsEffector(this.handle, this.effectorType);
}
