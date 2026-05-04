import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/goo2d.dart';

/// A 2D Rectangle defined by X and Y position, width and height.
/// 
/// Equivalent to Unity's `Rect2D`.
class Rect {
  /// Shorthand for writing new Rect(0,0,0,0).
  static Rect get zero => throw UnimplementedError('Implemented via Physics Worker');
  static set zero(Rect value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Returns the normalized coordinates corresponding to the point.
  /// - [rectangle]: Rectangle to get normalized coordinates inside.
  /// - [point]: A point inside the rectangle to get normalized coordinates for.
  static Vector2 pointToNormalized(Rect rectangle, Vector2 point) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Returns a point inside a rectangle, given normalized coordinates.
  /// - [rectangle]: Rectangle to get a point inside.
  /// - [normalizedRectCoordinates]: Normalized coordinates to get a point for.
  static Vector2 normalizedToPoint(Rect rectangle, Vector2 normalizedRectCoordinates) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Creates a rectangle from min/max coordinate values.
  /// - [xmin]: The minimum X coordinate.
  /// - [ymin]: The minimum Y coordinate.
  /// - [xmax]: The maximum X coordinate.
  /// - [ymax]: The maximum Y coordinate.
  static Rect minMaxRect(double xmin, double ymin, double xmax, double ymax) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// The minimum Y coordinate of the rectangle.
  double get yMin => throw UnimplementedError('Implemented via Physics Worker');
  set yMin(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The position of the minimum corner of the rectangle.
  Vector2 get min => throw UnimplementedError('Implemented via Physics Worker');
  set min(Vector2 value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The position of the maximum corner of the rectangle.
  Vector2 get max => throw UnimplementedError('Implemented via Physics Worker');
  set max(Vector2 value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The height of the rectangle, measured from the Y position.
  double get height => throw UnimplementedError('Implemented via Physics Worker');
  set height(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The width and height of the rectangle.
  Vector2 get size => throw UnimplementedError('Implemented via Physics Worker');
  set size(Vector2 value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The position of the center of the rectangle.
  Vector2 get center => throw UnimplementedError('Implemented via Physics Worker');
  set center(Vector2 value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The maximum Y coordinate of the rectangle.
  double get yMax => throw UnimplementedError('Implemented via Physics Worker');
  set yMax(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The minimum X coordinate of the rectangle.
  double get xMin => throw UnimplementedError('Implemented via Physics Worker');
  set xMin(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The X coordinate of the rectangle.
  double get x => throw UnimplementedError('Implemented via Physics Worker');
  set x(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The width of the rectangle, measured from the X position.
  double get width => throw UnimplementedError('Implemented via Physics Worker');
  set width(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The maximum X coordinate of the rectangle.
  double get xMax => throw UnimplementedError('Implemented via Physics Worker');
  set xMax(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The X and Y position of the rectangle.
  Vector2 get position => throw UnimplementedError('Implemented via Physics Worker');
  set position(Vector2 value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The Y coordinate of the rectangle.
  double get y => throw UnimplementedError('Implemented via Physics Worker');
  set y(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Returns true if the x and y components of point is a point inside this rectangle. If allowInverse is present and true, the width and height of the Rect are allowed to take negative values (ie, the min value is greater than the max), and the test will still work.
  /// - [point]: Point to test.
  bool contains(Vector2 point) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Set components of an existing Rect.
  void set(double p0, double p1, double p2, double p3) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Returns true if the other rectangle overlaps this one. If allowInverse is present and true, the widths and heights of the Rects are allowed to take negative values (ie, the min value is greater than the max), and the test will still work.
  /// - [other]: Other rectangle to test overlapping with.
  bool overlaps(Rect other) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

}