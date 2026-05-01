import 'dart:math' as math;
import 'package:flutter/painting.dart';
import 'package:goo2d/src/physics/core/physics_body.dart';
import 'package:goo2d/src/physics/core/physics_shape.dart';
import 'package:goo2d/src/physics/core/physics_contact.dart';
import 'package:goo2d/src/physics/core/physics_world.dart';
import 'package:goo2d/src/physics/core/world/collision/narrow_phase.dart';
import 'package:goo2d/src/physics/core/world/collision/utils.dart';

/// Resolves all collisions in the physics world.
void resolveWorldCollisions(PhysicsWorld world, double dt) {
  final allShapesList = world.allShapes.toList();
  for (int i = 0; i < allShapesList.length; i++) {
    for (int j = i + 1; j < allShapesList.length; j++) {
      final sA = allShapesList[i];
      final sB = allShapesList[j];

      final bA = world.bodies[sA.bodyId]!;
      final bB = world.bodies[sB.bodyId]!;

      // Check if we should skip this pair
      if (bA.type == 2 && bB.type == 2) continue; // Static vs Static
      if (bA == bB) continue; // Same body

      final manifold = checkCollision(sA, bA, sB, bB);
      if (manifold != null) {
        bool shouldResolve = true;
        if (sA.isOneWay || sB.isOneWay) {
          shouldResolve = !_shouldSuppressOneWay(sA, bA, sB, bB, manifold);
        }

        double impulseValue = 0.0;
        if (shouldResolve && !sA.isTrigger && !sB.isTrigger) {
          impulseValue = applyImpulse(bA, bB, sA, sB, manifold);
        }

        world.activeContacts.add(
          PhysicsContact(
            shapeAId: sA.id,
            shapeBId: sB.id,
            manifold: manifold,
            impulse: impulseValue,
          ),
        );
      }
    }
  }
}

/// Calculates and applies contact impulses between two bodies.
double applyImpulse(
  PhysicsBody bA,
  PhysicsBody bB,
  PhysicsShape sA,
  PhysicsShape sB,
  ContactManifold manifold,
) {
  final rA = manifold.contactPoint - bA.position;
  final rB = manifold.contactPoint - bB.position;

  final vA = bA.velocity +
      Offset(-bA.angularVelocity * rA.dy, bA.angularVelocity * rA.dx);
  final vB = bB.velocity +
      Offset(-bB.angularVelocity * rB.dy, bB.angularVelocity * rB.dx);
  final relativeVelocity = vB - vA;

  final velocityAlongNormal =
      relativeVelocity.dx * manifold.normal.dx +
      relativeVelocity.dy * manifold.normal.dy;
  if (velocityAlongNormal > 0) return 0.0;

  final raCrossN = rA.dx * manifold.normal.dy - rA.dy * manifold.normal.dx;
  final rbCrossN = rB.dx * manifold.normal.dy - rB.dy * manifold.normal.dx;

  final invMassSum = bA.invMass +
      bB.invMass +
      (raCrossN * raCrossN * bA.invInertia) +
      (rbCrossN * rbCrossN * bB.invInertia);

  if (invMassSum <= 0) return 0.0;

  final e = math.max(sA.bounciness, sB.bounciness);
  final mu = math.sqrt(sA.friction * sB.friction);

  double j = -(1.0 + e) * velocityAlongNormal;
  j /= invMassSum;

  final impulse = manifold.normal * j;
  bA.velocity -= impulse * bA.invMass;
  bA.angularVelocity -= raCrossN * j * bA.invInertia;
  bB.velocity += impulse * bB.invMass;
  bB.angularVelocity += rbCrossN * j * bB.invInertia;

  final tangent = relativeVelocity - manifold.normal * velocityAlongNormal;
  final tangentMag = tangent.distance;
  if (tangentMag > 0.0001) {
    final t = tangent / tangentMag;
    final raCrossT = rA.dx * t.dy - rA.dy * t.dx;
    final rbCrossT = rB.dx * t.dy - rB.dy * t.dx;
    final invMassSumT = bA.invMass +
        bB.invMass +
        (raCrossT * raCrossT * bA.invInertia) +
        (rbCrossT * rbCrossT * bB.invInertia);

    double jt = -relativeVelocity.dx * t.dx - relativeVelocity.dy * t.dy;
    jt /= invMassSumT;

    final maxFriction = j * mu;
    jt = jt.clamp(-maxFriction, maxFriction);

    final frictionImpulse = t * jt;
    bA.velocity -= frictionImpulse * bA.invMass;
    bA.angularVelocity -= raCrossT * jt * bA.invInertia;
    bB.velocity += frictionImpulse * bB.invMass;
    bB.angularVelocity += rbCrossT * jt * bB.invInertia;
  }

  const percent = 0.2;
  const slop = 0.01;
  final correction = manifold.normal *
      (math.max(manifold.depth - slop, 0.0) /
          (bA.invMass + bB.invMass) *
          percent);
  bA.position -= correction * bA.invMass;
  bB.position += correction * bB.invMass;

  return j;
}

bool _shouldSuppressOneWay(PhysicsShape sA, PhysicsBody bA, PhysicsShape sB,
    PhysicsBody bB, ContactManifold manifold) {
  if (sA.isOneWay) {
    if (_isIgnoredByOneWay(sA, bA, sB, bB, manifold)) return true;
  }

  if (sB.isOneWay) {
    // Manifold normal is A -> B. If B is platform, flip normal for check.
    if (_isIgnoredByOneWay(sB, bB, sA, bA, flipManifold(manifold)!)) {
      return true;
    }
  }

  return false;
}

bool _isIgnoredByOneWay(PhysicsShape platform, PhysicsBody pBody,
    PhysicsShape other, PhysicsBody oBody, ContactManifold manifold) {
  // platformNormal points towards the collision side (e.g. up)
  final pNormal =
      Offset(math.cos(platform.oneWayAngle), math.sin(platform.oneWayAngle));

  // Check if objects are moving towards each other from the right side
  final relVel = oBody.velocity - pBody.velocity;
  final velDot = relVel.dx * pNormal.dx + relVel.dy * pNormal.dy;

  // If moving away from the platform normal (i.e. passing through from bottom), ignore.
  // 0.1 threshold to prevent floating point jitter issues.
  if (velDot > 0.1) return true;

  // Angle check: Is the contact normal within the allowed arc?
  final dot =
      manifold.normal.dx * pNormal.dx + manifold.normal.dy * pNormal.dy;
  final angle = math.acos(dot.clamp(-1.0, 1.0));

  if (angle > platform.oneWayArc / 2.0) return true;

  return false;
}
