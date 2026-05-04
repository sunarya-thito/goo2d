import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/goo2d.dart';

/// The results of a slide movement performed with Rigidbody2D.Slide.
/// 
/// Equivalent to Unity's `SlideResults2D`.
class SlideResults {
  /// Returns the remaining velocity that couldn't be used when performing a Rigidbody2D.Slide.
  Vector2 get remainingVelocity => throw UnimplementedError('Implemented via Physics Worker');
  set remainingVelocity(Vector2 value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The position that was calculate as a target position to move to when performing a Rigidbody2D.Slide.
  Vector2 get position => throw UnimplementedError('Implemented via Physics Worker');
  set position(Vector2 value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The specific contact found when a slide movement is performed with Rigidbody2D.Slide.
  RaycastHit get surfaceHit => throw UnimplementedError('Implemented via Physics Worker');
  set surfaceHit(RaycastHit value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Returns the number of iterations used when performing a Rigidbody2D.Slide.
  int get iterationsUsed => throw UnimplementedError('Implemented via Physics Worker');
  set iterationsUsed(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The specific contact found when a slide movement is performed with Rigidbody2D.Slide.
  RaycastHit get slideHit => throw UnimplementedError('Implemented via Physics Worker');
  set slideHit(RaycastHit value) => throw UnimplementedError('Implemented via Physics Worker');

}