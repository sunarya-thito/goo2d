import 'package:flutter/painting.dart';
import 'package:goo2d/src/physics/core/physics_body.dart';
import 'package:goo2d/src/physics/core/physics_shape.dart';
import 'package:goo2d/src/physics/core/physics_contact.dart';
import 'package:goo2d/src/physics/core/world/collision/utils.dart';

ContactManifold? checkBoxBox(
  PhysicsBox sA,
  PhysicsBody bA,
  PhysicsBox sB,
  PhysicsBody bB,
) {
  final posA = getTransformedPoint(sA.localOffset, bA);
  final posB = getTransformedPoint(sB.localOffset, bB);

  final axesA = getBoxAxes(bA.rotation);
  final axesB = getBoxAxes(bB.rotation);

  final halfA = [sA.size.width / 2, sA.size.height / 2];
  final halfB = [sB.size.width / 2, sB.size.height / 2];

  double minOverlap = double.infinity;
  Offset bestAxis = Offset.zero;

  final axes = [...axesA, ...axesB];
  for (final axis in axes) {
    final overlap = getOverlap(posA, axesA, halfA, posB, axesB, halfB, axis);
    if (overlap <= 0) return null;
    if (overlap < minOverlap) {
      minOverlap = overlap;
      bestAxis = axis;
    }
  }

  Offset normal = bestAxis;
  if ((posB - posA).dx * normal.dx + (posB - posA).dy * normal.dy < 0) {
    normal *= -1.0;
  }

  return ContactManifold(
    normal: normal,
    depth: minOverlap,
    contactPoint: posA + normal * (halfA[0] + minOverlap / 2),
  );
}
