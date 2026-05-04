import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/src/physics/worker/engine/physics_engine.dart';
import 'package:goo2d/src/physics/worker/engine/physics_body.dart';
import 'package:goo2d/src/physics/worker/engine/physics_collider.dart';
import 'package:goo2d/src/physics/worker/engine/collision/broadphase.dart';
import 'package:goo2d/src/physics/worker/engine/collision/shape_intersect.dart';
import 'package:goo2d/src/physics/worker/data/collider_shape_type.dart';

/// A fully resolved collision contact.
class NarrowphaseContact {
  final int colliderA;
  final int colliderB;
  final int bodyA;
  final int bodyB;
  final ContactManifold manifold;

  const NarrowphaseContact({
    required this.colliderA,
    required this.colliderB,
    required this.bodyA,
    required this.bodyB,
    required this.manifold,
  });
}

/// Runs narrowphase detection on broadphase pairs.
List<NarrowphaseContact> resolveNarrowphase(
    PhysicsEngine engine, List<BroadphasePair> pairs) {
  final contacts = <NarrowphaseContact>[];

  for (final pair in pairs) {
    final cA = engine.colliders[pair.colliderA];
    final cB = engine.colliders[pair.colliderB];
    if (cA == null || cB == null) continue;

    final bA = engine.bodies[cA.bodyHandle];
    final bB = engine.bodies[cB.bodyHandle];
    if (bA == null || bB == null) continue;

    final manifold = _testShapes(cA, bA, cB, bB);
    if (manifold != null && manifold.contacts.isNotEmpty) {
      contacts.add(NarrowphaseContact(
        colliderA: pair.colliderA,
        colliderB: pair.colliderB,
        bodyA: cA.bodyHandle,
        bodyB: cB.bodyHandle,
        manifold: manifold,
      ));
    }
  }

  return contacts;
}

ContactManifold? _testShapes(
    PhysicsCollider cA, PhysicsBody bA,
    PhysicsCollider cB, PhysicsBody bB) {
  final typeA = cA.shapeType;
  final typeB = cB.shapeType;

  // Both circles
  if (typeA == ColliderShapeType.circle && typeB == ColliderShapeType.circle) {
    return circleVsCircle(
      _worldCenter(bA, cA), cA.circleRadius,
      _worldCenter(bB, cB), cB.circleRadius,
    );
  }

  // Circle vs convex (box/polygon)
  if (typeA == ColliderShapeType.circle && _isConvex(typeB)) {
    return circleVsPolygon(
      _worldCenter(bA, cA), cA.circleRadius,
      _worldVertices(cB, bB),
    );
  }
  if (_isConvex(typeA) && typeB == ColliderShapeType.circle) {
    final m = circleVsPolygon(
      _worldCenter(bB, cB), cB.circleRadius,
      _worldVertices(cA, bA),
    );
    return m != null ? ContactManifold(-m.normal, m.contacts) : null;
  }

  // Convex vs Convex (box, polygon)
  if (_isConvex(typeA) && _isConvex(typeB)) {
    return polygonVsPolygon(
      _worldVertices(cA, bA),
      _worldVertices(cB, bB),
    );
  }

  // Capsule — decompose into circle + box (simplified)
  if (typeA == ColliderShapeType.capsule || typeB == ColliderShapeType.capsule) {
    // Conservative: treat capsule as its bounding polygon
    return polygonVsPolygon(
      _worldVertices(cA, bA),
      _worldVertices(cB, bB),
    );
  }

  return null; // Edge/composite not yet handled in narrowphase
}

bool _isConvex(ColliderShapeType type) =>
    type == ColliderShapeType.box || type == ColliderShapeType.polygon;

Vector2 _worldCenter(PhysicsBody body, PhysicsCollider collider) {
  final rot = body.rotation * math.pi / 180.0;
  final c = math.cos(rot);
  final s = math.sin(rot);
  final o = collider.offset;
  return Vector2(
    o.x * c - o.y * s + body.position.x,
    o.x * s + o.y * c + body.position.y,
  );
}

/// Converts collider vertices to world space.
List<Vector2> _worldVertices(PhysicsCollider collider, PhysicsBody body) {
  final rot = body.rotation * math.pi / 180.0;
  final c = math.cos(rot);
  final s = math.sin(rot);
  final cx = body.position.x + collider.offset.x;
  final cy = body.position.y + collider.offset.y;

  final localVerts = _getLocalVertices(collider);
  return [
    for (final v in localVerts)
      Vector2(v.x * c - v.y * s + cx, v.x * s + v.y * c + cy),
  ];
}

/// Gets local-space vertices for convex shapes.
List<Vector2> _getLocalVertices(PhysicsCollider collider) {
  switch (collider.shapeType) {
    case ColliderShapeType.box:
      final hx = collider.boxSize.x * 0.5;
      final hy = collider.boxSize.y * 0.5;
      return [
        Vector2(-hx, -hy), Vector2(hx, -hy),
        Vector2(hx, hy), Vector2(-hx, hy),
      ];
    case ColliderShapeType.polygon:
      return collider.polygonPoints;
    case ColliderShapeType.capsule:
      // Approximate capsule as an 8-sided polygon
      return _capsulePolygon(collider.capsuleSize, collider.capsuleDirection);
    case ColliderShapeType.circle:
      // Approximate circle as 8-gon for polygon tests
      final r = collider.circleRadius;
      return [for (var i = 0; i < 8; i++)
        Vector2(r * math.cos(i * math.pi / 4), r * math.sin(i * math.pi / 4))];
    default:
      return [];
  }
}

List<Vector2> _capsulePolygon(Vector2 size, int direction) {
  final hx = size.x * 0.5;
  final hy = size.y * 0.5;
  final r = direction == 0 ? hx : hy;
  final halfLen = direction == 0 ? hy - r : hx - r;
  final verts = <Vector2>[];

  // Top semicircle
  for (var i = 0; i <= 4; i++) {
    final angle = math.pi * i / 4;
    if (direction == 0) {
      verts.add(Vector2(r * math.cos(angle), halfLen + r * math.sin(angle)));
    } else {
      verts.add(Vector2(halfLen + r * math.cos(angle), r * math.sin(angle)));
    }
  }
  // Bottom semicircle
  for (var i = 0; i <= 4; i++) {
    final angle = math.pi + math.pi * i / 4;
    if (direction == 0) {
      verts.add(Vector2(r * math.cos(angle), -halfLen + r * math.sin(angle)));
    } else {
      verts.add(Vector2(-halfLen + r * math.cos(angle), r * math.sin(angle)));
    }
  }
  return verts;
}
