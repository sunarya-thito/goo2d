import 'dart:ui';

/// Base class for defining the anchor point of a sprite.
/// 
/// A pivot point determines the origin (0,0) for an object's rotation, 
/// scaling, and positioning. Links to [GameSprite] for usage.
/// 
/// ```dart
/// class MyPivot extends SpritePivot {
///   @override
///   Offset compute(Size size) => Offset(0, 0);
/// }
/// ```
abstract class SpritePivot {
  /// Constant constructor for subclasses.
  /// 
  /// Initializes the pivot instance.
  const SpritePivot();

  /// Calculates the absolute offset in pixels.
  /// 
  /// Transforms the pivot coordinates into a concrete [Offset] based on [size].
  ///
  /// * [size]: The dimensions of the sprite.
  Offset compute(Size size);
}

/// A pivot defined by normalized coordinates (0.0 to 1.0).
///
/// Remains valid even if the sprite's texture size changes. Links to 
/// [SpritePivot] for the base implementation.
/// 
/// ```dart
/// // Rotate around the bottom-right corner
/// const pivot = NormalizedPivot(1.0, 1.0);
/// ```
class NormalizedPivot extends SpritePivot {
  /// The horizontal normalized coordinate.
  /// 
  /// Range: 0.0 (left) to 1.0 (right).
  final double x;

  /// The vertical normalized coordinate.
  /// 
  /// Range: 0.0 (top) to 1.0 (bottom).
  final double y;

  /// Creates a pivot at [x], [y].
  /// 
  /// Initializes the pivot with normalized coordinates.
  ///
  /// * [x]: Normalized horizontal coordinate.
  /// * [y]: Normalized vertical coordinate.
  const NormalizedPivot(this.x, this.y);

  @override
  Offset compute(Size size) => Offset(size.width * x, size.height * y);

  /// Anchor at the geometric center (0.5, 0.5).
  /// 
  /// Perfect for rotating sprites around their middle.
  static const center = NormalizedPivot(0.5, 0.5);

  /// Anchor at the top-left corner (0.0, 0.0).
  /// 
  /// Default for many UI elements.
  static const topLeft = NormalizedPivot(0.0, 0.0);

  /// Anchor at the top-right corner (1.0, 0.0).
  /// 
  /// Useful for right-aligned HUD elements.
  static const topRight = NormalizedPivot(1.0, 0.0);

  /// Anchor at the bottom-left corner (0.0, 1.0).
  /// 
  /// Common for ground-pinned sprites.
  static const bottomLeft = NormalizedPivot(0.0, 1.0);

  /// Anchor at the bottom-right corner (1.0, 1.0).
  /// 
  /// Useful for bottom-right UI anchors.
  static const bottomRight = NormalizedPivot(1.0, 1.0);

  /// Anchor at the top-center (0.5, 0.0).
  /// 
  /// Useful for hanging UI panels.
  static const topCenter = NormalizedPivot(0.5, 0.0);

  /// Anchor at the bottom-center (0.5, 1.0).
  /// 
  /// Ideal for characters that stand on the ground.
  static const bottomCenter = NormalizedPivot(0.5, 1.0);

  /// Anchor at the left-center (0.0, 0.5).
  /// 
  /// Useful for side-scrolling UI elements.
  static const leftCenter = NormalizedPivot(0.0, 0.5);

  /// Anchor at the right-center (1.0, 0.5).
  /// 
  /// Useful for right-pinned health bars.
  static const rightCenter = NormalizedPivot(1.0, 0.5);
}

/// A pivot defined by absolute pixel coordinates.
///
/// Ideal for character joints and precise alignment. Links to 
/// [SpritePivot] for the base implementation.
/// 
/// ```dart
/// const pivot = PixelPivot(16.0, 16.0);
/// ```
class PixelPivot extends SpritePivot {
  /// The horizontal pixel coordinate.
  /// 
  /// Defines the X-axis offset from the top-left edge.
  final double x;

  /// The vertical pixel coordinate.
  /// 
  /// Defines the Y-axis offset from the top-left edge.
  final double y;

  /// Creates a pivot at the specific [x], [y] pixel location.
  /// 
  /// Initializes the pivot with absolute pixel offsets.
  ///
  /// * [x]: X-coordinate in pixels.
  /// * [y]: Y-coordinate in pixels.
  const PixelPivot(this.x, this.y);

  @override
  Offset compute(Size size) => Offset(x, y);
}
