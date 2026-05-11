import 'package:vector_math/vector_math_64.dart';
import 'package:meta/meta.dart';
import 'package:goo2d/src/physics/components/joint.dart';
import 'package:goo2d/src/physics/worker/direct/direct_joint_ops.dart';
import 'package:goo2d/src/physics/worker/data/joint_type.dart';
import 'package:goo2d/goo2d.dart';

/// Connects two Rigidbody2D together at their anchor points using a configurable spring.
/// 
/// Equivalent to Unity's `FixedJoint2D`.
class FixedJoint extends Joint {
  @override
  int get jointType => JointType.fixed;

  @override
  @protected
  void syncProperties() {
    super.syncProperties();
    handleIfAttached?.then((h) {
      worker.setJointProperty(h, JointProp.anchor, _anchor);
      worker.setJointProperty(h, JointProp.connectedAnchor, _connectedAnchor);
      worker.setJointProperty(h, JointProp.autoConfigureConnectedAnchor, _autoConfigureConnectedAnchor);
      worker.setJointProperty(h, JointProp.springFrequency, _frequency);
      worker.setJointProperty(h, JointProp.springDampingRatio, _dampingRatio);
      worker.setJointProperty(h, JointProp.angularOffset, _referenceAngle);
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

  double _frequency = 0.0;
  /// The frequency at which the spring oscillates around the distance between the objects.
  double get frequency => _frequency;
  set frequency(double value) {
    _frequency = value;
    handleIfAttached?.then((h) => worker.setJointProperty(h, JointProp.springFrequency, value));
  }

  double _dampingRatio = 0.0;
  /// The amount by which the spring force is reduced in proportion to the movement speed.
  double get dampingRatio => _dampingRatio;
  set dampingRatio(double value) {
    _dampingRatio = value;
    handleIfAttached?.then((h) => worker.setJointProperty(h, JointProp.springDampingRatio, value));
  }

  double _referenceAngle = 0.0;
  /// The angle referenced between the two bodies used as the constraint for the joint.
  double get referenceAngle => _referenceAngle;
  set referenceAngle(double value) {
    _referenceAngle = value;
    handleIfAttached?.then((h) => worker.setJointProperty(h, JointProp.angularOffset, value));
  }
}