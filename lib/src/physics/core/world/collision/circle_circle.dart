import 'dart:math' as math;
import 'package:flutter/painting.dart';
import 'package:goo2d/src/physics/core/physics_body.dart';
import 'package:goo2d/src/physics/core/physics_shape.dart';
import 'package:goo2d/src/physics/core/physics_contact.dart';
import 'package:goo2d/src/physics/core/world/collision/utils.dart';

ContactManifold? checkCircleCircle(
  PhysicsCircle sA,
  PhysicsBody bA,
  PhysicsCircle sB,
  PhysicsBody bB,
) {
  final posA = getTransformedPoint(sA.localOffset, bA);
  final posB = getTransformedPoint(sB.localOffset, bB);
  final delta = posB - posA;
  final distSq = delta.distanceSquared;
  final radiusSum = sA.radius + sB.radius;

  if (distSq > radiusSum * radiusSum) return null;

  final dist = math.sqrt(distSq);
  final normal = dist > 0 ? delta / dist : const Offset(0, 1);
  final depth = radiusSum - dist;

  return ContactManifold(
    normal: normal,
    depth: depth,
    contactPoint: posA + normal * sA.radius,
  );
}
