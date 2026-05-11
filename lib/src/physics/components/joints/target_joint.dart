import 'package:meta/meta.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/src/physics/components/joint.dart';
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
  void syncProperties() {
    super.syncProperties();
    handleIfAttached?.then((h) {
      worker.setJointProperty(h, JointProp.anchor, _anchor);
      worker.setJointProperty(h, JointProp.target, _target);
      worker.setJointProperty(h, JointProp.targetMaxForce, _maxForce);
      worker.setJointProperty(h, JointProp.autoConfigureConnectedAnchor, _autoConfigureTarget);
      worker.setJointProperty(h, JointProp.springFrequency, _frequency);
      worker.setJointProperty(h, JointProp.springDampingRatio, _dampingRatio);
    });
  }

  final Vector2 _anchor = Vector2.zero();
  /// The local anchor point on the Rigidbody2D where the joint is attached.
  Vector2 get anchor => _anchor;
  set anchor(Vector2 value) {
    _anchor.setFrom(value);
    handleIfAttached?.then((h) => worker.setJointProperty(h, JointProp.anchor, value));
  }

  final Vector2 _target = Vector2.zero();
  /// The world-space position that the joint is currently trying to maintain.
  Vector2 get target => _target;
  set target(Vector2 value) {
    _target.setFrom(value);
    handleIfAttached?.then((h) => worker.setJointProperty(h, JointProp.target, value));
  }

  double _maxForce = 1000.0;
  /// The maximum force that can be generated when trying to maintain the target joint constraint.
  double get maxForce => _maxForce;
  set maxForce(double value) {
    _maxForce = value;
    handleIfAttached?.then((h) => worker.setJointProperty(h, JointProp.targetMaxForce, value));
  }

  bool _autoConfigureTarget = true;
  /// Should the target be calculated automatically?
  bool get autoConfigureTarget => _autoConfigureTarget;
  set autoConfigureTarget(bool value) {
    _autoConfigureTarget = value;
    handleIfAttached?.then((h) => worker.setJointProperty(h, JointProp.autoConfigureConnectedAnchor, value));
  }

  double _frequency = 5.0;
  /// The frequency at which the target spring oscillates around the target position.
  double get frequency => _frequency;
  set frequency(double value) {
    _frequency = value;
    handleIfAttached?.then((h) => worker.setJointProperty(h, JointProp.springFrequency, value));
  }

  double _dampingRatio = 0.7;
  /// The amount by which the target spring force is reduced in proportion to the movement speed.
  double get dampingRatio => _dampingRatio;
  set dampingRatio(double value) {
    _dampingRatio = value;
    handleIfAttached?.then((h) => worker.setJointProperty(h, JointProp.springDampingRatio, value));
  }
}