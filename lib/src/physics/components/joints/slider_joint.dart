import 'package:vector_math/vector_math_64.dart';
import 'package:meta/meta.dart';
import 'package:goo2d/src/physics/components/joint.dart';
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
  void syncProperties() {
    super.syncProperties();
    handleIfAttached?.then((h) {
      worker.setJointProperty(h, JointProp.anchor, _anchor);
      worker.setJointProperty(h, JointProp.connectedAnchor, _connectedAnchor);
      worker.setJointProperty(h, JointProp.autoConfigureConnectedAnchor, _autoConfigureConnectedAnchor);
      worker.setJointProperty(h, JointProp.useTranslationLimits, _useLimits);
      worker.setJointProperty(h, JointProp.useMotor, _useMotor);
      worker.setJointProperty(h, JointProp.sliderAngle, _angle);
      worker.setJointProperty(h, JointProp.autoConfigureAngle, _autoConfigureAngle);
    });
  }

  final Vector2 _anchor = Vector2.zero();
  /// The local anchor point on the Rigidbody2D where the joint is attached.
  Vector2 get anchor => _anchor;
  set anchor(Vector2 value) {
    _anchor.setFrom(value);
    handleIfAttached?.then((h) => worker.setJointProperty(h, JointProp.anchor, value));
  }

  final Vector2 _connectedAnchor = Vector2.zero();
  /// The local anchor point on the connected Rigidbody2D where the joint is attached.
  Vector2 get connectedAnchor => _connectedAnchor;
  set connectedAnchor(Vector2 value) {
    _connectedAnchor.setFrom(value);
    handleIfAttached?.then((h) => worker.setJointProperty(h, JointProp.connectedAnchor, value));
  }

  bool _autoConfigureConnectedAnchor = true;
  /// Should the connected anchor be calculated automatically?
  bool get autoConfigureConnectedAnchor => _autoConfigureConnectedAnchor;
  set autoConfigureConnectedAnchor(bool value) {
    _autoConfigureConnectedAnchor = value;
    handleIfAttached?.then((h) => worker.setJointProperty(h, JointProp.autoConfigureConnectedAnchor, value));
  }

  bool _useMotor = false;
  /// Should a motor force be applied automatically to the Rigidbody2D?
  bool get useMotor => _useMotor;
  set useMotor(bool value) {
    _useMotor = value;
    handleIfAttached?.then((h) => worker.setJointProperty(h, JointProp.useMotor, value));
  }

  double _angle = 0.0;
  /// The angle of the line in space (in degrees).
  double get angle => _angle;
  set angle(double value) {
    _angle = value;
    handleIfAttached?.then((h) => worker.setJointProperty(h, JointProp.sliderAngle, value));
  }

  bool _useLimits = false;
  /// Should motion limits be used?
  bool get useLimits => _useLimits;
  set useLimits(bool value) {
    _useLimits = value;
    handleIfAttached?.then((h) => worker.setJointProperty(h, JointProp.useTranslationLimits, value));
  }

  bool _autoConfigureAngle = true;
  /// Should the angle be calculated automatically?
  bool get autoConfigureAngle => _autoConfigureAngle;
  set autoConfigureAngle(bool value) {
    _autoConfigureAngle = value;
    handleIfAttached?.then((h) => worker.setJointProperty(h, JointProp.autoConfigureAngle, value));
  }

  double _motorSpeed = 0.0;
  double _maxMotorTorque = 10000.0;
  double _lowerTranslation = 0.0;
  double _upperTranslation = 0.0;

  /// Parameters for the motor applied along the slider axis.
  JointMotor get motor => JointMotor(motorSpeed: _motorSpeed, maxMotorTorque: _maxMotorTorque);
  set motor(JointMotor value) {
    _motorSpeed = value.motorSpeed;
    _maxMotorTorque = value.maxMotorTorque;
    handleIfAttached?.then((h) {
      worker.setJointProperty(h, JointProp.motorSpeed, value.motorSpeed);
      worker.setJointProperty(h, JointProp.maxMotorTorque, value.maxMotorTorque);
    });
  }

  /// Translation limits along the slider axis.
  JointTranslationLimits get limits => JointTranslationLimits(min: _lowerTranslation, max: _upperTranslation);
  set limits(JointTranslationLimits value) {
    _lowerTranslation = value.min;
    _upperTranslation = value.max;
    handleIfAttached?.then((h) {
      worker.setJointProperty(h, JointProp.lowerTranslation, value.min);
      worker.setJointProperty(h, JointProp.upperTranslation, value.max);
    });
  }

  /// The current state of the translation limits.
  JointLimitState get limitState => JointLimitState.inactive;

  /// The current translation of the joint along its constrained axis.
  Future<double> get jointTranslation async =>
      (await worker.getJointProperty(await handle, JointProp.lowerTranslation)) as double;

  /// The current speed of the joint along its constrained axis.
  Future<double> get jointSpeed async =>
      (await worker.getJointProperty(await handle, JointProp.motorSpeed)) as double;

  /// The angle (in degrees) referenced between the two bodies used as the constraint.
  double get referenceAngle => _angle;

  /// Gets the motor force applied by the joint scaled by the inverse timestep.
  Future<double> getMotorForce(double timeStep) async {
    final raw = (await worker.getJointProperty(await handle, JointProp.reactionForce)) as Vector2;
    return timeStep > 0 ? raw.length / timeStep : 0.0;
  }
}