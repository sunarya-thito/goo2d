/// Joint suspension used to define how suspension works on a WheelJoint2D.
///
/// Equivalent to Unity's `JointSuspension2D`.
class JointSuspension {
  JointSuspension({this.frequency = 1.0, this.angle = 0.0, this.dampingRatio = 0.0});

  /// The frequency at which the suspension spring oscillates.
  double frequency;

  /// The world angle (in degrees) along which the suspension will move.
  double angle;

  /// The amount by which the suspension spring force is reduced in proportion to the movement speed.
  double dampingRatio;
}
