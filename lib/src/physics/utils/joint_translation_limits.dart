/// Motion limits of a Rigidbody2D object along a SliderJoint2D.
///
/// Equivalent to Unity's `JointTranslationLimits2D`.
class JointTranslationLimits {
  JointTranslationLimits({this.min = 0.0, this.max = 0.0});

  /// Maximum distance the Rigidbody2D object can move from the Slider Joint's anchor.
  double max;

  /// Minimum distance the Rigidbody2D object can move from the Slider Joint's anchor.
  double min;
}
