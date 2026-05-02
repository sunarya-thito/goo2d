import 'dart:math' as math;
import 'package:flutter/painting.dart';
import 'package:goo2d/src/physics/core/physics_body.dart';
import 'package:goo2d/src/physics/core/physics_shape.dart';
import 'package:goo2d/src/physics/core/physics_contact.dart';
import 'package:goo2d/src/physics/core/world/collision/utils.dart';

ContactManifold? checkCirclePolygon(
  PhysicsCircle sA,
  PhysicsBody bA,
  PhysicsPolygon sB,
  PhysicsBody bB,
) {
  final center = getTransformedPoint(sA.localOffset, bA);
  final verts = getTransformedVertices(sB, bB);

  double minOverlap = double.infinity;
  Offset bestAxis = Offset.zero;

  final axes = getPolygonAxes(verts);
  final closestVert = getClosestVertex(center, verts);
  final circleAxis = (center - closestVert);
  if (circleAxis.distanceSquared > 0) {
    axes.add(circleAxis / circleAxis.distance);
  }

  for (final axis in axes) {
    final projA = [
      center.dx * axis.dx + center.dy * axis.dy - sA.radius,
      center.dx * axis.dx + center.dy * axis.dy + sA.radius,
    ];
    final projB = projectPolygon(verts, axis);

    final overlap = math.min(projA[1], projB[1]) - math.max(projA[0], projB[0]);
    if (overlap <= 0) return null;

    if (overlap < minOverlap) {
      minOverlap = overlap;
      bestAxis = axis;
    }
  }

  Offset normal = bestAxis;
  final centerB = getPolygonCenter(verts);
  if ((centerB - center).dx * normal.dx + (centerB - center).dy * normal.dy <
      0) {
    normal *= -1.0;
  }

  return ContactManifold(
    normal: normal,
    depth: minOverlap,
    contactPoint: center + normal * (sA.radius - minOverlap / 2),
  );
}
