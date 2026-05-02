import 'dart:math' as math;
import 'package:flutter/painting.dart';
import 'package:goo2d/src/physics/core/physics_body.dart';
import 'package:goo2d/src/physics/core/physics_shape.dart';
import 'package:goo2d/src/physics/core/physics_contact.dart';
import 'package:goo2d/src/physics/core/world/collision/utils.dart';

ContactManifold? checkCapsuleCircle(
  PhysicsCapsule sA,
  PhysicsBody bA,
  PhysicsCircle sB,
  PhysicsBody bB,
) {
  final segment = getCapsuleSegment(sA, bA);
  final posB = getTransformedPoint(sB.localOffset, bB);

  final closest = getClosestPointOnSegment(posB, segment[0], segment[1]);
  final delta = posB - closest;
  final distSq = delta.distanceSquared;
  final radiusSum = sA.radius + sB.radius;

  if (distSq > radiusSum * radiusSum) return null;

  final dist = math.sqrt(distSq);
  final normal = dist > 0 ? delta / dist : const Offset(0, 1);
  final depth = radiusSum - dist;

  return ContactManifold(
    normal: normal,
    depth: depth,
    contactPoint: closest + normal * sA.radius,
  );
}
