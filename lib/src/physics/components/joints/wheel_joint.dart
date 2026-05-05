import 'package:meta/meta.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/src/physics/components/joint.dart';
import 'package:goo2d/src/physics/worker/direct/direct_joint_ops.dart';
import 'package:goo2d/src/physics/worker/data/joint_type.dart';
import 'package:goo2d/goo2d.dart';

/// Joint that simulates a wheel by allowing rotation and applying a spring-force along a single line.
///
/// Equivalent to Unity's `WheelJoint2D`.
class WheelJoint extends Joint {
  @override
  int get jointType => JointType.wheel;

  @override
  @protected
  void syncProperties() {
    super.syncProperties();
    handle.then((h) {
      worker.setJointProperty(h, JointProp.anchor, _anchor);
      worker.setJointProperty(h, JointProp.connectedAnchor, _connectedAnchor);
      worker.setJointProperty(h, JointProp.autoConfigureConnectedAnchor, _autoConfigureConnectedAnchor);
      worker.setJointProperty(h, JointProp.useMotor, _useMotor);
      worker.setJointProperty(h, JointProp.motorSpeed, _motorSpeed);
      worker.setJointProperty(h, JointProp.maxMotorTorque, _maxMotorTorque);
      worker.setJointProperty(h, JointProp.springDampingRatio, _dampingRatio);
      worker.setJointProperty(h, JointProp.springFrequency, _frequency);
      worker.setJointProperty(h, JointProp.wheelSuspensionAngle, _suspensionAngle);
    });
  }

  final Vector2 _anchor = Vector2.zero();
  Vector2 get anchor => _anchor;
  set anchor(Vector2 value) {
    _anchor.setFrom(value);
    handle.then((h) => worker.setJointProperty(h, JointProp.anchor, value));
  }

  final Vector2 _connectedAnchor = Vector2.zero();
  Vector2 get connectedAnchor => _connectedAnchor;
  set connectedAnchor(Vector2 value) {
    _connectedAnchor.setFrom(value);
    handle.then((h) => worker.setJointProperty(h, JointProp.connectedAnchor, value));
  }

  bool _autoConfigureConnectedAnchor = true;
  bool get autoConfigureConnectedAnchor => _autoConfigureConnectedAnchor;
  set autoConfigureConnectedAnchor(bool value) {
    _autoConfigureConnectedAnchor = value;
    handle.then((h) => worker.setJointProperty(h, JointProp.autoConfigureConnectedAnchor, value));
  }

  bool _useMotor = false;
  bool get useMotor => _useMotor;
  set useMotor(bool value) {
    _useMotor = value;
    handle.then((h) => worker.setJointProperty(h, JointProp.useMotor, value));
  }

  double _motorSpeed = 0.0;
  double _maxMotorTorque = 10000.0;

  /// The motor parameters wrapping motorSpeed/maxMotorTorque.
  JointMotor get motor => JointMotor(motorSpeed: _motorSpeed, maxMotorTorque: _maxMotorTorque);
  set motor(JointMotor value) {
    _motorSpeed = value.motorSpeed;
    _maxMotorTorque = value.maxMotorTorque;
    handle.then((h) {
      worker.setJointProperty(h, JointProp.motorSpeed, value.motorSpeed);
      worker.setJointProperty(h, JointProp.maxMotorTorque, value.maxMotorTorque);
    });
  }

  double _dampingRatio = 0.7;
  double _frequency = 2.0;
  double _suspensionAngle = 90.0;

  /// The suspension parameters wrapping dampingRatio/frequency/suspensionAngle.
  JointSuspension get suspension => JointSuspension(frequency: _frequency, angle: _suspensionAngle, dampingRatio: _dampingRatio);
  set suspension(JointSuspension value) {
    _dampingRatio = value.dampingRatio;
    _frequency = value.frequency;
    _suspensionAngle = value.angle;
    handle.then((h) {
      worker.setJointProperty(h, JointProp.springDampingRatio, value.dampingRatio);
      worker.setJointProperty(h, JointProp.springFrequency, value.frequency);
      worker.setJointProperty(h, JointProp.wheelSuspensionAngle, value.angle);
    });
  }

  Future<double> get jointSpeed async =>
      (await worker.getJointProperty(await handle, JointProp.motorSpeed)) as double;

  Future<double> get jointTranslation async =>
      (await worker.getJointProperty(await handle, JointProp.lowerTranslation)) as double;

  Future<double> get jointAngle async => 0.0;

  Future<double> get jointLinearSpeed async => 0.0;

  Future<double> getMotorTorque(double timeStep) async =>
      (await worker.getJointProperty(await handle, JointProp.reactionTorque)) as double;
}
