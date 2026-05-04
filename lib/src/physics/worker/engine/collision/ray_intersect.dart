import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';

/// Result of a ray vs shape intersection test.
class RayHit {
  final double fraction;
  final Vector2 point;
  final Vector2 normal;

  const RayHit(this.fraction, this.point, this.normal);
}

/// Ray vs circle intersection.
///
/// Returns null if no hit within [maxFraction].
RayHit? rayVsCircle(
    Vector2 origin, Vector2 direction, double maxFraction,
    Vector2 center, double radius) {
  final oc = origin - center;
  final a = direction.dot(direction);
  final b = 2.0 * oc.dot(direction);
  final c = oc.dot(oc) - radius * radius;
  final disc = b * b - 4.0 * a * c;
  if (disc < 0) return null;

  final sqrtDisc = math.sqrt(disc);
  var t = (-b - sqrtDisc) / (2.0 * a);
  if (t < 0) t = (-b + sqrtDisc) / (2.0 * a);
  if (t < 0 || t > maxFraction) return null;

  final point = origin + direction * t;
  final normal = (point - center)..normalize();
  return RayHit(t, point, normal);
}

/// Ray vs line segment intersection.
///
/// Returns null if no hit within [maxFraction].
RayHit? rayVsSegment(
    Vector2 origin, Vector2 direction, double maxFraction,
    Vector2 p1, Vector2 p2) {
  final edge = p2 - p1;
  final dxe = direction.x * edge.y - direction.y * edge.x;
  if (dxe.abs() < 1e-10) return null; // Parallel

  final d = p1 - origin;
  final t = (d.x * edge.y - d.y * edge.x) / dxe;
  final u = (d.x * direction.y - d.y * direction.x) / dxe;

  if (t < 0 || t > maxFraction || u < 0 || u > 1) return null;

  final point = origin + direction * t;
  // Normal is edge perpendicular, facing toward ray origin
  var normal = Vector2(-edge.y, edge.x)..normalize();
  if (normal.dot(direction) > 0) normal = -normal;
  return RayHit(t, point, normal);
}

/// Ray vs OBB (Oriented Bounding Box) intersection.
RayHit? rayVsBox(
    Vector2 origin, Vector2 direction, double maxFraction,
    Vector2 center, Vector2 halfSize, double rotation) {
  // Transform ray into box-local space
  final c = math.cos(-rotation);
  final s = math.sin(-rotation);
  final d = origin - center;
  final localOrigin = Vector2(d.x * c - d.y * s, d.x * s + d.y * c);
  final localDir = Vector2(
      direction.x * c - direction.y * s,
      direction.x * s + direction.y * c);

  var tMin = -double.maxFinite;
  var tMax = double.maxFinite;
  var normalIdx = 0;
  var normalSign = 1.0;

  // X axis
  if (localDir.x.abs() < 1e-10) {
    if (localOrigin.x < -halfSize.x || localOrigin.x > halfSize.x) return null;
  } else {
    final inv = 1.0 / localDir.x;
    var t1 = (-halfSize.x - localOrigin.x) * inv;
    var t2 = (halfSize.x - localOrigin.x) * inv;
    var sign = -1.0;
    if (t1 > t2) { final tmp = t1; t1 = t2; t2 = tmp; sign = 1.0; }
    if (t1 > tMin) { tMin = t1; normalIdx = 0; normalSign = sign; }
    tMax = math.min(tMax, t2);
    if (tMin > tMax) return null;
  }

  // Y axis
  if (localDir.y.abs() < 1e-10) {
    if (localOrigin.y < -halfSize.y || localOrigin.y > halfSize.y) return null;
  } else {
    final inv = 1.0 / localDir.y;
    var t1 = (-halfSize.y - localOrigin.y) * inv;
    var t2 = (halfSize.y - localOrigin.y) * inv;
    var sign = -1.0;
    if (t1 > t2) { final tmp = t1; t1 = t2; t2 = tmp; sign = 1.0; }
    if (t1 > tMin) { tMin = t1; normalIdx = 1; normalSign = sign; }
    tMax = math.min(tMax, t2);
    if (tMin > tMax) return null;
  }

  if (tMin < 0) tMin = 0;
  if (tMin > maxFraction) return null;

  final point = origin + direction * tMin;

  // Compute world-space normal from local-space normal
  final cR = math.cos(rotation);
  final sR = math.sin(rotation);
  Vector2 normal;
  if (normalIdx == 0) {
    normal = Vector2(cR * normalSign, sR * normalSign);
  } else {
    normal = Vector2(-sR * normalSign, cR * normalSign);
  }

  return RayHit(tMin, point, normal);
}

/// Ray vs convex polygon intersection.
RayHit? rayVsPolygon(
    Vector2 origin, Vector2 direction, double maxFraction,
    Vector2 center, List<Vector2> localVertices, double rotation) {
  if (localVertices.length < 3) return null;

  final c = math.cos(rotation);
  final s = math.sin(rotation);

  // Transform vertices to world space
  final verts = <Vector2>[];
  for (final lv in localVertices) {
    verts.add(Vector2(
      lv.x * c - lv.y * s + center.x,
      lv.x * s + lv.y * c + center.y,
    ));
  }

  RayHit? best;
  for (var i = 0; i < verts.length; i++) {
    final j = (i + 1) % verts.length;
    final hit = rayVsSegment(origin, direction, maxFraction, verts[i], verts[j]);
    if (hit != null && (best == null || hit.fraction < best.fraction)) {
      best = hit;
    }
  }
  return best;
}

/// Ray vs capsule intersection.
RayHit? rayVsCapsule(
    Vector2 origin, Vector2 direction, double maxFraction,
    Vector2 center, Vector2 size, int capsuleDirection, double rotation) {
  final hx = size.x * 0.5;
  final hy = size.y * 0.5;
  final radius = capsuleDirection == 0 ? hx : hy;
  final halfLen = capsuleDirection == 0 ? hy - radius : hx - radius;

  // Capsule axis direction
  Vector2 axis;
  if (capsuleDirection == 0) {
    axis = Vector2(-math.sin(rotation), math.cos(rotation));
  } else {
    axis = Vector2(math.cos(rotation), math.sin(rotation));
  }

  final p1 = center + axis * halfLen;
  final p2 = center - axis * halfLen;

  // Test ray against both end circles and the rectangle body
  RayHit? best;

  final h1 = rayVsCircle(origin, direction, maxFraction, p1, radius);
  if (h1 != null) best = h1;

  final h2 = rayVsCircle(origin, direction, maxFraction, p2, radius);
  if (h2 != null && (best == null || h2.fraction < best.fraction)) best = h2;

  // Rectangle part: two side segments
  final perp = Vector2(-axis.y, axis.x) * radius;
  final s1 = rayVsSegment(origin, direction, maxFraction, p1 + perp, p2 + perp);
  if (s1 != null && (best == null || s1.fraction < best.fraction)) best = s1;
  final s2 = rayVsSegment(origin, direction, maxFraction, p2 - perp, p1 - perp);
  if (s2 != null && (best == null || s2.fraction < best.fraction)) best = s2;

  return best;
}
