import 'package:meta/meta.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/src/physics/components/joint.dart';
import 'package:goo2d/src/physics/worker/direct/direct_joint_ops.dart';
import 'package:goo2d/src/physics/worker/data/joint_type.dart';
import 'package:goo2d/goo2d.dart';

/// Keeps two Rigidbody2D at their relative orientations.
/// 
/// Equivalent to Unity's `RelativeJoint2D`.
class RelativeJoint extends Joint {
  @override
  int get jointType => JointType.relative;

  @override
  @protected
  void syncProperties() {
    super.syncProperties();
    handleIfAttached?.then((h) {
      worker.setJointProperty(h, JointProp.linearOffset, _linearOffset);
      worker.setJointProperty(h, JointProp.angularOffset, _angularOffset);
      worker.setJointProperty(h, JointProp.correctionScale, _correctionScale);
      worker.setJointProperty(h, JointProp.autoConfigureOffset, _autoConfigureOffset);
      worker.setJointProperty(h, JointProp.maxForce, _maxForce);
      worker.setJointProperty(h, JointProp.maxTorque, _maxTorque);
    });
  }

  final Vector2 _linearOffset = Vector2.zero();
  /// The current linear offset between the Rigidbody2D that the joint connects.
  Vector2 get linearOffset => _linearOffset;
  set linearOffset(Vector2 value) {
    _linearOffset.setFrom(value);
    handleIfAttached?.then((h) => worker.setJointProperty(h, JointProp.linearOffset, value));
  }

  double _angularOffset = 0.0;
  /// The current angular offset between the Rigidbody2D that the joint connects.
  double get angularOffset => _angularOffset;
  set angularOffset(double value) {
    _angularOffset = value;
    handleIfAttached?.then((h) => worker.setJointProperty(h, JointProp.angularOffset, value));
  }

  double _correctionScale = 0.3;
  /// Scales both the linear and angular forces used to correct the required relative orientation.
  double get correctionScale => _correctionScale;
  set correctionScale(double value) {
    _correctionScale = value;
    handleIfAttached?.then((h) => worker.setJointProperty(h, JointProp.correctionScale, value));
  }

  bool _autoConfigureOffset = true;
  /// Should both the linearOffset and angularOffset be calculated automatically?
  bool get autoConfigureOffset => _autoConfigureOffset;
  set autoConfigureOffset(bool value) {
    _autoConfigureOffset = value;
    handleIfAttached?.then((h) => worker.setJointProperty(h, JointProp.autoConfigureOffset, value));
  }

  double _maxForce = 1000.0;
  /// The maximum force that can be generated when trying to maintain the relative joint constraint.
  double get maxForce => _maxForce;
  set maxForce(double value) {
    _maxForce = value;
    handleIfAttached?.then((h) => worker.setJointProperty(h, JointProp.maxForce, value));
  }

  double _maxTorque = 1000.0;
  /// The maximum torque that can be generated when trying to maintain the relative joint constraint.
  double get maxTorque => _maxTorque;
  set maxTorque(double value) {
    _maxTorque = value;
    handleIfAttached?.then((h) => worker.setJointProperty(h, JointProp.maxTorque, value));
  }

  /// The world-space position that is currently trying to be maintained.
  Future<Vector2> get target async => (await worker.getJointProperty(await handle, JointProp.target)) as Vector2;
}