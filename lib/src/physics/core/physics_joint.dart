import 'dart:math' as math;
import 'package:flutter/painting.dart';
import 'package:goo2d/src/physics/core/physics_body.dart';

abstract class Joint {
  final int id;
  final int bodyAId;
  final int bodyBId;

  Joint({
    required this.id,
    required this.bodyAId,
    required this.bodyBId,
  });
  void solveVelocityConstraints(Map<int, PhysicsBody> bodies, double dt);
  void solvePositionConstraints(Map<int, PhysicsBody> bodies) {}
}

class DistanceJoint extends Joint {
  final Offset anchorA;
  final Offset anchorB;
  double length;

  DistanceJoint({
    required super.id,
    required super.bodyAId,
    required super.bodyBId,
    required this.anchorA,
    required this.anchorB,
    required this.length,
  });

  @override
  void solveVelocityConstraints(Map<int, PhysicsBody> bodies, double dt) {
    final bA = bodies[bodyAId];
    final bB = bodies[bodyBId];
    if (bA == null || bB == null) return;

    final rA = _rotate(anchorA, bA.rotation);
    final rB = _rotate(anchorB, bB.rotation);

    final pA = bA.position + rA;
    final pB = bB.position + rB;

    final delta = pB - pA;
    final dist = delta.distance;
    if (dist < 0.00001) return;

    final normal = delta / dist;

    // Relative velocity
    final vA =
        bA.velocity +
        Offset(-bA.angularVelocity * rA.dy, bA.angularVelocity * rA.dx);
    final vB =
        bB.velocity +
        Offset(-bB.angularVelocity * rB.dy, bB.angularVelocity * rB.dx);
    final relVel = vB - vA;

    final velAlongNormal = relVel.dx * normal.dx + relVel.dy * normal.dy;

    // Position correction (Baumgarte)
    const biasFactor = 0.2;
    final bias = -(biasFactor / dt) * (dist - length);

    final invMassSum =
        bA.invMass +
        bB.invMass +
        _cross(rA, normal) * _cross(rA, normal) * bA.invInertia +
        _cross(rB, normal) * _cross(rB, normal) * bB.invInertia;

    if (invMassSum <= 0) return;

    final impulseMag = (-(velAlongNormal) + bias) / invMassSum;
    final impulse = normal * impulseMag;

    bA.velocity -= impulse * bA.invMass;
    bA.angularVelocity -= _cross(rA, impulse) * bA.invInertia;
    bB.velocity += impulse * bB.invMass;
    bB.angularVelocity += _cross(rB, impulse) * bB.invInertia;
  }
}

class HingeJoint extends Joint {
  final Offset anchorA;
  final Offset anchorB;

  HingeJoint({
    required super.id,
    required super.bodyAId,
    required super.bodyBId,
    required this.anchorA,
    required this.anchorB,
  });

  @override
  void solveVelocityConstraints(Map<int, PhysicsBody> bodies, double dt) {
    final bA = bodies[bodyAId];
    final bB = bodies[bodyBId];
    if (bA == null || bB == null) return;

    final rA = _rotate(anchorA, bA.rotation);
    final rB = _rotate(anchorB, bB.rotation);

    final pA = bA.position + rA;
    final pB = bB.position + rB;

    final delta = pB - pA;

    // Relative velocity
    final vA =
        bA.velocity +
        Offset(-bA.angularVelocity * rA.dy, bA.angularVelocity * rA.dx);
    final vB =
        bB.velocity +
        Offset(-bB.angularVelocity * rB.dy, bB.angularVelocity * rB.dx);
    final relVel = vB - vA;

    // We want relVel to be 0 to correct the position error
    const biasFactor = 0.2;
    final bias = delta * -(biasFactor / dt);

    // Simplification: Solve X and Y separately or as a 2x2 system.
    // Here we use a simpler iterative impulse approach.

    _applyImpulse(
      bA,
      bB,
      rA,
      rB,
      Offset(relVel.dx - bias.dx, relVel.dy - bias.dy),
    );
  }

  void _applyImpulse(
    PhysicsBody bA,
    PhysicsBody bB,
    Offset rA,
    Offset rB,
    Offset targetVel,
  ) {
    // This is a simplified point-to-point constraint solver
    final invMassSumX =
        bA.invMass +
        bB.invMass +
        (rA.dy * rA.dy * bA.invInertia) +
        (rB.dy * rB.dy * bB.invInertia);
    final invMassSumY =
        bA.invMass +
        bB.invMass +
        (rA.dx * rA.dx * bA.invInertia) +
        (rB.dx * rB.dx * bB.invInertia);

    if (invMassSumX > 0) {
      final impulseX = -targetVel.dx / invMassSumX;
      bA.velocity -= Offset(impulseX * bA.invMass, 0);
      bA.angularVelocity -=
          rA.dx * 0 - rA.dy * impulseX * bA.invInertia; // Cross product check
      bB.velocity += Offset(impulseX * bB.invMass, 0);
      bB.angularVelocity += rB.dx * 0 - rB.dy * impulseX * bB.invInertia;
    }

    if (invMassSumY > 0) {
      final impulseY = -targetVel.dy / invMassSumY;
      bA.velocity -= Offset(0, impulseY * bA.invMass);
      bA.angularVelocity -= rA.dx * impulseY - rA.dy * 0 * bA.invInertia;
      bB.velocity += Offset(0, impulseY * bB.invMass);
      bB.angularVelocity += rB.dx * impulseY - rB.dy * 0 * bB.invInertia;
    }
  }
}

class SpringJoint extends Joint {
  final Offset anchorA;
  final Offset anchorB;
  double restLength;
  double stiffness;
  double damping;

  SpringJoint({
    required super.id,
    required super.bodyAId,
    required super.bodyBId,
    required this.anchorA,
    required this.anchorB,
    required this.restLength,
    required this.stiffness,
    required this.damping,
  });

  @override
  void solveVelocityConstraints(Map<int, PhysicsBody> bodies, double dt) {
    final bA = bodies[bodyAId];
    final bB = bodies[bodyBId];
    if (bA == null || bB == null) return;

    final rA = _rotate(anchorA, bA.rotation);
    final rB = _rotate(anchorB, bB.rotation);

    final pA = bA.position + rA;
    final pB = bB.position + rB;

    final delta = pB - pA;
    final dist = delta.distance;
    if (dist < 0.00001) return;

    final normal = delta / dist;

    final vA =
        bA.velocity +
        Offset(-bA.angularVelocity * rA.dy, bA.angularVelocity * rA.dx);
    final vB =
        bB.velocity +
        Offset(-bB.angularVelocity * rB.dy, bB.angularVelocity * rB.dx);
    final relVel = vB - vA;

    final velAlongNormal = relVel.dx * normal.dx + relVel.dy * normal.dy;

    final springForce = (dist - restLength) * stiffness;
    final dampingForce = velAlongNormal * damping;
    final totalForce = springForce + dampingForce;

    final impulseMag = totalForce * dt;
    final impulse = normal * impulseMag;

    bA.velocity += impulse * bA.invMass; // Spring pulls/pushes
    bA.angularVelocity += _cross(rA, impulse) * bA.invInertia;
    bB.velocity -= impulse * bB.invMass;
    bB.angularVelocity -= _cross(rB, impulse) * bB.invInertia;
  }
}

class SliderJoint extends Joint {
  final Offset anchorA;
  final Offset anchorB;
  final Offset axis; // In bodyA's local space

  SliderJoint({
    required super.id,
    required super.bodyAId,
    required super.bodyBId,
    required this.anchorA,
    required this.anchorB,
    required this.axis,
  });

  @override
  void solveVelocityConstraints(Map<int, PhysicsBody> bodies, double dt) {
    final bA = bodies[bodyAId];
    final bB = bodies[bodyBId];
    if (bA == null || bB == null) return;

    final worldAxis = _rotate(axis, bA.rotation);
    final worldNormal = Offset(-worldAxis.dy, worldAxis.dx);

    final rA = _rotate(anchorA, bA.rotation);
    final rB = _rotate(anchorB, bB.rotation);

    final pA = bA.position + rA;
    final pB = bB.position + rB;

    final delta = pB - pA;

    // 1. Constrain rotation (Slider usually locks rotation unless specified)
    final angularError = bB.rotation - bA.rotation;
    bB.angularVelocity -= angularError * 0.1 / dt; // Simple soft lock

    // 2. Constrain movement to axis (Zero out velocity along normal)
    final vA =
        bA.velocity +
        Offset(-bA.angularVelocity * rA.dy, bA.angularVelocity * rA.dx);
    final vB =
        bB.velocity +
        Offset(-bB.angularVelocity * rB.dy, bB.angularVelocity * rB.dx);
    final relVel = vB - vA;

    final velAlongNormal =
        relVel.dx * worldNormal.dx + relVel.dy * worldNormal.dy;
    final posErrorNormal =
        delta.dx * worldNormal.dx + delta.dy * worldNormal.dy;

    const biasFactor = 0.2;
    final bias = -(biasFactor / dt) * posErrorNormal;

    final invMassSum =
        bA.invMass +
        bB.invMass +
        _cross(rA, worldNormal) * _cross(rA, worldNormal) * bA.invInertia +
        _cross(rB, worldNormal) * _cross(rB, worldNormal) * bB.invInertia;

    if (invMassSum > 0) {
      final impulseMag = (-(velAlongNormal) + bias) / invMassSum;
      final impulse = worldNormal * impulseMag;
      bA.velocity -= impulse * bA.invMass;
      bA.angularVelocity -= _cross(rA, impulse) * bA.invInertia;
      bB.velocity += impulse * bB.invMass;
      bB.angularVelocity += _cross(rB, impulse) * bB.invInertia;
    }
  }
}

class WheelJoint extends Joint {
  final Offset anchorA;
  final Offset anchorB;
  final Offset suspensionAxis; // In bodyA's local space

  WheelJoint({
    required super.id,
    required super.bodyAId,
    required super.bodyBId,
    required this.anchorA,
    required this.anchorB,
    required this.suspensionAxis,
  });

  @override
  void solveVelocityConstraints(Map<int, PhysicsBody> bodies, double dt) {
    // Wheel joint is complex; we'll implement a simplified version
    // that acts like a point-to-point constraint with some slack.
    final bA = bodies[bodyAId];
    final bB = bodies[bodyBId];
    if (bA == null || bB == null) return;

    final rA = _rotate(anchorA, bA.rotation);
    final rB = _rotate(anchorB, bB.rotation);
    final pA = bA.position + rA;
    final pB = bB.position + rB;
    final delta = pB - pA;

    final vA =
        bA.velocity +
        Offset(-bA.angularVelocity * rA.dy, bA.angularVelocity * rA.dx);
    final vB =
        bB.velocity +
        Offset(-bB.angularVelocity * rB.dy, bB.angularVelocity * rB.dx);
    final relVel = vB - vA;

    // Suspension logic (spring along suspensionAxis)
    final worldAxis = _rotate(suspensionAxis, bA.rotation);
    final proj = delta.dx * worldAxis.dx + delta.dy * worldAxis.dy;
    final velProj = relVel.dx * worldAxis.dx + relVel.dy * worldAxis.dy;

    final springForce = proj * 500.0; // Stiffness
    final dampingForce = velProj * 10.0;
    final impulse = worldAxis * (springForce + dampingForce) * dt;

    bA.velocity += impulse * bA.invMass;
    bB.velocity -= impulse * bB.invMass;

    // Side-to-side lock (Prismatic constraint on normal)
    final worldNormal = Offset(-worldAxis.dy, worldAxis.dx);
    final velAlongNormal =
        relVel.dx * worldNormal.dx + relVel.dy * worldNormal.dy;
    final posErrorNormal =
        delta.dx * worldNormal.dx + delta.dy * worldNormal.dy;

    final invMassSum =
        bA.invMass +
        bB.invMass +
        _cross(rA, worldNormal) * _cross(rA, worldNormal) * bA.invInertia +
        _cross(rB, worldNormal) * _cross(rB, worldNormal) * bB.invInertia;

    if (invMassSum > 0) {
      final impulseMag =
          (-(velAlongNormal) - (posErrorNormal * 0.2 / dt)) / invMassSum;
      final lockImpulse = worldNormal * impulseMag;
      bA.velocity -= lockImpulse * bA.invMass;
      bA.angularVelocity -= _cross(rA, lockImpulse) * bA.invInertia;
      bB.velocity += lockImpulse * bB.invMass;
      bB.angularVelocity += _cross(rB, lockImpulse) * bB.invInertia;
    }
  }
}

class FixedJoint extends Joint {
  final double referenceAngle;
  final Offset localAnchorA;
  final Offset localAnchorB;

  FixedJoint({
    required super.id,
    required super.bodyAId,
    required super.bodyBId,
    required this.localAnchorA,
    required this.localAnchorB,
    required this.referenceAngle,
  });

  @override
  void solveVelocityConstraints(Map<int, PhysicsBody> bodies, double dt) {
    final bA = bodies[bodyAId];
    final bB = bodies[bodyBId];
    if (bA == null || bB == null) return;

    // 1. Angular constraint
    final angleError = (bB.rotation - bA.rotation) - referenceAngle;
    final angVelError = bB.angularVelocity - bA.angularVelocity;
    final invInertiaSum = bA.invInertia + bB.invInertia;
    if (invInertiaSum > 0) {
      final angImpulse =
          (-(angVelError) - (angleError * 0.2 / dt)) / invInertiaSum;
      bA.angularVelocity -= angImpulse * bA.invInertia;
      bB.angularVelocity += angImpulse * bB.invInertia;
    }

    // 2. Linear constraint (Hinge-like)
    final rA = _rotate(localAnchorA, bA.rotation);
    final rB = _rotate(localAnchorB, bB.rotation);
    final pA = bA.position + rA;
    final pB = bB.position + rB;
    final delta = pB - pA;
    final vA =
        bA.velocity +
        Offset(-bA.angularVelocity * rA.dy, bA.angularVelocity * rA.dx);
    final vB =
        bB.velocity +
        Offset(-bB.angularVelocity * rB.dy, bB.angularVelocity * rB.dx);
    final relVel = vB - vA;

    // Solve for relVel = 0
    final targetVel = relVel + delta * (0.2 / dt);

    // Simple iterative impulse
    final invMassSumX =
        bA.invMass +
        bB.invMass +
        (rA.dy * rA.dy * bA.invInertia) +
        (rB.dy * rB.dy * bB.invInertia);
    if (invMassSumX > 0) {
      final impulseX = -targetVel.dx / invMassSumX;
      bA.velocity -= Offset(impulseX * bA.invMass, 0);
      bA.angularVelocity += rA.dy * impulseX * bA.invInertia;
      bB.velocity += Offset(impulseX * bB.invMass, 0);
      bB.angularVelocity -= rB.dy * impulseX * bB.invInertia;
    }

    final invMassSumY =
        bA.invMass +
        bB.invMass +
        (rA.dx * rA.dx * bA.invInertia) +
        (rB.dx * rB.dx * bB.invInertia);
    if (invMassSumY > 0) {
      final impulseY = -targetVel.dy / invMassSumY;
      bA.velocity -= Offset(0, impulseY * bA.invMass);
      bA.angularVelocity -= rA.dx * impulseY * bA.invInertia;
      bB.velocity += Offset(0, impulseY * bB.invMass);
      bB.angularVelocity += rB.dx * impulseY * bB.invInertia;
    }
  }
}

class FrictionJoint extends Joint {
  final Offset localAnchorA;
  final Offset localAnchorB;
  double maxForce;
  double maxTorque;

  FrictionJoint({
    required super.id,
    required super.bodyAId,
    required super.bodyBId,
    required this.localAnchorA,
    required this.localAnchorB,
    required this.maxForce,
    required this.maxTorque,
  });

  @override
  void solveVelocityConstraints(Map<int, PhysicsBody> bodies, double dt) {
    final bA = bodies[bodyAId];
    final bB = bodies[bodyBId];
    if (bA == null || bB == null) return;

    // Friction is applied to reduce relative velocity to zero, clamped by maxForce/Torque
    final rA = _rotate(localAnchorA, bA.rotation);
    final rB = _rotate(localAnchorB, bB.rotation);
    final vA =
        bA.velocity +
        Offset(-bA.angularVelocity * rA.dy, bA.angularVelocity * rA.dx);
    final vB =
        bB.velocity +
        Offset(-bB.angularVelocity * rB.dy, bB.angularVelocity * rB.dx);
    final relVel = vB - vA;

    // Linear friction
    if (relVel.distanceSquared > 0) {
      final unit = relVel / relVel.distance;
      final invMassSum =
          bA.invMass +
          bB.invMass +
          _cross(rA, unit) * _cross(rA, unit) * bA.invInertia +
          _cross(rB, unit) * _cross(rB, unit) * bB.invInertia;

      if (invMassSum > 0) {
        double impulseMag = -relVel.distance / invMassSum;
        final maxImpulse = maxForce * dt;
        if (impulseMag.abs() > maxImpulse) {
          impulseMag = impulseMag.sign * maxImpulse;
        }
        final impulse = unit * impulseMag;
        bA.velocity -= impulse * bA.invMass;
        bA.angularVelocity -= _cross(rA, impulse) * bA.invInertia;
        bB.velocity += impulse * bB.invMass;
        bB.angularVelocity += _cross(rB, impulse) * bB.invInertia;
      }
    }

    // Angular friction
    final relAngVel = bB.angularVelocity - bA.angularVelocity;
    final invInertiaSum = bA.invInertia + bB.invInertia;
    if (invInertiaSum > 0) {
      double angImpulse = -relAngVel / invInertiaSum;
      final maxAngImpulse = maxTorque * dt;
      if (angImpulse.abs() > maxAngImpulse) {
        angImpulse = angImpulse.sign * maxAngImpulse;
      }
      bA.angularVelocity -= angImpulse * bA.invInertia;
      bB.angularVelocity += angImpulse * bB.invInertia;
    }
  }
}

class RelativeJoint extends Joint {
  final Offset linearOffset;
  final double angularOffset;
  double maxForce;
  double maxTorque;

  RelativeJoint({
    required super.id,
    required super.bodyAId,
    required super.bodyBId,
    required this.linearOffset,
    required this.angularOffset,
    required this.maxForce,
    required this.maxTorque,
  });

  @override
  void solveVelocityConstraints(Map<int, PhysicsBody> bodies, double dt) {
    // Similar to FrictionJoint but tries to reach a target offset/angle
    final bA = bodies[bodyAId];
    final bB = bodies[bodyBId];
    if (bA == null || bB == null) return;

    // 1. Angular
    final angleError = (bB.rotation - bA.rotation) - angularOffset;
    final relAngVel = bB.angularVelocity - bA.angularVelocity;
    final invInertiaSum = bA.invInertia + bB.invInertia;
    if (invInertiaSum > 0) {
      double angImpulse =
          (-(relAngVel) - (angleError * 0.1 / dt)) / invInertiaSum;
      final maxAngImpulse = maxTorque * dt;
      if (angImpulse.abs() > maxAngImpulse)
        angImpulse = angImpulse.sign * maxAngImpulse;
      bA.angularVelocity -= angImpulse * bA.invInertia;
      bB.angularVelocity += angImpulse * bB.invInertia;
    }

    // 2. Linear
    final worldTargetPos = bA.position + _rotate(linearOffset, bA.rotation);
    final posError = bB.position - worldTargetPos;
    final relVel = bB.velocity - bA.velocity;
    final invMassSum = bA.invMass + bB.invMass;
    if (invMassSum > 0) {
      final targetVel = relVel + posError * (0.1 / dt);
      Offset impulse = targetVel * (-1.0 / invMassSum);
      final maxImpulse = maxForce * dt;
      if (impulse.distance > maxImpulse) {
        impulse = (impulse / impulse.distance) * maxImpulse;
      }
      bA.velocity -= impulse * bA.invMass;
      bB.velocity += impulse * bB.invMass;
    }
  }
}

class TargetJoint extends Joint {
  Offset target;
  double maxForce;
  double frequency;
  double dampingRatio;

  TargetJoint({
    required super.id,
    required super.bodyAId, // Usually the body to pull
    required super.bodyBId, // Not used or static
    required this.target,
    required this.maxForce,
    required this.frequency,
    required this.dampingRatio,
  });

  @override
  void solveVelocityConstraints(Map<int, PhysicsBody> bodies, double dt) {
    final bA = bodies[bodyAId];
    if (bA == null) return;

    // Pull bA.position towards target
    final posError = bA.position - target;
    final relVel = bA.velocity;

    // Using a spring-damper model for the target joint
    final k = bA.mass * (frequency * frequency);
    final c = bA.mass * (2.0 * dampingRatio * frequency);

    final force = posError * (-k) - relVel * c;
    Offset impulse = force * dt;

    final maxImpulse = maxForce * dt;
    if (impulse.distance > maxImpulse) {
      impulse = (impulse / impulse.distance) * maxImpulse;
    }

    bA.velocity += impulse * bA.invMass;
  }
}

// Helpers
Offset _rotate(Offset v, double radians) {
  final cos = math.cos(radians);
  final sin = math.sin(radians);
  return Offset(
    v.dx * cos - v.dy * sin,
    v.dx * sin + v.dy * cos,
  );
}

double _cross(Offset a, Offset b) => a.dx * b.dy - a.dy * b.dx;
