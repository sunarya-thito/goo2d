import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/goo2d.dart';

/// The configuration that controls how a Rigidbody2D.Slide method behaves.
/// 
/// Equivalent to Unity's `SlideMovement2D`.
class SlideMovement {
  /// When the gravity movement causes a contact with a Collider2D, slippage maybe occur if the surface angle is greater than this angle.
  double get gravitySlipAngle => throw UnimplementedError('Implemented via Physics Worker');
  set gravitySlipAngle(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The specific Collider2D attached to this Rigidbody2D to be used to detect contacts.
  Collider get selectedCollider => throw UnimplementedError('Implemented via Physics Worker');
  set selectedCollider(Collider value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The gravity to be applied to the slide position.
  Vector2 get gravity => throw UnimplementedError('Implemented via Physics Worker');
  set gravity(Vector2 value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Whether the specified Rigidbody2D.SlideMovement.startPosition should be used or not.
  bool get useStartPosition => throw UnimplementedError('Implemented via Physics Worker');
  set useStartPosition(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The direction and distance to use when detecting if a surface is nearby during a slide iteration.
  Vector2 get surfaceAnchor => throw UnimplementedError('Implemented via Physics Worker');
  set surfaceAnchor(Vector2 value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Controls the maximum number of iterations to perform when determining how a Rigidbody2D will slide.
  int get maxIterations => throw UnimplementedError('Implemented via Physics Worker');
  set maxIterations(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// When the velocity movement causes a contact with a Collider2D, a slide maybe occur if the surface angle is less than this angle.
  double get surfaceSlideAngle => throw UnimplementedError('Implemented via Physics Worker');
  set surfaceSlideAngle(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Can be used to select whether any Collider2D attached to this Rigidbody2D (that are configured as a trigger) are used to detect contacts.
  bool get useAttachedTriggers => throw UnimplementedError('Implemented via Physics Worker');
  set useAttachedTriggers(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Controls whether the Rigidbody2D is instantly moved to the calculated position or is moved with Rigidbody2D.MovePosition.
  bool get useSimulationMove => throw UnimplementedError('Implemented via Physics Worker');
  set useSimulationMove(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Whether the specified Rigidbody2D.SlideMovement.layerMask should be used or not when determining what Collider2D should be detected.
  bool get useLayerMask => throw UnimplementedError('Implemented via Physics Worker');
  set useLayerMask(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Controls if any Rigidbody2D movement will happen or not.
  bool get useNoMove => throw UnimplementedError('Implemented via Physics Worker');
  set useNoMove(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// A reference direction used to calculate contact angles.
  Vector2 get surfaceUp => throw UnimplementedError('Implemented via Physics Worker');
  set surfaceUp(Vector2 value) => throw UnimplementedError('Implemented via Physics Worker');

  /// A LayerMask that will be used when determining what Collider2D should be detected.
  int get layerMask => throw UnimplementedError('Implemented via Physics Worker');
  set layerMask(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The start position to slide the Rigidbody2D from.
  Vector2 get startPosition => throw UnimplementedError('Implemented via Physics Worker');
  set startPosition(Vector2 value) => throw UnimplementedError('Implemented via Physics Worker');

  /// A helper method that simultaneously sets both the Rigidbody2D.SlideMovement.layerMask to the specified mask but also sets Rigidbody2D.SlideMovement.useLayerMask to true.
  /// - [mask]: The layer mask to use.
  void setLayerMask(int mask) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// A helper method that simultaneously sets both the Rigidbody2D.SlideMovement.startPosition to the specified /position but also sets Rigidbody2D.SlideMovement.useStartPosition to true.
  /// - [position]: The position to use.
  void setStartPosition(Vector2 position) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

}