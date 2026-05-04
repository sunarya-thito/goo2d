import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/src/physics/worker/engine/collision/aabb.dart';
import 'package:goo2d/src/physics/worker/engine/physics_collider.dart';
import 'package:goo2d/src/physics/worker/engine/physics_body.dart';
import 'package:goo2d/src/physics/worker/data/collider_shape_type.dart';

/// Computes AABB for a collider in world space.
AABB computeColliderAABB(PhysicsCollider collider, PhysicsBody body) {
  final pos = body.position + collider.offset;
  final rot = body.rotation * math.pi / 180.0;

  switch (collider.shapeType) {
    case ColliderShapeType.circle:
      final r = collider.circleRadius;
      return AABB(pos.x - r, pos.y - r, pos.x + r, pos.y + r);

    case ColliderShapeType.box:
      return _boxAABB(pos, collider.boxSize, rot);

    case ColliderShapeType.capsule:
      return _capsuleAABB(pos, collider.capsuleSize, collider.capsuleDirection, rot);

    case ColliderShapeType.polygon:
      return _polygonAABB(pos, collider.polygonPoints, rot);

    case ColliderShapeType.edge:
      return _edgeAABB(pos, collider.edgePoints, rot);

    case ColliderShapeType.composite:
      // Composite uses its child colliders; fallback to box-like
      return _boxAABB(pos, collider.boxSize, rot);
  }
}

AABB _boxAABB(Vector2 center, Vector2 size, double rot) {
  final hx = size.x * 0.5;
  final hy = size.y * 0.5;
  final c = math.cos(rot).abs();
  final s = math.sin(rot).abs();
  final ex = hx * c + hy * s;
  final ey = hx * s + hy * c;
  return AABB(center.x - ex, center.y - ey, center.x + ex, center.y + ey);
}

AABB _capsuleAABB(Vector2 center, Vector2 size, int direction, double rot) {
  final hx = size.x * 0.5;
  final hy = size.y * 0.5;
  final radius = direction == 0 ? hx : hy;
  final halfLen = direction == 0 ? hy - radius : hx - radius;

  // Two end-cap centers
  Vector2 dir;
  if (direction == 0) {
    // Vertical
    dir = Vector2(-math.sin(rot) * halfLen, math.cos(rot) * halfLen);
  } else {
    // Horizontal
    dir = Vector2(math.cos(rot) * halfLen, math.sin(rot) * halfLen);
  }

  final p1 = center + dir;
  final p2 = center - dir;
  final aabb = AABB(
    math.min(p1.x, p2.x), math.min(p1.y, p2.y),
    math.max(p1.x, p2.x), math.max(p1.y, p2.y),
  );
  aabb.expand(radius);
  return aabb;
}

AABB _polygonAABB(Vector2 center, List<Vector2> points, double rot) {
  if (points.isEmpty) return AABB(center.x, center.y, center.x, center.y);

  final c = math.cos(rot);
  final s = math.sin(rot);

  var p = points[0];
  var wx = p.x * c - p.y * s + center.x;
  var wy = p.x * s + p.y * c + center.y;
  final aabb = AABB(wx, wy, wx, wy);

  for (var i = 1; i < points.length; i++) {
    p = points[i];
    wx = p.x * c - p.y * s + center.x;
    wy = p.x * s + p.y * c + center.y;
    aabb.encapsulate(wx, wy);
  }
  return aabb;
}

AABB _edgeAABB(Vector2 center, List<Vector2> points, double rot) {
  return _polygonAABB(center, points, rot);
}
