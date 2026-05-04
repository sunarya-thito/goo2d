import 'package:goo2d/src/physics/worker/engine/physics_engine.dart';
import 'package:goo2d/src/physics/worker/engine/collision/broadphase.dart';
import 'package:goo2d/src/physics/worker/engine/collision/narrowphase.dart';
import 'package:goo2d/src/physics/worker/engine/collision/solver.dart';
import 'package:goo2d/src/physics/worker/engine/collision/joint_solver.dart';
import 'package:goo2d/src/physics/worker/engine/collision/effector_apply.dart';

/// Simulation step logic, extracted from [PhysicsEngine].
bool engineStep(PhysicsEngine engine, double dt, int layers) {
  if (dt <= 0) return false;

  // 1. Apply effector forces
  applyEffectors(engine, dt);

  // 2. Apply gravity and accumulated forces
  for (final body in engine.bodies.values) {
    if (!body.simulated || body.bodyType != 0) continue;
    if (body.isSleeping) continue;

    body.linearVelocity += engine.gravity * body.gravityScale * dt;
    if (body.mass > 0) {
      body.linearVelocity += body.totalForce * (dt / body.mass);
    }
    if (body.inertia > 0) {
      body.angularVelocity += body.totalTorque * (dt / body.inertia);
    }
    body.totalForce.setZero();
    body.totalTorque = 0;
  }

  // 3. Apply damping
  for (final body in engine.bodies.values) {
    if (!body.simulated || body.bodyType != 0) continue;
    if (body.isSleeping) continue;
    body.linearVelocity *= 1.0 / (1.0 + dt * body.linearDamping);
    body.angularVelocity *= 1.0 / (1.0 + dt * body.angularDamping);
  }

  // 4. Broadphase — find potential collision pairs
  final pairs = findBroadphasePairs(engine);

  // 5. Narrowphase — generate contact manifolds
  final npContacts = resolveNarrowphase(engine, pairs);

  // 6. Build and solve contact constraints
  if (npContacts.isNotEmpty) {
    final constraints = buildConstraints(engine, npContacts);
    initializeConstraints(constraints, engine);

    // Velocity iterations (contacts + joints)
    for (var i = 0; i < engine.velocityIterations; i++) {
      solveVelocityConstraints(constraints, engine);
      solveJointConstraints(engine, dt);
    }

    // 7. Integrate positions
    _integratePositions(engine, dt);

    // Position iterations
    for (var i = 0; i < engine.positionIterations; i++) {
      final solved = solvePositionConstraints(
        constraints, engine,
        engine.baumgarteScale, engine.maxLinearCorrection,
      );
      if (solved) break;
    }
  } else {
    // No contacts — still solve joints
    for (var i = 0; i < engine.velocityIterations; i++) {
      solveJointConstraints(engine, dt);
    }

    // 7. Integrate positions
    _integratePositions(engine, dt);
  }

  // 8. Update active contacts + trigger tracking
  engine.activeContacts
    ..clear()
    ..addAll(npContacts);

  engine.contactTracker.update(npContacts, (handle) {
    final c = engine.colliders[handle];
    return c != null && c.isTrigger;
  });

  // 9. Sleep management
  _manageSleep(engine, dt);

  return true;
}

void _integratePositions(PhysicsEngine engine, double dt) {
  for (final body in engine.bodies.values) {
    if (!body.simulated || body.bodyType == 1) continue;
    if (body.isSleeping) continue;

    final linSpeed = body.linearVelocity.length;
    if (linSpeed > engine.maxTranslationSpeed) {
      body.linearVelocity *= engine.maxTranslationSpeed / linSpeed;
    }
    if (body.angularVelocity.abs() > engine.maxRotationSpeed) {
      body.angularVelocity = body.angularVelocity.sign * engine.maxRotationSpeed;
    }

    body.position += body.linearVelocity * dt;
    body.rotation += body.angularVelocity * dt;
    body.worldCenterOfMass
      ..setFrom(body.position)
      ..add(body.centerOfMass);
  }
}

void _manageSleep(PhysicsEngine engine, double dt) {
  for (final body in engine.bodies.values) {
    if (!body.simulated || body.bodyType != 0) continue;
    if (body.sleepMode == 2) continue; // neverSleep

    final linSq = body.linearVelocity.length2;
    final angSq = body.angularVelocity * body.angularVelocity;
    final linTol = engine.linearSleepTolerance * engine.linearSleepTolerance;
    final angTol = engine.angularSleepTolerance * engine.angularSleepTolerance;

    if (linSq > linTol || angSq > angTol) {
      body.sleepTime = 0;
      if (body.isSleeping) body.wake();
    } else {
      body.sleepTime += dt;
      if (body.sleepTime >= engine.timeToSleep && body.isAwake) {
        body.putToSleep();
        body.linearVelocity.setZero();
        body.angularVelocity = 0;
      }
    }
  }
}
