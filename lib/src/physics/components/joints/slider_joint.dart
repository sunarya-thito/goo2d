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
    handle.then((h) {
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
    handle.then((h) => worker.setJointProperty(h, JointProp.anchor, value));
  }

  final Vector2 _connectedAnchor = Vector2.zero();
  /// The local anchor point on the connected Rigidbody2D where the joint is attached.
  Vector2 get connectedAnchor => _connectedAnchor;
  set connectedAnchor(Vector2 value) {
    _connectedAnchor.setFrom(value);
    handle.then((h) => worker.setJointProperty(h, JointProp.connectedAnchor, value));
  }

  bool _autoConfigureConnectedAnchor = true;
  /// Should the connected anchor be calculated automatically?
  bool get autoConfigureConnectedAnchor => _autoConfigureConnectedAnchor;
  set autoConfigureConnectedAnchor(bool value) {
    _autoConfigureConnectedAnchor = value;
    handle.then((h) => worker.setJointProperty(h, JointProp.autoConfigureConnectedAnchor, value));
  }

  bool _useMotor = false;
  /// Should a motor force be applied automatically to the Rigidbody2D?
  bool get useMotor => _useMotor;
  set useMotor(bool value) {
    _useMotor = value;
    handle.then((h) => worker.setJointProperty(h, JointProp.useMotor, value));
  }

  double _angle = 0.0;
  /// The angle of the line in space (in degrees).
  double get angle => _angle;
  set angle(double value) {
    _angle = value;
    handle.then((h) => worker.setJointProperty(h, JointProp.sliderAngle, value));
  }

  bool _useLimits = false;
  /// Should motion limits be used?
  bool get useLimits => _useLimits;
  set useLimits(bool value) {
    _useLimits = value;
    handle.then((h) => worker.setJointProperty(h, JointProp.useTranslationLimits, value));
  }

  bool _autoConfigureAngle = true;
  /// Should the angle be calculated automatically?
  bool get autoConfigureAngle => _autoConfigureAngle;
  set autoConfigureAngle(bool value) {
    _autoConfigureAngle = value;
    handle.then((h) => worker.setJointProperty(h, JointProp.autoConfigureAngle, value));
  }

  /// Parameters for a motor force that is applied automatically to the Rigibody2D along the line.
  Object? get motor => null; // Missing spec for JointMotor2D

  /// Restrictions on how far the joint can slide in each direction along the line.
  Object? get limits => null; // Missing spec for JointTranslationLimits2D

  /// Gets the state of the joint limit.
  Object? get limitState => null; // Missing spec for JointLimitState2D

  /// The current joint translation.
  Future<double> get jointTranslation async => 0.0; // Placeholder

  /// The current joint speed.
  Future<double> get jointSpeed async => 0.0; // Placeholder

  /// The angle (in degrees) referenced between the two bodies used as the constraint for the joint.
  Future<double> get referenceAngle async => 0.0; // Placeholder

  /// Gets the motor force of the joint given the specified timestep.
  Future<double> GetMotorForce(double timeStep) async => 0.0; // Placeholder
}