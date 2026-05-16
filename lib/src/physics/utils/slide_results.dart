import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/goo2d.dart';

/// The results of a slide movement performed with Rigidbody2D.Slide.
///
/// Equivalent to Unity's `SlideResults2D`.
class SlideResults {
  SlideResults()
      : remainingVelocity = Vector2.zero(),
        position = Vector2.zero();

  /// The remaining velocity that couldn't be used during the slide.
  Vector2 remainingVelocity;

  /// The target position calculated during the slide.
  Vector2 position;

  /// The surface contact found during the slide.
  RaycastHit? surfaceHit;

  /// The number of iterations used during the slide.
  int iterationsUsed = 0;

  /// The contact found when a slide movement occurred.
  RaycastHit? slideHit;
}
