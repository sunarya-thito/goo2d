import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/src/physics/worker/engine/physics_engine.dart';
import 'package:goo2d/src/physics/worker/engine/physics_body.dart';
import 'package:goo2d/src/physics/worker/engine/physics_joint.dart';

/// Solves all active joint constraints for one step.
void solveJointConstraints(PhysicsEngine engine, double dt) {
  final toRemove = <int>[];

  for (final joint in engine.joints.values) {
    final bA = engine.bodies[joint.bodyHandleA];
    if (bA == null) continue;
    final bB = joint.bodyHandleB >= 0 ? engine.bodies[joint.bodyHandleB] : null;

    switch (joint.jointType) {
      case 0: _solveDistanceJoint(joint, bA, bB, dt, engine); break;
      case 1: _solveFixedJoint(joint, bA, bB, dt, engine); break;
      case 2: _solveFrictionJoint(joint, bA, bB, dt, engine); break;
      case 3: _solveHingeJoint(joint, bA, bB, dt, engine); break;
      case 4: _solveRelativeJoint(joint, bA, bB, dt, engine); break;
      case 5: _solveSliderJoint(joint, bA, bB, dt, engine); break;
      case 6: _solveSpringJoint(joint, bA, bB, dt, engine); break;
      case 7: _solveTargetJoint(joint, bA, bB, dt, engine); break;
      case 8: _solveWheelJoint(joint, bA, bB, dt, engine); break;
    }

    // Check break force/torque
    if (_shouldBreak(joint, bA, bB)) {
      toRemove.add(joint.handle);
    }
  }

  for (final h in toRemove) {
    engine.joints.remove(h);
  }
}

// ===================== Distance Joint =====================

void _solveDistanceJoint(
    PhysicsJoint j, PhysicsBody bA, PhysicsBody? bB,
    double dt, PhysicsEngine engine) {
  final anchorA = _worldAnchor(bA, j.anchor);
  final anchorB = bB != null ? _worldAnchor(bB, j.connectedAnchor) : j.connectedAnchor;

  final delta = anchorB - anchorA;
  final dist = delta.length;
  if (dist < 1e-10) return;

  final targetDist = j.autoConfigureDistance ? dist : j.distance;
  final error = dist - targetDist;

  // Max-distance-only mode: only constrain if stretched beyond
  if (j.maxDistanceOnly > 0 && error < 0) return;

  final normal = delta / dist;
  final impulse = _computeDistanceImpulse(bA, bB, normal, error, dt);

  _applyJointImpulse(bA, bB, impulse, anchorA, anchorB);
}

Vector2 _computeDistanceImpulse(
    PhysicsBody bA, PhysicsBody? bB, Vector2 normal, double error, double dt,
    {Vector2? localAnchorA, Vector2? localAnchorB}) {
  final anchorA = _worldAnchor(bA, localAnchorA ?? Vector2.zero());
  final anchorB = bB != null
      ? _worldAnchor(bB, localAnchorB ?? Vector2.zero())
      : (localAnchorB ?? Vector2.zero());

  final invMass = _computeEffectiveInvMass(bA, bB, anchorA, anchorB, normal);
  if (invMass <= 0) return Vector2.zero();

  // Baumgarte stabilization with clamped bias to prevent explosion
  const beta = 0.2;
  const maxBias = 10.0;
  final bias = (beta / dt * error).clamp(-maxBias, maxBias);

  // Relative velocity at points
  final relVel = _relativeVelocityAtPoints(bA, bB, anchorA, anchorB, normal);
  var lambda = -(relVel + bias) / invMass;

  // Clamp impulse to prevent numerical explosion
  const maxLambda = 100.0;
  lambda = lambda.clamp(-maxLambda, maxLambda);

  return normal * lambda;
}

// ===================== Fixed Joint =====================

void _solveFixedJoint(
    PhysicsJoint j, PhysicsBody bA, PhysicsBody? bB,
    double dt, PhysicsEngine engine) {
  if (bB == null) return;

  // Position constraint
  final anchorA = _worldAnchor(bA, j.anchor);
  final anchorB = _worldAnchor(bB, j.connectedAnchor);
  final delta = anchorB - anchorA;
  final dist = delta.length;

  if (dist > 1e-6) {
    final normal = delta / dist;
    final impulse = _computeDistanceImpulse(bA, bB, normal, dist, dt);
    _applyJointImpulse(bA, bB, impulse, anchorA, anchorB);
  }

  // Rotation constraint — keep relative angle constant
  final relAngle = bB.rotation - bA.rotation;
  final angError = relAngle; // Target is 0 relative rotation
  _applyAngularCorrection(bA, bB, angError, dt);
}

// ===================== Friction Joint =====================

void _solveFrictionJoint(
    PhysicsJoint j, PhysicsBody bA, PhysicsBody? bB,
    double dt, PhysicsEngine engine) {
  if (bB == null) return;

  // Linear friction
  final relVelVec = bB.linearVelocity - bA.linearVelocity;
  final relSpeed = relVelVec.length;
  if (relSpeed > 1e-10) {
    final invMassSum = _invMass(bA) + _invMass(bB);
    if (invMassSum <= 0) return;
    var lambda = -relSpeed / invMassSum;
    final maxLambda = j.maxForce * dt;
    lambda = lambda.clamp(-maxLambda, maxLambda);
    final impulse = (relVelVec / relSpeed) * lambda;
    _applyLinearImpulse(bA, bB, impulse);
  }

  // Angular friction
  final relAngVel = bB.angularVelocity - bA.angularVelocity;
  final invIA = _invInertia(bA);
  final invIB = _invInertia(bB);
  final invISum = invIA + invIB;
  if (invISum > 0) {
    var angLambda = -relAngVel / invISum;
    final maxAng = j.maxTorque * dt;
    angLambda = angLambda.clamp(-maxAng, maxAng);
    if (bA.bodyType == 0) bA.angularVelocity -= angLambda * invIA;
    if (bB.bodyType == 0) bB.angularVelocity += angLambda * invIB;
  }
}

// ===================== Hinge Joint =====================

void _solveHingeJoint(
    PhysicsJoint j, PhysicsBody bA, PhysicsBody? bB,
    double dt, PhysicsEngine engine) {
  if (bB == null) return;

  // Position constraint (keep anchors together)
  final anchorA = _worldAnchor(bA, j.anchor);
  final anchorB = _worldAnchor(bB, j.connectedAnchor);
  final delta = anchorB - anchorA;
  final dist = delta.length;

  if (dist > 1e-6) {
    final normal = delta / dist;
    final impulse = _computeDistanceImpulse(bA, bB, normal, dist, dt);
    _applyJointImpulse(bA, bB, impulse, anchorA, anchorB);
  }

  // Angle limits
  if (j.useLimits) {
    final relAngle = bB.rotation - bA.rotation;
    if (relAngle < j.lowerAngle) {
      _applyAngularCorrection(bA, bB, relAngle - j.lowerAngle, dt);
    } else if (relAngle > j.upperAngle) {
      _applyAngularCorrection(bA, bB, relAngle - j.upperAngle, dt);
    }
  }

  // Motor
  if (j.useMotor) {
    final relAngVel = bB.angularVelocity - bA.angularVelocity;
    final targetSpeed = j.motorSpeed;
    final error = relAngVel - targetSpeed;
    final invIA = _invInertia(bA);
    final invIB = _invInertia(bB);
    final invISum = invIA + invIB;
    if (invISum > 0) {
      var impulse = -error / invISum;
      final maxImpulse = j.maxMotorTorque * dt;
      impulse = impulse.clamp(-maxImpulse, maxImpulse);
      if (bA.bodyType == 0) bA.angularVelocity -= impulse * invIA;
      if (bB.bodyType == 0) bB.angularVelocity += impulse * invIB;
    }
  }
}

// ===================== Relative Joint =====================

void _solveRelativeJoint(
    PhysicsJoint j, PhysicsBody bA, PhysicsBody? bB,
    double dt, PhysicsEngine engine) {
  if (bB == null) return;

  // Maintain relative offset
  final targetPos = bA.position + j.linearOffset;
  final delta = targetPos - bB.position;
  final correction = delta * j.correctionScale;

  final invMassA = _invMass(bA);
  final invMassB = _invMass(bB);
  final totalInvMass = invMassA + invMassB;
  if (totalInvMass <= 0) return;

  final impulse = correction / (totalInvMass * dt);
  _applyLinearImpulse(bA, bB, -impulse);

  // Angular
  final targetAngle = bA.rotation + j.angularOffset;
  final angError = targetAngle - bB.rotation;
  _applyAngularCorrection(bA, bB, -angError * j.correctionScale, dt);
}

// ===================== Slider Joint =====================

void _solveSliderJoint(
    PhysicsJoint j, PhysicsBody bA, PhysicsBody? bB,
    double dt, PhysicsEngine engine) {
  if (bB == null) return;

  final anchorA = _worldAnchor(bA, j.anchor);
  final anchorB = _worldAnchor(bB, j.connectedAnchor);
  final delta = anchorB - anchorA;

  // Slider axis
  final angleRad = j.sliderAngle * math.pi / 180.0;
  final axis = Vector2(math.cos(angleRad), math.sin(angleRad));
  final perp = Vector2(-axis.y, axis.x);

  // Constrain movement perpendicular to axis
  final perpError = delta.dot(perp);
  if (perpError.abs() > 1e-6) {
    final invMassSum = _invMass(bA) + _invMass(bB);
    if (invMassSum > 0) {
      final impulse = perp * (-perpError * 0.2 / (dt * invMassSum));
      _applyLinearImpulse(bA, bB, impulse);
    }
  }

  // Translation limits
  if (j.useTranslationLimits) {
    final axisProj = delta.dot(axis);
    if (axisProj < j.lowerTranslation) {
      final error = axisProj - j.lowerTranslation;
      final impulse = _computeDistanceImpulse(bA, bB, axis, error, dt);
      _applyLinearImpulse(bA, bB, impulse);
    } else if (axisProj > j.upperTranslation) {
      final error = axisProj - j.upperTranslation;
      final impulse = _computeDistanceImpulse(bA, bB, axis, error, dt);
      _applyLinearImpulse(bA, bB, impulse);
    }
  }
}

// ===================== Spring Joint =====================

void _solveSpringJoint(
    PhysicsJoint j, PhysicsBody bA, PhysicsBody? bB,
    double dt, PhysicsEngine engine) {
  final anchorA = _worldAnchor(bA, j.anchor);
  final anchorB = bB != null ? _worldAnchor(bB, j.connectedAnchor) : j.connectedAnchor;

  final delta = anchorB - anchorA;
  final dist = delta.length;
  if (dist < 1e-10) return;

  final targetDist = j.distance;
  final error = dist - targetDist;
  final normal = delta / dist;

  // Relative velocity at anchor points along normal
  final relVel = _relativeVelocityAtPoints(bA, bB, anchorA, anchorB, normal);

  // Effective mass for this constraint
  final invMass = _computeEffectiveInvMass(bA, bB, anchorA, anchorB, normal);
  if (invMass <= 0) return;
  final mass = 1.0 / invMass;

  // Spring-damper force: F = -k*x - c*v
  final omega = 2.0 * math.pi * j.springFrequency;
  final k = mass * omega * omega;
  final c = 2.0 * mass * j.springDampingRatio * omega;

  var force = k * error + c * relVel;
  
  // Clamp force to prevent explosion
  const maxForce = 5000.0;
  force = force.clamp(-maxForce, maxForce);

  // Impulse on B is -F*dt*normal.
  final impulse = normal * (-force * dt);
  _applyJointImpulse(bA, bB, impulse, anchorA, anchorB);
}

// ===================== Target Joint =====================

void _solveTargetJoint(
    PhysicsJoint j, PhysicsBody bA, PhysicsBody? bB,
    double dt, PhysicsEngine engine) {
  final anchorA = _worldAnchor(bA, j.anchor);
  final target = j.target;

  final delta = target - anchorA;
  final dist = delta.length;
  if (dist < 1e-10) return;

  final normal = delta / dist;
  final error = dist; // Target distance is 0

  // Baumgarte stabilization
  const beta = 0.2;
  final bias = (beta / dt * error).clamp(-10.0, 10.0);

  // Relative velocity at anchor point
  final relVel = _relativeVelocityAtPoints(bA, null, anchorA, target, normal);

  final invMass = _computeEffectiveInvMass(bA, null, anchorA, target, normal);
  if (invMass <= 0) return;

  var lambda = -(relVel + bias) / invMass;
  
  // Clamp impulse
  const maxLambda = 100.0;
  lambda = lambda.clamp(-maxLambda, maxLambda);

  final impulse = normal * lambda;
  _applyJointImpulse(bA, null, impulse, anchorA, target);
}

// ===================== Wheel Joint =====================

void _solveWheelJoint(
    PhysicsJoint j, PhysicsBody bA, PhysicsBody? bB,
    double dt, PhysicsEngine engine) {
  if (bB == null) return;

  // Suspension axis
  final suspAngle = j.wheelSuspensionAngle * math.pi / 180.0;
  final suspAxis = Vector2(math.cos(suspAngle), math.sin(suspAngle));

  final anchorA = _worldAnchor(bA, j.anchor);
  final anchorB = _worldAnchor(bB, j.connectedAnchor);
  final delta = anchorB - anchorA;

  // Spring along suspension axis
  final suspDisp = delta.dot(suspAxis);
  if (suspDisp.abs() > 1e-6) {
    final omega = 2.0 * math.pi * j.springFrequency;
    final massA = bA.mass > 0 ? bA.mass : 1.0;
    final k = massA * omega * omega;
    final c = 2.0 * massA * j.springDampingRatio * omega;
    final relVel = _relativeVelocity(bA, bB, suspAxis);
    final force = k * suspDisp + c * relVel;
    final impulse = suspAxis * (force * dt);
    _applyLinearImpulse(bA, bB, impulse);
  }

  // Constrain perpendicular to suspension axis
  final perpAxis = Vector2(-suspAxis.y, suspAxis.x);
  final perpError = delta.dot(perpAxis);
  if (perpError.abs() > 1e-6) {
    final invMassSum = _invMass(bA) + _invMass(bB);
    if (invMassSum > 0) {
      final impulse = perpAxis * (-perpError * 0.2 / (dt * invMassSum));
      _applyLinearImpulse(bA, bB, impulse);
    }
  }
}

// ===================== Break Check =====================

bool _shouldBreak(PhysicsJoint j, PhysicsBody bA, PhysicsBody? bB) {
  if (j.breakForce.isInfinite && j.breakTorque.isInfinite) return false;

  // Estimate reaction force from velocity correction
  final anchorA = _worldAnchor(bA, j.anchor);
  final anchorB = bB != null ? _worldAnchor(bB, j.connectedAnchor) : j.connectedAnchor;
  final reactionForce = (anchorB - anchorA).length * (bA.mass > 0 ? bA.mass : 1.0);

  return reactionForce > j.breakForce;
}

// ===================== Helpers =====================

double _invMass(PhysicsBody b) =>
    b.bodyType == 0 ? (b.mass > 0 ? 1.0 / b.mass : 0) : 0;

double _invInertia(PhysicsBody b) =>
    b.bodyType == 0 ? (b.inertia > 0 ? 1.0 / b.inertia : 0) : 0;

Vector2 _worldAnchor(PhysicsBody body, Vector2 localAnchor) {
  final rot = body.rotation * math.pi / 180.0;
  final c = math.cos(rot);
  final s = math.sin(rot);
  return Vector2(
    localAnchor.x * c - localAnchor.y * s + body.position.x,
    localAnchor.x * s + localAnchor.y * c + body.position.y,
  );
}

double _relativeVelocityAtPoints(
    PhysicsBody bA, PhysicsBody? bB, Vector2 pA, Vector2 pB, Vector2 axis) {
  final rA = pA - bA.worldCenterOfMass;
  final vA = bA.linearVelocity + _crossSV(bA.angularVelocity * math.pi / 180, rA);

  if (bB == null) {
    return -vA.dot(axis);
  }

  final rB = pB - bB.worldCenterOfMass;
  final vB = bB.linearVelocity + _crossSV(bB.angularVelocity * math.pi / 180, rB);

  return (vB - vA).dot(axis);
}

double _computeEffectiveInvMass(
    PhysicsBody bA, PhysicsBody? bB, Vector2 pA, Vector2 pB, Vector2 axis) {
  final invMassA = _invMass(bA);
  final invIA = _invInertia(bA);
  final rA = pA - bA.worldCenterOfMass;
  final rnA = _cross2(rA, axis);

  var k = invMassA + invIA * rnA * rnA;

  if (bB != null) {
    final invMassB = _invMass(bB);
    final invIB = _invInertia(bB);
    final rB = pB - bB.worldCenterOfMass;
    final rnB = _cross2(rB, axis);
    k += invMassB + invIB * rnB * rnB;
  }

  return k;
}

double _relativeVelocity(PhysicsBody bA, PhysicsBody? bB, Vector2 axis) {
  final vA = bA.linearVelocity.dot(axis);
  final vB = bB != null ? bB.linearVelocity.dot(axis) : 0.0;
  return vB - vA;
}

void _applyJointImpulse(PhysicsBody bA, PhysicsBody? bB,
    Vector2 impulse, Vector2 anchorA, Vector2 anchorB) {
  if (bA.bodyType == 0) {
    bA.linearVelocity -= impulse * _invMass(bA);
    final rA = anchorA - bA.worldCenterOfMass;
    bA.angularVelocity -=
        (rA.x * impulse.y - rA.y * impulse.x) * _invInertia(bA) * 180 / math.pi;
  }
  if (bB != null && bB.bodyType == 0) {
    bB.linearVelocity += impulse * _invMass(bB);
    final rB = anchorB - bB.worldCenterOfMass;
    bB.angularVelocity +=
        (rB.x * impulse.y - rB.y * impulse.x) * _invInertia(bB) * 180 / math.pi;
  }
}

void _applyLinearImpulse(PhysicsBody bA, PhysicsBody? bB, Vector2 impulse) {
  if (bA.bodyType == 0) bA.linearVelocity -= impulse * _invMass(bA);
  if (bB != null && bB.bodyType == 0) bB.linearVelocity += impulse * _invMass(bB);
}

void _applyAngularCorrection(
    PhysicsBody bA, PhysicsBody? bB, double angError, double dt) {
  final invIA = _invInertia(bA);
  final invIB = bB != null ? _invInertia(bB) : 0.0;
  final invISum = invIA + invIB;
  if (invISum <= 0) return;

  const beta = 0.2;
  const maxBias = 10.0;
  final bias = (beta / dt * angError).clamp(-maxBias, maxBias);
  final relAngVel = (bB?.angularVelocity ?? 0.0) - bA.angularVelocity;
  final impulse = -(relAngVel + bias) / invISum;

  if (bA.bodyType == 0) bA.angularVelocity -= impulse * invIA;
  if (bB != null && bB.bodyType == 0) bB.angularVelocity += impulse * invIB;
}
double _cross2(Vector2 a, Vector2 b) => a.x * b.y - a.y * b.x;

Vector2 _crossSV(double s, Vector2 v) => Vector2(-s * v.y, s * v.x);
