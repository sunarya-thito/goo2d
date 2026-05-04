import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/src/physics/worker/engine/physics_engine.dart';

/// Joint property indices.
class JointProp {
  static const int breakForce = 0;
  static const int breakTorque = 1;
  static const int breakAction = 2;
  static const int enableCollision = 3;
  static const int anchor = 4;
  static const int connectedAnchor = 5;
  static const int autoConfigureConnectedAnchor = 6;
  static const int bodyHandleB = 7;
  static const int distance = 8;
  static const int autoConfigureDistance = 9;
  static const int maxDistanceOnly = 10;
  static const int springFrequency = 11;
  static const int springDampingRatio = 12;
  static const int maxForce = 13;
  static const int maxTorque = 14;
  static const int useLimits = 15;
  static const int lowerAngle = 16;
  static const int upperAngle = 17;
  static const int useMotor = 18;
  static const int motorSpeed = 19;
  static const int maxMotorTorque = 20;
  static const int lowerTranslation = 21;
  static const int upperTranslation = 22;
  static const int useTranslationLimits = 23;
  static const int sliderAngle = 24;
  static const int autoConfigureAngle = 25;
  static const int linearOffset = 26;
  static const int angularOffset = 27;
  static const int correctionScale = 28;
  static const int autoConfigureOffset = 29;
  static const int target = 30;
  static const int targetMaxForce = 31;
  static const int wheelSuspensionAngle = 32;
}

/// Direct joint operations. `object → invocation`.
class DirectJointOps {
  DirectJointOps._();

  static Future<int> create(PhysicsEngine e, int t, int bh) => Future.value(e.createJoint(t, bh));
  static Future<void> destroy(PhysicsEngine e, int h) { e.destroyJoint(h); return Future.value(); }

  static Future<Object?> getProperty(PhysicsEngine e, int h, int p) {
    final j = e.getJoint(h);
    return Future.value(switch (p) {
      JointProp.breakForce => j.breakForce,
      JointProp.breakTorque => j.breakTorque,
      JointProp.breakAction => j.breakAction,
      JointProp.enableCollision => j.enableCollision,
      JointProp.anchor => j.anchor,
      JointProp.connectedAnchor => j.connectedAnchor,
      JointProp.autoConfigureConnectedAnchor => j.autoConfigureConnectedAnchor,
      JointProp.bodyHandleB => j.bodyHandleB,
      JointProp.distance => j.distance,
      JointProp.autoConfigureDistance => j.autoConfigureDistance,
      JointProp.maxDistanceOnly => j.maxDistanceOnly,
      JointProp.springFrequency => j.springFrequency,
      JointProp.springDampingRatio => j.springDampingRatio,
      JointProp.maxForce => j.maxForce,
      JointProp.maxTorque => j.maxTorque,
      JointProp.useLimits => j.useLimits,
      JointProp.lowerAngle => j.lowerAngle,
      JointProp.upperAngle => j.upperAngle,
      JointProp.useMotor => j.useMotor,
      JointProp.motorSpeed => j.motorSpeed,
      JointProp.maxMotorTorque => j.maxMotorTorque,
      JointProp.lowerTranslation => j.lowerTranslation,
      JointProp.upperTranslation => j.upperTranslation,
      JointProp.useTranslationLimits => j.useTranslationLimits,
      JointProp.sliderAngle => j.sliderAngle,
      JointProp.autoConfigureAngle => j.autoConfigureAngle,
      JointProp.linearOffset => j.linearOffset,
      JointProp.angularOffset => j.angularOffset,
      JointProp.correctionScale => j.correctionScale,
      JointProp.autoConfigureOffset => j.autoConfigureOffset,
      JointProp.target => j.target,
      JointProp.targetMaxForce => j.targetMaxForce,
      JointProp.wheelSuspensionAngle => j.wheelSuspensionAngle,
      _ => throw ArgumentError('Unknown joint property: $p'),
    });
  }

  static Future<void> setProperty(PhysicsEngine e, int h, int p, Object? v) {
    final j = e.getJoint(h);
    switch (p) {
      case JointProp.breakForce: j.breakForce = v as double;
      case JointProp.breakTorque: j.breakTorque = v as double;
      case JointProp.breakAction: j.breakAction = v as int;
      case JointProp.enableCollision: j.enableCollision = v as bool;
      case JointProp.anchor: j.anchor.setFrom(v as Vector2);
      case JointProp.connectedAnchor: j.connectedAnchor.setFrom(v as Vector2);
      case JointProp.autoConfigureConnectedAnchor: j.autoConfigureConnectedAnchor = v as bool;
      case JointProp.bodyHandleB: j.bodyHandleB = v as int;
      case JointProp.distance: j.distance = v as double;
      case JointProp.autoConfigureDistance: j.autoConfigureDistance = v as bool;
      case JointProp.maxDistanceOnly: j.maxDistanceOnly = v as double;
      case JointProp.springFrequency: j.springFrequency = v as double;
      case JointProp.springDampingRatio: j.springDampingRatio = v as double;
      case JointProp.maxForce: j.maxForce = v as double;
      case JointProp.maxTorque: j.maxTorque = v as double;
      case JointProp.useLimits: j.useLimits = v as bool;
      case JointProp.lowerAngle: j.lowerAngle = v as double;
      case JointProp.upperAngle: j.upperAngle = v as double;
      case JointProp.useMotor: j.useMotor = v as bool;
      case JointProp.motorSpeed: j.motorSpeed = v as double;
      case JointProp.maxMotorTorque: j.maxMotorTorque = v as double;
      case JointProp.lowerTranslation: j.lowerTranslation = v as double;
      case JointProp.upperTranslation: j.upperTranslation = v as double;
      case JointProp.useTranslationLimits: j.useTranslationLimits = v as bool;
      case JointProp.sliderAngle: j.sliderAngle = v as double;
      case JointProp.autoConfigureAngle: j.autoConfigureAngle = v as bool;
      case JointProp.linearOffset: j.linearOffset.setFrom(v as Vector2);
      case JointProp.angularOffset: j.angularOffset = v as double;
      case JointProp.correctionScale: j.correctionScale = v as double;
      case JointProp.autoConfigureOffset: j.autoConfigureOffset = v as bool;
      case JointProp.target: j.target.setFrom(v as Vector2);
      case JointProp.targetMaxForce: j.targetMaxForce = v as double;
      case JointProp.wheelSuspensionAngle: j.wheelSuspensionAngle = v as double;
      default: throw ArgumentError('Unknown joint property: $p');
    }
    return Future.value();
  }
}
