import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/src/physics/worker/engine/physics_engine.dart';
import 'package:goo2d/src/physics/worker/engine/physics_body.dart';
import 'package:goo2d/src/physics/worker/engine/physics_effector.dart';

/// Applies all active effectors to overlapping bodies each step.
void applyEffectors(PhysicsEngine engine, double dt) {
  for (final effector in engine.effectors.values) {
    switch (effector.effectorType) {
      case 0: _applyAreaEffector(effector, engine, dt);
      case 1: _applyBuoyancyEffector(effector, engine, dt);
      // Platform (2) modifies contact response, handled in solver
      case 3: _applyPointEffector(effector, engine, dt);
      case 4: _applySurfaceEffector(effector, engine, dt);
    }
  }
}

// ===================== Area Effector =====================

void _applyAreaEffector(PhysicsEffector e, PhysicsEngine engine, double dt) {
  if (e.forceMagnitude == 0 && e.drag == 0 && e.angularDrag == 0) return;

  final angleRad = e.forceAngle * math.pi / 180.0;
  final baseForce = Vector2(
    math.cos(angleRad) * e.forceMagnitude,
    math.sin(angleRad) * e.forceMagnitude,
  );

  for (final body in engine.bodies.values) {
    if (!body.simulated || body.bodyType != 0) continue;
    if (body.isSleeping) continue;

    // Apply force with variation
    final variation = e.forceVariation > 0
        ? (1.0 + (math.Random().nextDouble() - 0.5) * 2 * e.forceVariation)
        : 1.0;

    final force = baseForce * variation;

    if (e.forceTarget == 0) {
      // Rigidbody: apply as acceleration (ignore mass)
      body.linearVelocity += force * dt;
    } else {
      // Collider: apply as force
      body.totalForce += force;
    }

    // Drag
    if (e.drag > 0) {
      body.linearVelocity *= 1.0 / (1.0 + dt * e.drag);
    }
    if (e.angularDrag > 0) {
      body.angularVelocity *= 1.0 / (1.0 + dt * e.angularDrag);
    }
  }
}

// ===================== Buoyancy Effector =====================

void _applyBuoyancyEffector(PhysicsEffector e, PhysicsEngine engine, double dt) {
  for (final body in engine.bodies.values) {
    if (!body.simulated || body.bodyType != 0) continue;
    if (body.isSleeping) continue;

    // Simple buoyancy: if body is below surface level, apply upward force
    final depth = e.surfaceLevel - body.position.y;
    if (depth <= 0) continue;

    // Buoyancy force = density * gravity * submerged_volume
    // Simplified: proportional to depth
    final buoyancyForce = e.buoyancyDensity * 9.81 * depth;
    body.totalForce += Vector2(0, buoyancyForce);

    // Flow force
    if (e.flowMagnitude > 0) {
      final flowAngleRad = e.flowAngle * math.pi / 180.0;
      final variation = e.flowVariation > 0
          ? (1.0 + (math.Random().nextDouble() - 0.5) * 2 * e.flowVariation)
          : 1.0;
      final flowForce = Vector2(
        math.cos(flowAngleRad) * e.flowMagnitude * variation,
        math.sin(flowAngleRad) * e.flowMagnitude * variation,
      );
      body.totalForce += flowForce;
    }

    // Drag
    if (e.linearDrag > 0) {
      body.linearVelocity *= 1.0 / (1.0 + dt * e.linearDrag);
    }
    if (e.angularDragBuoyancy > 0) {
      body.angularVelocity *= 1.0 / (1.0 + dt * e.angularDragBuoyancy);
    }
  }
}

// ===================== Point Effector =====================

void _applyPointEffector(PhysicsEffector e, PhysicsEngine engine, double dt) {
  if (e.pointForceMagnitude == 0) return;

  // Source position: first collider attached, or use (0,0)
  final sourcePos = Vector2.zero();

  for (final body in engine.bodies.values) {
    if (!body.simulated || body.bodyType != 0) continue;
    if (body.isSleeping) continue;

    final delta = body.position - sourcePos;
    final dist = delta.length;
    if (dist < 1e-10) continue;

    final direction = delta / dist;
    final scaledDist = e.distanceScale > 0 ? dist / e.distanceScale : dist;

    // Inverse-square falloff
    final forceFactor = scaledDist > 1e-10 ? 1.0 / (scaledDist * scaledDist) : 1.0;
    final variation = e.pointForceVariation > 0
        ? (1.0 + (math.Random().nextDouble() - 0.5) * 2 * e.pointForceVariation)
        : 1.0;

    final magnitude = e.pointForceMagnitude * forceFactor * variation;

    if (e.pointForceTarget == 0) {
      body.linearVelocity += direction * (magnitude * dt);
    } else {
      body.totalForce += direction * magnitude;
    }

    // Drag
    if (e.pointDrag > 0) {
      body.linearVelocity *= 1.0 / (1.0 + dt * e.pointDrag);
    }
    if (e.pointAngularDrag > 0) {
      body.angularVelocity *= 1.0 / (1.0 + dt * e.pointAngularDrag);
    }
  }
}

// ===================== Surface Effector =====================

void _applySurfaceEffector(PhysicsEffector e, PhysicsEngine engine, double dt) {
  if (e.speed == 0 && e.forceScale == 0) return;

  // Surface effector applies tangential velocity to bodies in contact
  for (final contact in engine.activeContacts) {
    final bA = engine.bodies[contact.bodyA];
    final bB = engine.bodies[contact.bodyB];
    if (bA == null || bB == null) continue;

    final normal = contact.manifold.normal;
    final tangent = Vector2(-normal.y, normal.x);

    final variation = e.speedVariation > 0
        ? (1.0 + (math.Random().nextDouble() - 0.5) * 2 * e.speedVariation)
        : 1.0;
    final targetSpeed = e.speed * variation;

    // Apply to dynamic body
    void applyToBody(PhysicsBody body) {
      if (body.bodyType != 0) return;
      final currentTangentVel = body.linearVelocity.dot(tangent);
      final speedDiff = targetSpeed - currentTangentVel;
      body.linearVelocity += tangent * (speedDiff * e.forceScale * dt);
    }

    applyToBody(bA);
    applyToBody(bB);
  }
}
