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
  void syncProperties() {
    super.syncProperties();
    handle.then((h) {
      worker.setJointProperty(h, JointProp.anchor, _anchor);
      worker.setJointProperty(h, JointProp.connectedAnchor, _connectedAnchor);
      worker.setJointProperty(h, JointProp.autoConfigureConnectedAnchor, _autoConfigureConnectedAnchor);
      worker.setJointProperty(h, JointProp.useLimits, _useLimits);
      worker.setJointProperty(h, JointProp.lowerAngle, _lowerAngle);
      worker.setJointProperty(h, JointProp.upperAngle, _upperAngle);
      worker.setJointProperty(h, JointProp.useMotor, _useMotor);
      worker.setJointProperty(h, JointProp.motorSpeed, _motorSpeed);
      worker.setJointProperty(h, JointProp.maxMotorTorque, _maxMotorTorque);
      worker.setJointProperty(h, JointProp.angularOffset, _referenceAngle);
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

  /// Whether a connected anchor is used.
  bool useConnectedAnchor = true;

  bool _useLimits = false;
  bool get useLimits => _useLimits;
  set useLimits(bool value) {
    _useLimits = value;
    handle.then((h) => worker.setJointProperty(h, JointProp.useLimits, value));
  }

  double _lowerAngle = 0.0;
  double _upperAngle = 360.0;

  /// The angle limits on rotation, wrapping lowerAngle/upperAngle.
  JointAngleLimits get limits => JointAngleLimits(min: _lowerAngle, max: _upperAngle);
  set limits(JointAngleLimits value) {
    _lowerAngle = value.min;
    _upperAngle = value.max;
    handle.then((h) {
      worker.setJointProperty(h, JointProp.lowerAngle, value.min);
      worker.setJointProperty(h, JointProp.upperAngle, value.max);
    });
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

  double _referenceAngle = 0.0;
  double get referenceAngle => _referenceAngle;
  set referenceAngle(double value) {
    _referenceAngle = value;
    handle.then((h) => worker.setJointProperty(h, JointProp.angularOffset, value));
  }

  /// The current limit state (read-only).
  JointLimitState get limitState => JointLimitState.inactive;

  Future<double> getMotorTorque(double timeStep) async =>
      (await worker.getJointProperty(await handle, JointProp.reactionTorque)) as double;

  Future<double> get jointSpeed async =>
      (await worker.getJointProperty(await handle, JointProp.motorSpeed)) as double;

  Future<double> get jointAngle async =>
      (await worker.getJointProperty(await handle, JointProp.lowerAngle)) as double;
}
