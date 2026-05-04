import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';

/// Axis-Aligned Bounding Box for broadphase collision detection.
class AABB {
  double minX, minY, maxX, maxY;

  AABB(this.minX, this.minY, this.maxX, this.maxY);
  AABB.zero() : minX = 0, minY = 0, maxX = 0, maxY = 0;

  double get width => maxX - minX;
  double get height => maxY - minY;
  Vector2 get center => Vector2((minX + maxX) * 0.5, (minY + maxY) * 0.5);
  Vector2 get halfExtents => Vector2(width * 0.5, height * 0.5);

  bool overlaps(AABB other) =>
      minX <= other.maxX && maxX >= other.minX &&
      minY <= other.maxY && maxY >= other.minY;

  bool containsPoint(Vector2 p) =>
      p.x >= minX && p.x <= maxX && p.y >= minY && p.y <= maxY;

  /// Expands this AABB to include a point.
  void encapsulate(double x, double y) {
    if (x < minX) minX = x;
    if (x > maxX) maxX = x;
    if (y < minY) minY = y;
    if (y > maxY) maxY = y;
  }

  /// Expands by a uniform margin.
  void expand(double margin) {
    minX -= margin;
    minY -= margin;
    maxX += margin;
    maxY += margin;
  }

  /// Merges another AABB into this one.
  void merge(AABB other) {
    minX = math.min(minX, other.minX);
    minY = math.min(minY, other.minY);
    maxX = math.max(maxX, other.maxX);
    maxY = math.max(maxY, other.maxY);
  }

  /// Ray intersection test. Returns fraction [0, maxFraction] or -1 if miss.
  double raycast(Vector2 origin, Vector2 direction, double maxFraction) {
    var tMin = -double.maxFinite;
    var tMax = double.maxFinite;

    // X slab
    if (direction.x.abs() < 1e-10) {
      if (origin.x < minX || origin.x > maxX) return -1;
    } else {
      final invD = 1.0 / direction.x;
      var t1 = (minX - origin.x) * invD;
      var t2 = (maxX - origin.x) * invD;
      if (t1 > t2) { final tmp = t1; t1 = t2; t2 = tmp; }
      tMin = math.max(tMin, t1);
      tMax = math.min(tMax, t2);
      if (tMin > tMax) return -1;
    }

    // Y slab
    if (direction.y.abs() < 1e-10) {
      if (origin.y < minY || origin.y > maxY) return -1;
    } else {
      final invD = 1.0 / direction.y;
      var t1 = (minY - origin.y) * invD;
      var t2 = (maxY - origin.y) * invD;
      if (t1 > t2) { final tmp = t1; t1 = t2; t2 = tmp; }
      tMin = math.max(tMin, t1);
      tMax = math.min(tMax, t2);
      if (tMin > tMax) return -1;
    }

    if (tMin < 0) tMin = 0;
    if (tMin > maxFraction) return -1;
    return tMin;
  }
}
