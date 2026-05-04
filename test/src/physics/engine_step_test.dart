import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/src/physics/worker/engine/physics_engine.dart';
import 'package:goo2d/src/physics/worker/data/collider_shape_type.dart';

void main() {
  late PhysicsEngine engine;

  setUp(() {
    engine = PhysicsEngine();
    engine.gravity = Vector2(0, -9.81);
  });

  group('gravity', () {
    test('dynamic body falls under gravity', () {
      final h = engine.createBody();
      final b = engine.getBody(h);
      b.bodyType = 0;
      b.mass = 1.0;
      b.inertia = 0.5;
      b.position = Vector2(0, 10);

      // Step 60 frames at 60fps
      for (var i = 0; i < 60; i++) {
        engine.step(1.0 / 60.0);
      }

      // Should have fallen
      expect(b.position.y, lessThan(10));
      expect(b.linearVelocity.y, lessThan(0));
    });

    test('static body does not fall', () {
      final h = engine.createBody();
      final b = engine.getBody(h);
      b.bodyType = 1; // static
      b.position = Vector2(0, 10);

      for (var i = 0; i < 60; i++) {
        engine.step(1.0 / 60.0);
      }

      expect(b.position.y, closeTo(10, 1e-10));
    });

    test('gravityScale = 0 means no gravity', () {
      final h = engine.createBody();
      final b = engine.getBody(h);
      b.bodyType = 0;
      b.mass = 1.0;
      b.inertia = 0.5;
      b.gravityScale = 0;
      b.position = Vector2(0, 10);

      for (var i = 0; i < 60; i++) {
        engine.step(1.0 / 60.0);
      }

      expect(b.position.y, closeTo(10, 1e-6));
    });
  });

  group('damping', () {
    test('linear damping slows body', () {
      final h = engine.createBody();
      final b = engine.getBody(h);
      b.bodyType = 0;
      b.mass = 1.0;
      b.inertia = 0.5;
      b.linearDamping = 5.0;
      b.gravityScale = 0;
      b.linearVelocity = Vector2(10, 0);

      for (var i = 0; i < 120; i++) {
        engine.step(1.0 / 60.0);
      }

      expect(b.linearVelocity.x, lessThan(1));
    });

    test('angular damping slows rotation', () {
      final h = engine.createBody();
      final b = engine.getBody(h);
      b.bodyType = 0;
      b.mass = 1.0;
      b.inertia = 0.5;
      b.angularDamping = 5.0;
      b.gravityScale = 0;
      b.angularVelocity = 360;

      for (var i = 0; i < 120; i++) {
        engine.step(1.0 / 60.0);
      }

      expect(b.angularVelocity.abs(), lessThan(10));
    });
  });

  group('sleep', () {
    test('stationary body falls asleep', () {
      final h = engine.createBody();
      final b = engine.getBody(h);
      b.bodyType = 0;
      b.mass = 1.0;
      b.inertia = 0.5;
      b.gravityScale = 0;
      b.linearVelocity = Vector2.zero();
      engine.timeToSleep = 0.1;

      // Step enough for sleep timer
      for (var i = 0; i < 30; i++) {
        engine.step(1.0 / 60.0);
      }

      expect(b.isSleeping, isTrue);
    });

    test('neverSleep mode prevents sleeping', () {
      final h = engine.createBody();
      final b = engine.getBody(h);
      b.bodyType = 0;
      b.mass = 1.0;
      b.inertia = 0.5;
      b.gravityScale = 0;
      b.sleepMode = 2; // neverSleep
      engine.timeToSleep = 0.01;

      for (var i = 0; i < 60; i++) {
        engine.step(1.0 / 60.0);
      }

      expect(b.isSleeping, isFalse);
    });
  });

  group('velocity clamping', () {
    test('linear velocity clamped to maxTranslationSpeed', () {
      final h = engine.createBody();
      final b = engine.getBody(h);
      b.bodyType = 0;
      b.mass = 1.0;
      b.inertia = 0.5;
      b.gravityScale = 0;
      b.linearVelocity = Vector2(99999, 0);
      engine.maxTranslationSpeed = 100;

      engine.step(1.0 / 60.0);

      expect(b.linearVelocity.length, closeTo(100, 0.1));
    });

    test('angular velocity clamped to maxRotationSpeed', () {
      final h = engine.createBody();
      final b = engine.getBody(h);
      b.bodyType = 0;
      b.mass = 1.0;
      b.inertia = 0.5;
      b.gravityScale = 0;
      b.angularVelocity = 99999;
      engine.maxRotationSpeed = 500;

      engine.step(1.0 / 60.0);

      expect(b.angularVelocity.abs(), closeTo(500, 0.1));
    });
  });

  group('circle collision', () {
    test('two circles collide and separate', () {
      engine.gravity = Vector2.zero();

      final hA = engine.createBody();
      final bA = engine.getBody(hA);
      bA.bodyType = 0;
      bA.mass = 1.0;
      bA.inertia = 0.5;
      bA.position = Vector2(0, 0);
      bA.linearVelocity = Vector2(5, 0);

      final hB = engine.createBody();
      final bB = engine.getBody(hB);
      bB.bodyType = 0;
      bB.mass = 1.0;
      bB.inertia = 0.5;
      bB.position = Vector2(1.5, 0);
      bB.linearVelocity = Vector2(-5, 0);

      final chA = engine.createCollider(ColliderShapeType.circle, hA);
      engine.getCollider(chA).circleRadius = 1.0;
      final chB = engine.createCollider(ColliderShapeType.circle, hB);
      engine.getCollider(chB).circleRadius = 1.0;

      for (var i = 0; i < 120; i++) {
        engine.step(1.0 / 60.0);
      }

      // Bodies should have bounced apart
      final dist = (bB.position - bA.position).length;
      expect(dist, greaterThanOrEqualTo(1.5));
    });
  });

  group('CRUD', () {
    test('create and destroy body', () {
      final h = engine.createBody();
      expect(engine.bodies.containsKey(h), isTrue);
      engine.destroyBody(h);
      expect(engine.bodies.containsKey(h), isFalse);
    });

    test('create and destroy collider', () {
      final bh = engine.createBody();
      final ch = engine.createCollider(ColliderShapeType.circle, bh);
      expect(engine.colliders.containsKey(ch), isTrue);
      engine.destroyCollider(ch);
      expect(engine.colliders.containsKey(ch), isFalse);
    });

    test('create and destroy joint', () {
      final bh = engine.createBody();
      final jh = engine.createJoint(0, bh);
      expect(engine.joints.containsKey(jh), isTrue);
      engine.destroyJoint(jh);
      expect(engine.joints.containsKey(jh), isFalse);
    });

    test('create and destroy effector', () {
      final eh = engine.createEffector(0);
      expect(engine.effectors.containsKey(eh), isTrue);
      engine.destroyEffector(eh);
      expect(engine.effectors.containsKey(eh), isFalse);
    });
  });
}
