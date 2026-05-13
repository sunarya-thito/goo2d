import 'package:meta/meta.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/src/physics/components/joint.dart';
import 'package:goo2d/src/physics/worker/direct/direct_joint_ops.dart';
import 'package:goo2d/src/physics/worker/data/joint_type.dart';
import 'package:goo2d/goo2d.dart';

/// Joint that allows a Rigidbody2D object to rotate around a point in space or a point on another object.
///
/// Equivalent to Unity's `HingeJoint2D`.
class HingeJoint extends Joint {
  @override
  int get jointType => JointType.hinge;

  @override
  @protected
  void syncAllProperties() {
    super.syncAllProperties();
    worker.setJointProperty(handle, JointProp.anchor, _anchor.clone());
    worker.setJointProperty(handle, JointProp.connectedAnchor, _connectedAnchor.clone());
    worker.setJointProperty(handle, JointProp.autoConfigureConnectedAnchor, _autoConfigureConnectedAnchor);
    worker.setJointProperty(handle, JointProp.useLimits, _useLimits);
    worker.setJointProperty(handle, JointProp.lowerAngle, _lowerAngle);
    worker.setJointProperty(handle, JointProp.upperAngle, _upperAngle);
    worker.setJointProperty(handle, JointProp.useMotor, _useMotor);
    worker.setJointProperty(handle, JointProp.motorSpeed, _motorSpeed);
    worker.setJointProperty(handle, JointProp.maxMotorTorque, _maxMotorTorque);
    worker.setJointProperty(handle, JointProp.angularOffset, _referenceAngle);
  }

  final Vector2 _anchor = Vector2.zero();
  Vector2 get anchor => _anchor;
  set anchor(Vector2 value) {
    _anchor.setFrom(value);
    if (isAttached) worker.setJointProperty(handle, JointProp.anchor, value.clone());
  }

  final Vector2 _connectedAnchor = Vector2.zero();
  Vector2 get connectedAnchor => _connectedAnchor;
  set connectedAnchor(Vector2 value) {
    _connectedAnchor.setFrom(value);
    if (isAttached) worker.setJointProperty(handle, JointProp.connectedAnchor, value.clone());
  }

  bool _autoConfigureConnectedAnchor = true;
  bool get autoConfigureConnectedAnchor => _autoConfigureConnectedAnchor;
  set autoConfigureConnectedAnchor(bool value) {
    _autoConfigureConnectedAnchor = value;
    if (isAttached) worker.setJointProperty(handle, JointProp.autoConfigureConnectedAnchor, value);
  }

  bool useConnectedAnchor = true;

  bool _useLimits = false;
  bool get useLimits => _useLimits;
  set useLimits(bool value) {
    _useLimits = value;
    if (isAttached) worker.setJointProperty(handle, JointProp.useLimits, value);
  }

  double _lowerAngle = 0.0;
  double _upperAngle = 360.0;

  JointAngleLimits get limits => JointAngleLimits(min: _lowerAngle, max: _upperAngle);
  set limits(JointAngleLimits value) {
    _lowerAngle = value.min;
    _upperAngle = value.max;
    if (isAttached) {
      worker.setJointProperty(handle, JointProp.lowerAngle, value.min);
      worker.setJointProperty(handle, JointProp.upperAngle, value.max);
    }
  }

  bool _useMotor = false;
  bool get useMotor => _useMotor;
  set useMotor(bool value) {
    _useMotor = value;
    if (isAttached) worker.setJointProperty(handle, JointProp.useMotor, value);
  }

  double _motorSpeed = 0.0;
  double _maxMotorTorque = 10000.0;

  JointMotor get motor => JointMotor(motorSpeed: _motorSpeed, maxMotorTorque: _maxMotorTorque);
  set motor(JointMotor value) {
    _motorSpeed = value.motorSpeed;
    _maxMotorTorque = value.maxMotorTorque;
    if (isAttached) {
      worker.setJointProperty(handle, JointProp.motorSpeed, value.motorSpeed);
      worker.setJointProperty(handle, JointProp.maxMotorTorque, value.maxMotorTorque);
    }
  }

  double _referenceAngle = 0.0;
  double get referenceAngle => _referenceAngle;
  set referenceAngle(double value) {
    _referenceAngle = value;
    if (isAttached) worker.setJointProperty(handle, JointProp.angularOffset, value);
  }

  JointLimitState get limitState => JointLimitState.inactive;

  Future<double> getMotorTorque(double timeStep) async =>
      (await worker.getJointProperty(handle, JointProp.reactionTorque)) as double;

  Future<double> get jointSpeed async =>
      (await worker.getJointProperty(handle, JointProp.motorSpeed)) as double;

  Future<double> get jointAngle async =>
      (await worker.getJointProperty(handle, JointProp.lowerAngle)) as double;
}
