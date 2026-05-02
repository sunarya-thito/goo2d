import 'dart:math' as math;
import 'package:flutter/painting.dart';
import 'package:goo2d/src/physics/core/physics_body.dart';
import 'package:goo2d/src/physics/core/physics_shape.dart';
import 'package:goo2d/src/physics/core/physics_contact.dart';
import 'package:goo2d/src/physics/core/world/collision/utils.dart';

ContactManifold? checkCapsulePolygon(
  PhysicsCapsule sA,
  PhysicsBody bA,
  PhysicsPolygon sB,
  PhysicsBody bB,
) {
  final segment = getCapsuleSegment(sA, bA);
  final vertices = getTransformedVertices(sB, bB);

  // Find the point on the polygon closest to the capsule segment
  double minDistSq = double.infinity;
  Offset closestOnSeg = Offset.zero;
  Offset closestOnPoly = Offset.zero;

  // Check segment endpoints against polygon edges
  for (final endpoint in segment) {
    for (int i = 0; i < vertices.length; i++) {
      final p1 = vertices[i];
      final p2 = vertices[(i + 1) % vertices.length];
      final p = getClosestPointOnSegment(endpoint, p1, p2);
      final distSq = (endpoint - p).distanceSquared;
      if (distSq < minDistSq) {
        minDistSq = distSq;
        closestOnSeg = endpoint;
        closestOnPoly = p;
      }
    }
  }

  // Check polygon vertices against capsule segment
  for (final vertex in vertices) {
    final p = getClosestPointOnSegment(vertex, segment[0], segment[1]);
    final distSq = (vertex - p).distanceSquared;
    if (distSq < minDistSq) {
      minDistSq = distSq;
      closestOnSeg = p;
      closestOnPoly = vertex;
    }
  }

  // Check for intersection
  final radius = sA.radius;
  if (minDistSq > radius * radius) {
    // We also need to check if the segment is fully inside the polygon
    if (containsPoint(getPolygonCenter(vertices), segment[0], segment[1], 0)) {
      // This is a simplification. For SAT, we'd need more work.
    }
    return null;
  }

  final dist = math.sqrt(minDistSq);
  final delta = closestOnPoly - closestOnSeg;
  final normal = dist > 1e-6 ? delta / dist : const Offset(0, 1);
  final depth = radius - dist;

  return ContactManifold(
    normal: normal,
    depth: depth,
    contactPoint: closestOnSeg + normal * radius,
  );
}

bool containsPoint(Offset p, Offset a, Offset b, double radius) {
  // Helper to check if a point is inside a thickened segment (capsule)
  final closest = getClosestPointOnSegment(p, a, b);
  return (p - closest).distanceSquared <= radius * radius;
}
