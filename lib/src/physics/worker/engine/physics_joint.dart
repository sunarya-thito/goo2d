import 'package:forge2d/forge2d.dart' as f;
import 'package:vector_math/vector_math_64.dart';

/// Internal joint representation matching Unity's Joint2D state.
/// The [_joint] field holds the Forge2D joint, created lazily before the first
/// physics step once both bodies are available.
class PhysicsJoint {
  final int handle;
  final int jointType;
  int bodyHandleA;
  int bodyHandleB = -1;

  // Forge2D joint — null until _ensureJointCreated() runs in PhysicsEngine.step()
  f.Joint? _joint;

  // Common
  double breakForce = double.infinity;
  double breakTorque = double.infinity;
  int breakAction = 0;
  bool enableCollision = false;

  // Anchors
  Vector2 anchor = Vector2.zero();
  Vector2 connectedAnchor = Vector2.zero();
  bool autoConfigureConnectedAnchor = true;

  // Distance
  double distance = 1.0;
  bool autoConfigureDistance = true;
  double maxDistanceOnly = 0.0;

  // Spring
  double springFrequency = 1.0;
  double springDampingRatio = 0.0;

  // Friction
  double maxForce = 0.0;
  double maxTorque = 0.0;

  // Hinge
  bool useLimits = false;
  double lowerAngle = 0.0;
  double upperAngle = 360.0;
  bool useMotor = false;
  double motorSpeed = 0.0;
  double maxMotorTorque = 10000.0;

  // Slider
  double lowerTranslation = 0.0;
  double upperTranslation = 1.0;
  bool useTranslationLimits = false;
  double sliderAngle = 0.0;
  bool autoConfigureAngle = true;

  // Relative
  Vector2 linearOffset = Vector2.zero();
  double angularOffset = 0.0;
  double correctionScale = 0.3;
  bool autoConfigureOffset = true;

  // Target
  Vector2 target = Vector2.zero();
  double targetMaxForce = 0.0;

  // Wheel
  double wheelSuspensionAngle = 90.0;

  // Reaction (read from Forge2D joint; invDt=50 for 50 Hz fixed step)
  Vector2 get reactionForce {
    final j = _joint;
    if (j == null) return Vector2.zero();
    final rf = j.reactionForce(50.0);
    return Vector2(rf.x, rf.y);
  }

  double get reactionTorque {
    final j = _joint;
    if (j == null) return 0.0;
    return j.reactionTorque(50.0);
  }

  PhysicsJoint(this.handle, this.jointType, this.bodyHandleA);

  void initForgeJoint(f.Joint? joint) => _joint = joint;
  f.Joint? get forgeJoint => _joint;
}
