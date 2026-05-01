import 'dart:math' as math;
import 'package:flutter/painting.dart';
import 'package:goo2d/src/physics/core/physics_body.dart';
import 'package:goo2d/src/physics/core/physics_shape.dart';
import 'package:goo2d/src/physics/core/physics_raycast_hit.dart';
import 'package:goo2d/src/physics/core/physics_world.dart';
import 'package:goo2d/src/physics/core/world/collision/utils.dart';

/// Performs a spatial query for ray intersections in the world.
PhysicsRaycastHit? raycastWorld(
  PhysicsWorld world,
  Offset origin,
  Offset direction,
  double maxDistance,
) {
  PhysicsRaycastHit? closestHit;

  for (final shape in world.allShapes) {
    final body = world.bodies[shape.bodyId]!;
    PhysicsRaycastHit? hit;

    if (shape is PhysicsCircle) {
      hit = raycastCircle(shape, body, origin, direction, maxDistance);
    } else if (shape is PhysicsBox) {
      hit = raycastPolygon(
        boxToPolygon(shape, body),
        body,
        origin,
        direction,
        maxDistance,
      );
    } else if (shape is PhysicsPolygon) {
      hit = raycastPolygon(shape, body, origin, direction, maxDistance);
    }

    if (hit != null) {
      if (closestHit == null || hit.distance < closestHit.distance) {
        closestHit = hit;
      }
    }
  }

  return closestHit;
}

PhysicsRaycastHit? raycastCircle(
  PhysicsCircle circle,
  PhysicsBody body,
  Offset origin,
  Offset direction,
  double maxDistance,
) {
  final center = getTransformedPoint(circle.localOffset, body);
  final L = center - origin;
  final tca = L.dx * direction.dx + L.dy * direction.dy;
  if (tca < 0) return null;

  final d2 = L.dx * L.dx + L.dy * L.dy - tca * tca;
  final r2 = circle.radius * circle.radius;
  if (d2 > r2) return null;

  final thc = math.sqrt(r2 - d2);
  final t0 = tca - thc;

  if (t0 < 0 || t0 > maxDistance) return null;

  final point = origin + direction * t0;
  final normal = (point - center) / circle.radius;

  return PhysicsRaycastHit(
    shapeId: circle.id,
    point: point,
    normal: normal,
    distance: t0,
    fraction: t0 / maxDistance,
  );
}

PhysicsRaycastHit? raycastPolygon(
  PhysicsPolygon poly,
  PhysicsBody body,
  Offset origin,
  Offset direction,
  double maxDistance,
) {
  final verts = getTransformedVertices(poly, body);
  double minT = double.infinity;
  Offset bestNormal = Offset.zero;

  for (int i = 0; i < verts.length; i++) {
    final p1 = verts[i];
    final p2 = verts[(i + 1) % verts.length];

    final v1 = origin - p1;
    final v2 = p2 - p1;
    final v3 = Offset(-direction.dy, direction.dx);

    final dot = v2.dx * v3.dx + v2.dy * v3.dy;
    if (dot.abs() < 0.000001) continue;

    final t1 = (v2.dx * v1.dy - v2.dy * v1.dx) / dot;
    final t2 = (v1.dx * v3.dx + v1.dy * v3.dy) / dot;

    if (t1 >= 0 && t1 <= maxDistance && t2 >= 0 && t2 <= 1) {
      if (t1 < minT) {
        minT = t1;
        final edge = p2 - p1;
        final dist = edge.distance;
        if (dist > 0.000001) {
          bestNormal = Offset(-edge.dy, edge.dx) / dist;
          if (bestNormal.dx * direction.dx + bestNormal.dy * direction.dy > 0) {
            bestNormal *= -1.0;
          }
        }
      }
    }
  }

  if (minT == double.infinity) return null;

  return PhysicsRaycastHit(
    shapeId: poly.id,
    point: origin + direction * minT,
    normal: bestNormal,
    distance: minT,
    fraction: minT / maxDistance,
  );
}
