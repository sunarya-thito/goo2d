import 'dart:math' as math;
import 'package:flutter/painting.dart';
import 'package:goo2d/src/physics/core/physics_body.dart';
import 'package:goo2d/src/physics/core/physics_shape.dart';
import 'package:goo2d/src/physics/core/physics_contact.dart';
import 'package:goo2d/src/physics/core/world/collision/utils.dart';

ContactManifold? checkPolygonPolygon(
  PhysicsPolygon sA,
  PhysicsBody bA,
  PhysicsPolygon sB,
  PhysicsBody bB,
) {
  final vertsA = getTransformedVertices(sA, bA);
  final vertsB = getTransformedVertices(sB, bB);

  double minOverlap = double.infinity;
  Offset bestAxis = Offset.zero;

  final axes = [...getPolygonAxes(vertsA), ...getPolygonAxes(vertsB)];
  for (final axis in axes) {
    final projA = projectPolygon(vertsA, axis);
    final projB = projectPolygon(vertsB, axis);

    final overlap = math.min(projA[1], projB[1]) - math.max(projA[0], projB[0]);
    if (overlap <= 0) return null;

    if (overlap < minOverlap) {
      minOverlap = overlap;
      bestAxis = axis;
    }
  }

  Offset normal = bestAxis;
  final centerA = getPolygonCenter(vertsA);
  final centerB = getPolygonCenter(vertsB);
  if ((centerB - centerA).dx * normal.dx + (centerB - centerA).dy * normal.dy <
      0) {
    normal *= -1.0;
  }

  return ContactManifold(
    normal: normal,
    depth: minOverlap,
    contactPoint: centerA + normal * (minOverlap / 2),
  );
}
