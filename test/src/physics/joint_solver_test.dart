import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/src/physics/worker/engine/physics_engine.dart';
import 'package:goo2d/src/physics/worker/engine/physics_body.dart';
import 'package:goo2d/src/physics/worker/engine/collision/joint_solver.dart';

void main() {
  late PhysicsEngine engine;

  setUp(() {
    engine = PhysicsEngine();
  });

  PhysicsBody _makeDynamic(double x, double y, {double mass = 1.0}) {
    final h = engine.createBody();
    final b = engine.getBody(h);
    b.position = Vector2(x, y);
    b.worldCenterOfMass = Vector2(x, y);
    b.bodyType = 0;
    b.mass = mass;
    b.inertia = mass * 0.5;
    return b;
  }

  /// Simulates N physics frames with proper solve-then-integrate order.
  void _simulate(List<PhysicsBody> bodies, int frames, {int solveIters = 8}) {
    const dt = 1.0 / 60.0;
    for (var f = 0; f < frames; f++) {
      // Solve constraint iterations (velocity only)
      for (var i = 0; i < solveIters; i++) {
        solveJointConstraints(engine, dt);
      }
      // Integrate positions once per frame
      for (final b in bodies) {
        if (b.bodyType != 0) continue;
        b.position += b.linearVelocity * dt;
        b.worldCenterOfMass.setFrom(b.position);
      }
    }
  }

  group('distance joint', () {
    test('converges toward target distance', () {
      final bA = _makeDynamic(0, 0);
      final bB = _makeDynamic(5, 0);

      final jh = engine.createJoint(0, bA.handle);
      final joint = engine.getJoint(jh);
      joint.bodyHandleB = bB.handle;
      joint.distance = 3.0;
      joint.autoConfigureDistance = false;

      _simulate([bA, bB], 120);

      final dist = (bB.position - bA.position).length;
      expect(dist, closeTo(3.0, 1.0));
    });
  });

  group('fixed joint', () {
    test('keeps bodies close together', () {
      final bA = _makeDynamic(0, 0);
      final bB = _makeDynamic(0.5, 0);

      final jh = engine.createJoint(1, bA.handle);
      final joint = engine.getJoint(jh);
      joint.bodyHandleB = bB.handle;

      _simulate([bA, bB], 120);

      final dist = (bB.position - bA.position).length;
      expect(dist, lessThan(0.5));
    });
  });

  group('spring joint', () {
    test('oscillates around rest length', () {
      final bA = _makeDynamic(0, 0);
      final bB = _makeDynamic(5, 0);

      final jh = engine.createJoint(6, bA.handle);
      final joint = engine.getJoint(jh);
      joint.bodyHandleB = bB.handle;
      joint.distance = 3.0;
      joint.springFrequency = 2.0;
      joint.springDampingRatio = 0.5;

      _simulate([bA, bB], 180, solveIters: 4);

      final lastDist = (bB.position - bA.position).length;
      expect(lastDist, closeTo(3.0, 1.5));
    });
  });

  group('target joint', () {
    test('pulls body toward target', () {
      final bA = _makeDynamic(0, 0);

      final jh = engine.createJoint(7, bA.handle);
      final joint = engine.getJoint(jh);
      joint.target = Vector2(10, 0);
      joint.targetMaxForce = 100;

      _simulate([bA], 120);

      expect(bA.position.x, greaterThan(5));
    });
  });

  group('hinge joint motor', () {
    test('motor applies angular velocity', () {
      final bA = _makeDynamic(0, 0);
      final bB = _makeDynamic(2, 0);

      final jh = engine.createJoint(3, bA.handle);
      final joint = engine.getJoint(jh);
      joint.bodyHandleB = bB.handle;
      joint.useMotor = true;
      joint.motorSpeed = 90;
      joint.maxMotorTorque = 100;

      _simulate([bA, bB], 60);

      final relAngVel = bB.angularVelocity - bA.angularVelocity;
      expect(relAngVel.abs(), greaterThan(0));
    });
  });

  group('break detection', () {
    test('joint breaks when force exceeds threshold', () {
      final bA = _makeDynamic(0, 0);
      final bB = _makeDynamic(100, 0);

      final jh = engine.createJoint(0, bA.handle);
      final joint = engine.getJoint(jh);
      joint.bodyHandleB = bB.handle;
      joint.distance = 1.0;
      joint.autoConfigureDistance = false;
      joint.breakForce = 0.001;

      solveJointConstraints(engine, 1.0 / 60.0);

      expect(engine.joints.containsKey(jh), isFalse);
    });
  });
}
