import 'package:meta/meta.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/src/physics/components/joint.dart';
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
  void syncProperties() {
    super.syncProperties();
    handle.then((h) {
      worker.setJointProperty(h, JointProp.anchor, _anchor);
      worker.setJointProperty(h, JointProp.connectedAnchor, _connectedAnchor);
      worker.setJointProperty(h, JointProp.autoConfigureConnectedAnchor, _autoConfigureConnectedAnchor);
      worker.setJointProperty(h, JointProp.distance, _distance);
      worker.setJointProperty(h, JointProp.autoConfigureDistance, _autoConfigureDistance);
      worker.setJointProperty(h, JointProp.maxDistanceOnly, _maxDistanceOnly);
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

  bool _autoConfigureDistance = true;
  /// Should the distance be calculated automatically?
  bool get autoConfigureDistance => _autoConfigureDistance;
  set autoConfigureDistance(bool value) {
    _autoConfigureDistance = value;
    handle.then((h) => worker.setJointProperty(h, JointProp.autoConfigureDistance, value));
  }

  bool _maxDistanceOnly = false;
  /// Whether to maintain a maximum distance only or not. If not then the absolute distance will be maintained instead.
  bool get maxDistanceOnly => _maxDistanceOnly;
  set maxDistanceOnly(bool value) {
    _maxDistanceOnly = value;
    handle.then((h) => worker.setJointProperty(h, JointProp.maxDistanceOnly, value));
  }

  double _distance = 1.0;
  /// The distance separating the two ends of the joint.
  double get distance => _distance;
  set distance(double value) {
    _distance = value;
    handle.then((h) => worker.setJointProperty(h, JointProp.distance, value));
  }
}