import 'package:meta/meta.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/src/physics/worker/direct/direct_joint_ops.dart';
import 'package:goo2d/src/physics/worker/data/joint_type.dart';
import 'package:goo2d/goo2d.dart';

/// Joint that keeps two Rigidbody2D objects a fixed distance apart.
///
/// Equivalent to Unity's `DistanceJoint2D`.
class DistanceJoint extends Joint {
  @override
  int get jointType => JointType.distance;

  @override
  @protected
  void syncAllProperties() {
    super.syncAllProperties();
    worker.setJointProperty(handle, JointProp.anchor, _anchor.clone());
    worker.setJointProperty(handle, JointProp.connectedAnchor, _connectedAnchor.clone());
    worker.setJointProperty(handle, JointProp.autoConfigureConnectedAnchor, _autoConfigureConnectedAnchor);
    worker.setJointProperty(handle, JointProp.distance, _distance);
    worker.setJointProperty(handle, JointProp.autoConfigureDistance, _autoConfigureDistance);
    worker.setJointProperty(handle, JointProp.maxDistanceOnly, _maxDistanceOnly ? 1.0 : 0.0);
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

  bool _autoConfigureDistance = true;
  bool get autoConfigureDistance => _autoConfigureDistance;
  set autoConfigureDistance(bool value) {
    _autoConfigureDistance = value;
    if (isAttached) worker.setJointProperty(handle, JointProp.autoConfigureDistance, value);
  }

  bool _maxDistanceOnly = false;
  bool get maxDistanceOnly => _maxDistanceOnly;
  set maxDistanceOnly(bool value) {
    _maxDistanceOnly = value;
    if (isAttached) worker.setJointProperty(handle, JointProp.maxDistanceOnly, value ? 1.0 : 0.0);
  }

  double _distance = 1.0;
  double get distance => _distance;
  set distance(double value) {
    _distance = value;
    if (isAttached) worker.setJointProperty(handle, JointProp.distance, value);
  }
}
