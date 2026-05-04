import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/src/physics/worker/engine/physics_collider.dart';
import 'package:goo2d/src/physics/worker/engine/physics_body.dart';
import 'package:goo2d/src/physics/worker/engine/collision/aabb.dart';
import 'package:goo2d/src/physics/worker/engine/collision/aabb_compute.dart';
import 'package:goo2d/src/physics/worker/data/collider_shape_type.dart';

/// Tests whether a point overlaps a collider in world space.
bool pointInCollider(Vector2 point, PhysicsCollider collider, PhysicsBody body) {
  final local = _toLocal(point, body, collider);

  switch (collider.shapeType) {
    case ColliderShapeType.circle:
      return local.length2 <= collider.circleRadius * collider.circleRadius;
    case ColliderShapeType.box:
      final hx = collider.boxSize.x * 0.5;
      final hy = collider.boxSize.y * 0.5;
      return local.x.abs() <= hx && local.y.abs() <= hy;
    case ColliderShapeType.capsule:
      return _pointInCapsule(local, collider.capsuleSize, collider.capsuleDirection);
    case ColliderShapeType.polygon:
      return _pointInConvex(local, collider.polygonPoints);
    case ColliderShapeType.edge:
      return false; // Edges have no area
    case ColliderShapeType.composite:
      return false; // Handled via sub-colliders
  }
}

/// Finds the closest point on a collider to a given world position.
Vector2 closestPointOnCollider(Vector2 point, PhysicsCollider collider, PhysicsBody body) {
  final local = _toLocal(point, body, collider);
  final localResult = _closestLocal(local, collider);
  return _toWorld(localResult, body, collider);
}

Vector2 _closestLocal(Vector2 local, PhysicsCollider collider) {
  switch (collider.shapeType) {
    case ColliderShapeType.circle:
      final dist = local.length;
      if (dist < 1e-10) return Vector2(collider.circleRadius, 0);
      return local * (collider.circleRadius / dist);

    case ColliderShapeType.box:
      final hx = collider.boxSize.x * 0.5;
      final hy = collider.boxSize.y * 0.5;
      return Vector2(
        local.x.clamp(-hx, hx),
        local.y.clamp(-hy, hy),
      );

    case ColliderShapeType.capsule:
      return _closestOnCapsule(local, collider.capsuleSize, collider.capsuleDirection);

    case ColliderShapeType.polygon:
      return _closestOnPolygon(local, collider.polygonPoints);

    case ColliderShapeType.edge:
      return _closestOnEdge(local, collider.edgePoints);

    case ColliderShapeType.composite:
      return local.clone(); // Fallback
  }
}

/// Tests if a circle overlaps a collider.
bool circleOverlapsCollider(
    Vector2 center, double radius, PhysicsCollider collider, PhysicsBody body) {
  final closest = closestPointOnCollider(center, collider, body);
  return (closest - center).length2 <= radius * radius;
}

/// Tests if an OBB overlaps a collider (conservative via AABB).
bool boxOverlapsCollider(
    Vector2 center, Vector2 size, double angle,
    PhysicsCollider collider, PhysicsBody body) {
  // AABB-based conservative test
  final queryAABB = _rotatedBoxAABB(center, size, angle);
  final colliderAABB = computeColliderAABB(collider, body);
  return queryAABB.overlaps(colliderAABB);
}

// ===================== Helpers =====================

Vector2 _toLocal(Vector2 world, PhysicsBody body, PhysicsCollider collider) {
  final rot = -body.rotation * math.pi / 180.0;
  final c = math.cos(rot);
  final s = math.sin(rot);
  final d = world - body.position - collider.offset;
  return Vector2(d.x * c - d.y * s, d.x * s + d.y * c);
}

Vector2 _toWorld(Vector2 local, PhysicsBody body, PhysicsCollider collider) {
  final rot = body.rotation * math.pi / 180.0;
  final c = math.cos(rot);
  final s = math.sin(rot);
  return Vector2(
    local.x * c - local.y * s + body.position.x + collider.offset.x,
    local.x * s + local.y * c + body.position.y + collider.offset.y,
  );
}

bool _pointInCapsule(Vector2 local, Vector2 size, int direction) {
  final hx = size.x * 0.5;
  final hy = size.y * 0.5;
  final radius = direction == 0 ? hx : hy;
  final halfLen = direction == 0 ? hy - radius : hx - radius;

  // Project onto capsule axis
  final axisComp = direction == 0 ? local.y : local.x;
  final perpComp = direction == 0 ? local.x : local.y;
  final clamped = axisComp.clamp(-halfLen, halfLen);
  final closest = direction == 0
      ? Vector2(0, clamped)
      : Vector2(clamped, 0);
  return (local - closest).length2 <= radius * radius;
}

bool _pointInConvex(Vector2 point, List<Vector2> verts) {
  if (verts.length < 3) return false;
  for (var i = 0; i < verts.length; i++) {
    final j = (i + 1) % verts.length;
    final edge = verts[j] - verts[i];
    final toP = point - verts[i];
    if (edge.x * toP.y - edge.y * toP.x < 0) return false;
  }
  return true;
}

Vector2 _closestOnCapsule(Vector2 local, Vector2 size, int direction) {
  final hx = size.x * 0.5;
  final hy = size.y * 0.5;
  final radius = direction == 0 ? hx : hy;
  final halfLen = direction == 0 ? hy - radius : hx - radius;

  final axisComp = direction == 0 ? local.y : local.x;
  final clamped = axisComp.clamp(-halfLen, halfLen);
  final center = direction == 0 ? Vector2(0, clamped) : Vector2(clamped, 0);
  final diff = local - center;
  final dist = diff.length;
  if (dist < 1e-10) return center + Vector2(radius, 0);
  return center + diff * (radius / dist);
}

Vector2 _closestOnPolygon(Vector2 point, List<Vector2> verts) {
  if (verts.isEmpty) return point.clone();
  var bestDist = double.maxFinite;
  var best = verts[0];

  for (var i = 0; i < verts.length; i++) {
    final j = (i + 1) % verts.length;
    final cp = _closestOnSegment(point, verts[i], verts[j]);
    final d = (cp - point).length2;
    if (d < bestDist) { bestDist = d; best = cp; }
  }
  return best;
}

Vector2 _closestOnEdge(Vector2 point, List<Vector2> verts) {
  return _closestOnPolygon(point, verts);
}

Vector2 _closestOnSegment(Vector2 point, Vector2 a, Vector2 b) {
  final ab = b - a;
  final len2 = ab.length2;
  if (len2 < 1e-10) return a.clone();
  final t = ((point - a).dot(ab) / len2).clamp(0.0, 1.0);
  return a + ab * t;
}

AABB _rotatedBoxAABB(Vector2 center, Vector2 size, double angle) {
  final hx = size.x * 0.5;
  final hy = size.y * 0.5;
  final c = math.cos(angle).abs();
  final s = math.sin(angle).abs();
  final ex = hx * c + hy * s;
  final ey = hx * s + hy * c;
  return AABB(center.x - ex, center.y - ey, center.x + ex, center.y + ey);
}
