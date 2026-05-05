import 'package:meta/meta.dart';
import 'package:goo2d/src/physics/components/joint.dart';
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
  void syncProperties() {
    super.syncProperties();
    handle.then((h) {
      worker.setJointProperty(h, JointProp.maxForce, _maxForce);
      worker.setJointProperty(h, JointProp.maxTorque, _maxTorque);
    });
  }

  double _maxForce = 0;
  /// The maximum force that can be generated when trying to maintain the friction joint constraint.
  double get maxForce => _maxForce;
  set maxForce(double value) {
    _maxForce = value;
    handle.then((h) => worker.setJointProperty(h, JointProp.maxForce, value));
  }

  double _maxTorque = 0;
  /// The maximum torque that can be generated when trying to maintain the friction joint constraint.
  double get maxTorque => _maxTorque;
  set maxTorque(double value) {
    _maxTorque = value;
    handle.then((h) => worker.setJointProperty(h, JointProp.maxTorque, value));
  }
}