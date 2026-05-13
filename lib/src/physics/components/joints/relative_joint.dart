import 'package:meta/meta.dart';
import 'package:vector_math/vector_math_64.dart';
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
  void syncAllProperties() {
    super.syncAllProperties();
    worker.setJointProperty(handle, JointProp.linearOffset, _linearOffset.clone());
    worker.setJointProperty(handle, JointProp.angularOffset, _angularOffset);
    worker.setJointProperty(handle, JointProp.correctionScale, _correctionScale);
    worker.setJointProperty(handle, JointProp.autoConfigureOffset, _autoConfigureOffset);
    worker.setJointProperty(handle, JointProp.maxForce, _maxForce);
    worker.setJointProperty(handle, JointProp.maxTorque, _maxTorque);
  }

  final Vector2 _linearOffset = Vector2.zero();
  Vector2 get linearOffset => _linearOffset;
  set linearOffset(Vector2 value) {
    _linearOffset.setFrom(value);
    if (isAttached) worker.setJointProperty(handle, JointProp.linearOffset, value.clone());
  }

  double _angularOffset = 0.0;
  double get angularOffset => _angularOffset;
  set angularOffset(double value) {
    _angularOffset = value;
    if (isAttached) worker.setJointProperty(handle, JointProp.angularOffset, value);
  }

  double _correctionScale = 0.3;
  double get correctionScale => _correctionScale;
  set correctionScale(double value) {
    _correctionScale = value;
    if (isAttached) worker.setJointProperty(handle, JointProp.correctionScale, value);
  }

  bool _autoConfigureOffset = true;
  bool get autoConfigureOffset => _autoConfigureOffset;
  set autoConfigureOffset(bool value) {
    _autoConfigureOffset = value;
    if (isAttached) worker.setJointProperty(handle, JointProp.autoConfigureOffset, value);
  }

  double _maxForce = 1000.0;
  double get maxForce => _maxForce;
  set maxForce(double value) {
    _maxForce = value;
    if (isAttached) worker.setJointProperty(handle, JointProp.maxForce, value);
  }

  double _maxTorque = 1000.0;
  double get maxTorque => _maxTorque;
  set maxTorque(double value) {
    _maxTorque = value;
    if (isAttached) worker.setJointProperty(handle, JointProp.maxTorque, value);
  }

  Future<Vector2> get target async => (await worker.getJointProperty(handle, JointProp.target)) as Vector2;
}
