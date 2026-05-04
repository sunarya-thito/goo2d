import 'package:vector_math/vector_math_64.dart';

/// Internal joint representation matching Unity's Joint2D state.
class PhysicsJoint {
  final int handle;
  final int jointType;
  int bodyHandleA;
  int bodyHandleB = -1;

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

  PhysicsJoint(this.handle, this.jointType, this.bodyHandleA);
}
