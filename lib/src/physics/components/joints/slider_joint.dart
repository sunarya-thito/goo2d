import 'package:meta/meta.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/src/physics/worker/direct/direct_joint_ops.dart';
import 'package:goo2d/src/physics/worker/data/joint_type.dart';
import 'package:goo2d/goo2d.dart';

/// Joint that restricts the motion of a Rigidbody2D object to a single line.
///
/// Equivalent to Unity's `SliderJoint2D`.
class SliderJoint extends Joint {
  @override
  int get jointType => JointType.slider;

  @override
  @protected
  void syncAllProperties() {
    super.syncAllProperties();
    worker.setJointProperty(handle, JointProp.anchor, _anchor.clone());
    worker.setJointProperty(handle, JointProp.connectedAnchor, _connectedAnchor.clone());
    worker.setJointProperty(handle, JointProp.autoConfigureConnectedAnchor, _autoConfigureConnectedAnchor);
    worker.setJointProperty(handle, JointProp.useTranslationLimits, _useLimits);
    worker.setJointProperty(handle, JointProp.useMotor, _useMotor);
    worker.setJointProperty(handle, JointProp.sliderAngle, _angle);
    worker.setJointProperty(handle, JointProp.autoConfigureAngle, _autoConfigureAngle);
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

  bool _useMotor = false;
  bool get useMotor => _useMotor;
  set useMotor(bool value) {
    _useMotor = value;
    if (isAttached) worker.setJointProperty(handle, JointProp.useMotor, value);
  }

  double _angle = 0.0;
  double get angle => _angle;
  set angle(double value) {
    _angle = value;
    if (isAttached) worker.setJointProperty(handle, JointProp.sliderAngle, value);
  }

  bool _useLimits = false;
  bool get useLimits => _useLimits;
  set useLimits(bool value) {
    _useLimits = value;
    if (isAttached) worker.setJointProperty(handle, JointProp.useTranslationLimits, value);
  }

  bool _autoConfigureAngle = true;
  bool get autoConfigureAngle => _autoConfigureAngle;
  set autoConfigureAngle(bool value) {
    _autoConfigureAngle = value;
    if (isAttached) worker.setJointProperty(handle, JointProp.autoConfigureAngle, value);
  }

  double _motorSpeed = 0.0;
  double _maxMotorTorque = 10000.0;
  double _lowerTranslation = 0.0;
  double _upperTranslation = 0.0;

  JointMotor get motor => JointMotor(motorSpeed: _motorSpeed, maxMotorTorque: _maxMotorTorque);
  set motor(JointMotor value) {
    _motorSpeed = value.motorSpeed;
    _maxMotorTorque = value.maxMotorTorque;
    if (isAttached) {
      worker.setJointProperty(handle, JointProp.motorSpeed, value.motorSpeed);
      worker.setJointProperty(handle, JointProp.maxMotorTorque, value.maxMotorTorque);
    }
  }

  JointTranslationLimits get limits => JointTranslationLimits(min: _lowerTranslation, max: _upperTranslation);
  set limits(JointTranslationLimits value) {
    _lowerTranslation = value.min;
    _upperTranslation = value.max;
    if (isAttached) {
      worker.setJointProperty(handle, JointProp.lowerTranslation, value.min);
      worker.setJointProperty(handle, JointProp.upperTranslation, value.max);
    }
  }

  JointLimitState get limitState => JointLimitState.inactive;

  Future<double> get jointTranslation async =>
      (await worker.getJointProperty(handle, JointProp.lowerTranslation)) as double;

  Future<double> get jointSpeed async =>
      (await worker.getJointProperty(handle, JointProp.motorSpeed)) as double;

  double get referenceAngle => _angle;

  Future<double> getMotorForce(double timeStep) async {
    final raw = (await worker.getJointProperty(handle, JointProp.reactionForce)) as Vector2;
    return timeStep > 0 ? raw.length / timeStep : 0.0;
  }
}
