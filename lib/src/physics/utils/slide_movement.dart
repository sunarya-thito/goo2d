import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/goo2d.dart';

/// The configuration that controls how a Rigidbody2D.Slide method behaves.
///
/// Equivalent to Unity's `SlideMovement2D`.
class SlideMovement {
  SlideMovement()
      : gravity = Vector2.zero(),
        surfaceAnchor = Vector2.zero(),
        surfaceUp = Vector2(0, 1),
        startPosition = Vector2.zero();

  /// When gravity causes contact with a Collider2D, slippage may occur if the surface angle exceeds this value.
  double gravitySlipAngle = 90.0;

  /// The specific Collider2D to be used to detect contacts.
  Collider? selectedCollider;

  /// The gravity to be applied to the slide position.
  Vector2 gravity;

  /// Whether the specified startPosition should be used.
  bool useStartPosition = false;

  /// The direction and distance used when detecting a nearby surface.
  Vector2 surfaceAnchor;

  /// Controls the maximum number of slide iterations.
  int maxIterations = 4;

  /// When velocity causes contact with a Collider2D, a slide may occur if the surface angle is less than this value.
  double surfaceSlideAngle = 90.0;

  /// Whether attached trigger Collider2Ds are used to detect contacts.
  bool useAttachedTriggers = false;

  /// Whether the Rigidbody2D is instantly moved or moved with MovePosition.
  bool useSimulationMove = false;

  /// Whether the specified layerMask is used when determining Collider2D detection.
  bool useLayerMask = false;

  /// Controls if any Rigidbody2D movement will happen.
  bool useNoMove = false;

  /// A reference direction used to calculate contact angles.
  Vector2 surfaceUp;

  /// The LayerMask used when determining Collider2D detection.
  int layerMask = ~0;

  /// The start position to slide the Rigidbody2D from.
  Vector2 startPosition;

  /// Sets the layerMask and enables useLayerMask.
  void setLayerMask(int mask) {
    layerMask = mask;
    useLayerMask = true;
  }

  /// Sets the startPosition and enables useStartPosition.
  void setStartPosition(Vector2 position) {
    startPosition = position;
    useStartPosition = true;
  }
}
