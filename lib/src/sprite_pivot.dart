import 'dart:ui';

/// A definition for the anchor point of a sprite or visual element.
///
/// [SpritePivot] determines the origin point used for transformations such 
/// as rotation, scaling, and positioning. It supports both relative 
/// (normalized 0.0 to 1.0) and fixed pixel-based offsets, allowing 
/// for flexible anchoring regardless of the asset's dimensions.
///
/// ```dart
/// void example(Size size) {
///   const pivot = SpritePivot.relative(0.5, 0.5);
///   final offset = pivot.compute(size);
/// }
/// ```
///
/// See also:
/// * [NormalizedPivot] for percentage-based anchoring.
/// * [PixelPivot] for absolute pixel-based anchoring.
abstract class SpritePivot {
  /// Base constructor for all [SpritePivot] implementations.
  ///
  /// This constructor is kept const to enable efficient sharing of pivot 
  /// definitions across multiple game components. It establishes the contract 
  /// for calculating anchor offsets.
  const SpritePivot();

  /// Creates a pivot point relative to the target's size.
  ///
  /// [NormalizedPivot] uses coordinates where (0.0, 0.0) is the top-left 
  /// and (1.0, 1.0) is the bottom-right. This is ideal for most gameplay 
  /// objects that should rotate around their center or base regardless of 
  /// their specific scale.
  ///
  /// * [x]: The horizontal ratio (typically 0.0 to 1.0).
  /// * [y]: The vertical ratio (typically 0.0 to 1.0).
  const factory SpritePivot.relative(double x, double y) = NormalizedPivot;

  /// Creates a pivot point at a fixed pixel offset.
  ///
  /// [PixelPivot] uses absolute pixel coordinates relative to the top-left 
  /// corner of the asset. This is particularly useful for UI elements or 
  /// sprites where the anchor point corresponds to a specific pixel-perfect 
  /// feature, such as the tip of a sword or the base of a needle.
  ///
  /// * [x]: The horizontal pixel offset.
  /// * [y]: The vertical pixel offset.
  const factory SpritePivot.fixed(double x, double y) = PixelPivot;

  /// Computes the actual [Offset] in pixels for a given [size].
  ///
  /// This method resolves the pivot's abstract definition into concrete 
  /// coordinates that can be used by the rendering engine's transformation 
  /// matrix. The resulting offset is relative to the top-left of the bounds.
  ///
  /// * [size]: The dimensions of the object to compute the pivot for.
  Offset compute(Size size);
}

/// A pivot strategy that uses normalized coordinates.
///
/// [NormalizedPivot] is the most versatile anchoring strategy in the Goo2D 
/// engine. By defining the anchor as a percentage of the total size, it 
/// ensures that the anchor remains logically consistent even if the sprite 
/// source or destination size changes.
///
/// ```dart
/// void example(Size size) {
///   const pivot = NormalizedPivot.center;
///   final offset = pivot.compute(size);
/// }
/// ```
///
/// See also:
/// * [SpritePivot.relative] for the factory constructor.
class NormalizedPivot extends SpritePivot {
  /// The horizontal ratio of the pivot (0.0 to 1.0).
  ///
  /// A value of 0.0 represents the left edge, 0.5 the horizontal center, 
  /// and 1.0 the right edge. Values outside this range are permitted for 
  /// objects that anchor outside their visual bounds.
  final double x;

  /// The vertical ratio of the pivot (0.0 to 1.0).
  ///
  /// A value of 0.0 represents the top edge, 0.5 the vertical center, 
  /// and 1.0 the bottom edge. This coordinate system follows standard 
  /// screen space where Y increases downwards.
  final double y;

  /// Creates a [NormalizedPivot] with explicit [x] and [y] ratios.
  ///
  /// This constructor is ideal for custom alignments. For standard 
  /// alignments like center or top-left, prefer using the static 
  /// constants provided by this class.
  ///
  /// * [x]: The horizontal ratio.
  /// * [y]: The vertical ratio.
  const NormalizedPivot(this.x, this.y);

  @override
  Offset compute(Size size) => Offset(size.width * x, size.height * y);

  /// Anchors the object at its geometric center.
  ///
  /// This is the most common pivot for gameplay objects that rotate, 
  /// ensuring they spin around their midpoint.
  static const center = NormalizedPivot(0.5, 0.5);

  /// Anchors the object at its top-left corner.
  ///
  /// This corresponds to the (0.0, 0.0) coordinate in normalized space. 
  /// It is often used for UI containers and menus.
  static const topLeft = NormalizedPivot(0.0, 0.0);

  /// Anchors the object at its top-right corner.
  ///
  /// This corresponds to the (1.0, 0.0) coordinate in normalized space.
  static const topRight = NormalizedPivot(1.0, 0.0);

  /// Anchors the object at its bottom-left corner.
  ///
  /// This corresponds to the (0.0, 1.0) coordinate in normalized space.
  static const bottomLeft = NormalizedPivot(0.0, 1.0);

  /// Anchors the object at its bottom-right corner.
  ///
  /// This corresponds to the (1.0, 1.0) coordinate in normalized space.
  static const bottomRight = NormalizedPivot(1.0, 1.0);

  /// Anchors the object at the center of its top edge.
  ///
  /// This is useful for elements that hang downwards from a fixed point.
  static const topCenter = NormalizedPivot(0.5, 0.0);

  /// Anchors the object at the center of its bottom edge.
  ///
  /// This is the preferred pivot for ground-based characters and props, 
  /// as it ensures they sit naturally on a floor or platform.
  static const bottomCenter = NormalizedPivot(0.5, 1.0);

  /// Anchors the object at the center of its left edge.
  ///
  /// This is often used for UI labels or progress bars that expand to the right.
  static const leftCenter = NormalizedPivot(0.0, 0.5);

  /// Anchors the object at the center of its right edge.
  ///
  /// This is often used for UI elements that are anchored to the right 
  /// side of the screen.
  static const rightCenter = NormalizedPivot(1.0, 0.5);
}

/// A pivot strategy that uses fixed pixel offsets.
///
/// [PixelPivot] provides absolute control over the anchor location. It is 
/// best suited for sprites where the logical center of the object does 
/// not align with its geometric center, such as an asymmetrical tool or 
/// a character with a long shadow included in the asset.
///
/// ```dart
/// void example(Size size) {
///   const pivot = PixelPivot(16, 32);
///   final offset = pivot.compute(size);
/// }
/// ```
///
/// See also:
/// * [SpritePivot.fixed] for the factory constructor.
class PixelPivot extends SpritePivot {
  /// The horizontal pixel offset from the left edge.
  ///
  /// This value is absolute and does not scale with the object's 
  /// current visual size. It is measured in local asset pixels.
  final double x;

  /// The vertical pixel offset from the top edge.
  ///
  /// This value is absolute and does not scale with the object's 
  /// current visual size. It follows the standard coordinate system 
  /// where positive Y is down.
  final double y;

  /// Creates a [PixelPivot] at the specified [x] and [y] pixel coordinates.
  ///
  /// This constructor is used when you need to pin an object to a specific 
  /// coordinate within the source asset.
  ///
  /// * [x]: Horizontal pixel offset.
  /// * [y]: Vertical pixel offset.
  const PixelPivot(this.x, this.y);

  @override
  Offset compute(Size size) => Offset(x, y);
}
