import 'dart:math' as math;
import 'package:flutter/painting.dart';
import 'package:goo2d/src/physics/core/physics_body.dart';
import 'package:goo2d/src/physics/core/physics_shape.dart';
import 'package:goo2d/src/physics/core/physics_contact.dart';
import 'package:goo2d/src/physics/core/world/collision/utils.dart';

/// Checks for collision between two capsules.
ContactManifold? checkCapsuleCapsule(
  PhysicsCapsule sA,
  PhysicsBody bA,
  PhysicsCapsule sB,
  PhysicsBody bB,
) {
  final segA = getCapsuleSegment(sA, bA);
  final segB = getCapsuleSegment(sB, bB);

  final closest = getClosestPointsBetweenSegments(
    segA[0], segA[1], segB[0], segB[1],
  );
  
  final pA = closest[0];
  final pB = closest[1];
  final delta = pB - pA;
  final distSq = delta.distanceSquared;
  final radiusSum = sA.radius + sB.radius;

  if (distSq > radiusSum * radiusSum) return null;

  final dist = math.sqrt(distSq);
  final normal = dist > 0 ? delta / dist : const Offset(0, 1);
  final depth = radiusSum - dist;

  return ContactManifold(
    normal: normal,
    depth: depth,
    contactPoint: pA + normal * sA.radius,
  );
}
