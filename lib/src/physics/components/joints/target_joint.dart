import 'package:meta/meta.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/src/physics/worker/direct/direct_joint_ops.dart';
import 'package:goo2d/src/physics/worker/data/joint_type.dart';
import 'package:goo2d/goo2d.dart';

/// Joint that connects a Rigidbody2D to a fixed target point.
///
/// Equivalent to Unity's `TargetJoint2D`.
class TargetJoint extends Joint {
  @override
  int get jointType => JointType.target;

  @override
  @protected
  void syncAllProperties() {
    super.syncAllProperties();
    worker.setJointProperty(handle, JointProp.anchor, _anchor.clone());
    worker.setJointProperty(handle, JointProp.target, _target.clone());
    worker.setJointProperty(handle, JointProp.targetMaxForce, _maxForce);
    worker.setJointProperty(handle, JointProp.autoConfigureConnectedAnchor, _autoConfigureTarget);
    worker.setJointProperty(handle, JointProp.springFrequency, _frequency);
    worker.setJointProperty(handle, JointProp.springDampingRatio, _dampingRatio);
  }

  final Vector2 _anchor = Vector2.zero();
  Vector2 get anchor => _anchor;
  set anchor(Vector2 value) {
    _anchor.setFrom(value);
    if (isAttached) worker.setJointProperty(handle, JointProp.anchor, value.clone());
  }

  final Vector2 _target = Vector2.zero();
  Vector2 get target => _target;
  set target(Vector2 value) {
    _target.setFrom(value);
    if (isAttached) worker.setJointProperty(handle, JointProp.target, value.clone());
  }

  double _maxForce = 1000.0;
  double get maxForce => _maxForce;
  set maxForce(double value) {
    _maxForce = value;
    if (isAttached) worker.setJointProperty(handle, JointProp.targetMaxForce, value);
  }

  bool _autoConfigureTarget = true;
  bool get autoConfigureTarget => _autoConfigureTarget;
  set autoConfigureTarget(bool value) {
    _autoConfigureTarget = value;
    if (isAttached) worker.setJointProperty(handle, JointProp.autoConfigureConnectedAnchor, value);
  }

  double _frequency = 5.0;
  double get frequency => _frequency;
  set frequency(double value) {
    _frequency = value;
    if (isAttached) worker.setJointProperty(handle, JointProp.springFrequency, value);
  }

  double _dampingRatio = 0.7;
  double get dampingRatio => _dampingRatio;
  set dampingRatio(double value) {
    _dampingRatio = value;
    if (isAttached) worker.setJointProperty(handle, JointProp.springDampingRatio, value);
  }
}
