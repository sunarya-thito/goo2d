import 'package:vector_math/vector_math_64.dart';

/// A 2D Rectangle defined by X and Y position, width and height.
///
/// Equivalent to Unity's `Rect`.
class Rect {
  Rect(this.x, this.y, this.width, this.height);
  Rect.fromMinMax(Vector2 min, Vector2 max)
      : x = min.x, y = min.y, width = max.x - min.x, height = max.y - min.y;

  double x;
  double y;
  double width;
  double height;

  double get xMin => x;
  double get xMax => x + width;
  double get yMin => y;
  double get yMax => y + height;
  Vector2 get min => Vector2(xMin, yMin);
  Vector2 get max => Vector2(xMax, yMax);
  Vector2 get center => Vector2(x + width / 2, y + height / 2);
  Vector2 get size => Vector2(width, height);
  Vector2 get position => Vector2(x, y);

  set xMin(double v) { width += x - v; x = v; }
  set xMax(double v) => width = v - x;
  set yMin(double v) { height += y - v; y = v; }
  set yMax(double v) => height = v - y;
  set min(Vector2 v) { xMin = v.x; yMin = v.y; }
  set max(Vector2 v) { xMax = v.x; yMax = v.y; }
  set center(Vector2 v) { x = v.x - width / 2; y = v.y - height / 2; }
  set size(Vector2 v) { width = v.x; height = v.y; }
  set position(Vector2 v) { x = v.x; y = v.y; }

  static Rect get zero => Rect(0, 0, 0, 0);

  static Vector2 pointToNormalized(Rect rectangle, Vector2 point) =>
      Vector2((point.x - rectangle.x) / rectangle.width, (point.y - rectangle.y) / rectangle.height);

  static Vector2 normalizedToPoint(Rect rectangle, Vector2 normalizedRectCoordinates) =>
      Vector2(rectangle.x + normalizedRectCoordinates.x * rectangle.width,
              rectangle.y + normalizedRectCoordinates.y * rectangle.height);

  static Rect minMaxRect(double xmin, double ymin, double xmax, double ymax) =>
      Rect(xmin, ymin, xmax - xmin, ymax - ymin);

  bool contains(Vector2 point) =>
      point.x >= x && point.x <= x + width && point.y >= y && point.y <= y + height;

  void set(double x, double y, double width, double height) {
    this.x = x; this.y = y; this.width = width; this.height = height;
  }

  bool overlaps(Rect other) =>
      xMax > other.xMin && xMin < other.xMax && yMax > other.yMin && yMin < other.yMax;

  @override
  String toString() => 'Rect(x: $x, y: $y, width: $width, height: $height)';
}
