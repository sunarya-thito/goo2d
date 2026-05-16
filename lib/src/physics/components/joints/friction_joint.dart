import 'package:meta/meta.dart';
import 'package:goo2d/src/physics/worker/direct/direct_joint_ops.dart';
import 'package:goo2d/goo2d.dart';

/// Applies both force and torque to reduce both the linear and angular velocities to zero.
///
/// Equivalent to Unity's `FrictionJoint2D`.
class FrictionJoint extends Joint {
  @override
  int get jointType => 2;

  @override
  @protected
  void syncAllProperties() {
    super.syncAllProperties();
    worker.setJointProperty(handle, JointProp.maxForce, _maxForce);
    worker.setJointProperty(handle, JointProp.maxTorque, _maxTorque);
  }

  double _maxForce = 0;
  double get maxForce => _maxForce;
  set maxForce(double value) {
    _maxForce = value;
    if (isAttached) worker.setJointProperty(handle, JointProp.maxForce, value);
  }

  double _maxTorque = 0;
  double get maxTorque => _maxTorque;
  set maxTorque(double value) {
    _maxTorque = value;
    if (isAttached) worker.setJointProperty(handle, JointProp.maxTorque, value);
  }
}
