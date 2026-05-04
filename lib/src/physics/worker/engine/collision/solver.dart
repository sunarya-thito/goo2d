import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/src/physics/worker/engine/physics_engine.dart';
import 'package:goo2d/src/physics/worker/engine/physics_body.dart';
import 'package:goo2d/src/physics/worker/engine/collision/narrowphase.dart';
import 'package:goo2d/src/physics/worker/engine/collision/shape_intersect.dart';

/// Prepared contact constraint for the solver.
class ContactConstraint {
  final int bodyA;
  final int bodyB;
  final Vector2 normal;
  final List<_ContactPoint> points;

  /// Combined friction of the two colliders.
  final double friction;
  /// Combined restitution (bounciness).
  final double restitution;

  ContactConstraint({
    required this.bodyA,
    required this.bodyB,
    required this.normal,
    required this.points,
    required this.friction,
    required this.restitution,
  });
}

class _ContactPoint {
  final Vector2 point;
  final double penetration;

  // Solver accumulators
  double normalImpulse = 0;
  double tangentImpulse = 0;

  // Pre-computed
  late Vector2 rA;
  late Vector2 rB;
  late double normalMass;
  late double tangentMass;
  late double velocityBias;

  _ContactPoint(this.point, this.penetration);
}

/// Builds contact constraints from narrowphase results.
List<ContactConstraint> buildConstraints(
    PhysicsEngine engine, List<NarrowphaseContact> contacts) {
  return [
    for (final c in contacts)
      ContactConstraint(
        bodyA: c.bodyA,
        bodyB: c.bodyB,
        normal: c.manifold.normal,
        points: [
          for (final cv in c.manifold.contacts)
            _ContactPoint(cv.point, cv.penetration),
        ],
        friction: _combineFriction(engine, c.colliderA, c.colliderB),
        restitution: _combineRestitution(engine, c.colliderA, c.colliderB),
      ),
  ];
}

double _combineFriction(PhysicsEngine engine, int cA, int cB) {
  final a = engine.colliders[cA];
  final b = engine.colliders[cB];
  if (a == null || b == null) return 0.4;
  return math.sqrt(a.friction * b.friction);
}

double _combineRestitution(PhysicsEngine engine, int cA, int cB) {
  final a = engine.colliders[cA];
  final b = engine.colliders[cB];
  if (a == null || b == null) return 0;
  return math.max(a.bounciness, b.bounciness);
}

/// Pre-computes solver data for each constraint.
void initializeConstraints(
    List<ContactConstraint> constraints, PhysicsEngine engine) {
  for (final c in constraints) {
    final bA = engine.bodies[c.bodyA];
    final bB = engine.bodies[c.bodyB];
    if (bA == null || bB == null) continue;

    final invMassA = _invMass(bA);
    final invMassB = _invMass(bB);
    final invIA = _invInertia(bA);
    final invIB = _invInertia(bB);

    final tangent = Vector2(-c.normal.y, c.normal.x);

    for (final cp in c.points) {
      cp.rA = cp.point - bA.worldCenterOfMass;
      cp.rB = cp.point - bB.worldCenterOfMass;

      final rnA = _cross2(cp.rA, c.normal);
      final rnB = _cross2(cp.rB, c.normal);
      final kNormal = invMassA + invMassB + invIA * rnA * rnA + invIB * rnB * rnB;
      cp.normalMass = kNormal > 0 ? 1.0 / kNormal : 0;

      final rtA = _cross2(cp.rA, tangent);
      final rtB = _cross2(cp.rB, tangent);
      final kTangent = invMassA + invMassB + invIA * rtA * rtA + invIB * rtB * rtB;
      cp.tangentMass = kTangent > 0 ? 1.0 / kTangent : 0;

      // Velocity bias for restitution and position correction
      final vA = bA.linearVelocity + _crossSV(bA.angularVelocity * math.pi / 180, cp.rA);
      final vB = bB.linearVelocity + _crossSV(bB.angularVelocity * math.pi / 180, cp.rB);
      final relVel = (vB - vA).dot(c.normal);

      cp.velocityBias = 0;
      if (relVel < -engine.bounceThreshold) {
        cp.velocityBias = -c.restitution * relVel;
      }
    }
  }
}

/// Solves velocity constraints (one iteration).
void solveVelocityConstraints(
    List<ContactConstraint> constraints, PhysicsEngine engine) {
  for (final c in constraints) {
    final bA = engine.bodies[c.bodyA];
    final bB = engine.bodies[c.bodyB];
    if (bA == null || bB == null) continue;
    if (bA.bodyType == 1 && bB.bodyType == 1) continue; // Both static

    final invMassA = _invMass(bA);
    final invMassB = _invMass(bB);
    final invIA = _invInertia(bA);
    final invIB = _invInertia(bB);
    final tangent = Vector2(-c.normal.y, c.normal.x);

    for (final cp in c.points) {
      // Relative velocity at contact
      final wA = bA.angularVelocity * math.pi / 180;
      final wB = bB.angularVelocity * math.pi / 180;
      final vA = bA.linearVelocity + _crossSV(wA, cp.rA);
      final vB = bB.linearVelocity + _crossSV(wB, cp.rB);
      final dv = vB - vA;

      // Normal impulse
      final vn = dv.dot(c.normal);
      var lambda = cp.normalMass * (-vn + cp.velocityBias);
      final newImpulse = math.max(cp.normalImpulse + lambda, 0);
      lambda = newImpulse - cp.normalImpulse;
      cp.normalImpulse = newImpulse.toDouble();

      final impulseN = c.normal * lambda;
      _applyImpulse(bA, bB, impulseN, cp.rA, cp.rB, invMassA, invMassB, invIA, invIB);

      // Tangent impulse (friction)
      final vt = dv.dot(tangent);
      var lambdaT = cp.tangentMass * (-vt);
      final maxFriction = c.friction * cp.normalImpulse;
      final newTangent = (cp.tangentImpulse + lambdaT).clamp(-maxFriction, maxFriction);
      lambdaT = newTangent - cp.tangentImpulse;
      cp.tangentImpulse = newTangent;

      final impulseT = tangent * lambdaT;
      _applyImpulse(bA, bB, impulseT, cp.rA, cp.rB, invMassA, invMassB, invIA, invIB);
    }
  }
}

/// Solves position constraints to prevent penetration.
bool solvePositionConstraints(
    List<ContactConstraint> constraints, PhysicsEngine engine,
    double baumgarteScale, double maxLinearCorrection) {
  var minSep = 0.0;
  const slop = 0.005; // Allowed penetration

  for (final c in constraints) {
    final bA = engine.bodies[c.bodyA];
    final bB = engine.bodies[c.bodyB];
    if (bA == null || bB == null) continue;
    if (bA.bodyType == 1 && bB.bodyType == 1) continue;

    final invMassA = _invMass(bA);
    final invMassB = _invMass(bB);
    final invIA = _invInertia(bA);
    final invIB = _invInertia(bB);

    for (final cp in c.points) {
      final rA = cp.point - bA.position;
      final rB = cp.point - bB.position;

      final separation = c.normal.dot(bB.position + rB - bA.position - rA) - 0;
      minSep = math.min(minSep, separation);

      final cVal = (baumgarteScale * (separation + slop)).clamp(
          -maxLinearCorrection, 0.0);

      final rnA = _cross2(rA, c.normal);
      final rnB = _cross2(rB, c.normal);
      final k = invMassA + invMassB + invIA * rnA * rnA + invIB * rnB * rnB;
      if (k <= 0) continue;

      final impulse = -cVal / k;
      final p = c.normal * impulse;

      if (bA.bodyType == 0) { // Dynamic
        bA.position -= p * invMassA;
        bA.rotation -= _cross2(rA, p) * invIA * 180 / math.pi;
      }
      if (bB.bodyType == 0) {
        bB.position += p * invMassB;
        bB.rotation += _cross2(rB, p) * invIB * 180 / math.pi;
      }
    }
  }

  return minSep >= -3 * slop;
}

// ===================== Helpers =====================

double _invMass(PhysicsBody b) => b.bodyType == 0 ? (b.mass > 0 ? 1.0 / b.mass : 0) : 0;
double _invInertia(PhysicsBody b) => b.bodyType == 0 ? (b.inertia > 0 ? 1.0 / b.inertia : 0) : 0;

double _cross2(Vector2 a, Vector2 b) => a.x * b.y - a.y * b.x;

Vector2 _crossSV(double s, Vector2 v) => Vector2(-s * v.y, s * v.x);

void _applyImpulse(PhysicsBody bA, PhysicsBody bB, Vector2 impulse,
    Vector2 rA, Vector2 rB,
    double invMassA, double invMassB, double invIA, double invIB) {
  if (bA.bodyType == 0) {
    bA.linearVelocity -= impulse * invMassA;
    bA.angularVelocity -= _cross2(rA, impulse) * invIA * 180 / math.pi;
  }
  if (bB.bodyType == 0) {
    bB.linearVelocity += impulse * invMassB;
    bB.angularVelocity += _cross2(rB, impulse) * invIB * 180 / math.pi;
  }
}
