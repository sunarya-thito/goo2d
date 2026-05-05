/// Parameters for the optional motor force applied to a Joint2D.
///
/// Equivalent to Unity's `JointMotor2D`.
class JointMotor {
  JointMotor({this.maxMotorTorque = 0.0, this.motorSpeed = 0.0});

  /// The maximum force that can be applied to the Rigidbody2D at the joint to attain the target speed.
  double maxMotorTorque;

  /// The desired speed for the Rigidbody2D to reach as it moves with the joint.
  double motorSpeed;
}
