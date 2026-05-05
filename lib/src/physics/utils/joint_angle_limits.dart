/// Angular limits on the rotation of a Rigidbody2D object around a HingeJoint2D.
///
/// Equivalent to Unity's `JointAngleLimits2D`.
class JointAngleLimits {
  JointAngleLimits({this.min = 0.0, this.max = 0.0});

  /// Upper angular limit of rotation.
  double max;

  /// Lower angular limit of rotation.
  double min;
}
