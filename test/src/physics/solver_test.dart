import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/src/physics/worker/engine/collision/solver.dart';
import 'package:goo2d/src/physics/worker/engine/collision/narrowphase.dart';
import 'package:goo2d/src/physics/worker/engine/collision/shape_intersect.dart';
import 'package:goo2d/src/physics/worker/engine/physics_engine.dart';
import 'package:goo2d/src/physics/worker/data/collider_shape_type.dart';

void main() {
  late PhysicsEngine engine;

  setUp(() {
    engine = PhysicsEngine();
  });

  int _createDynamic(double x, double y, {double mass = 1.0}) {
    final h = engine.createBody();
    final b = engine.getBody(h);
    b.position = Vector2(x, y);
    b.worldCenterOfMass = Vector2(x, y);
    b.bodyType = 0;
    b.mass = mass;
    b.inertia = mass * 0.5;
    return h;
  }

  int _createStatic(double x, double y) {
    final h = engine.createBody();
    final b = engine.getBody(h);
    b.position = Vector2(x, y);
    b.worldCenterOfMass = Vector2(x, y);
    b.bodyType = 1;
    return h;
  }

  group('buildConstraints', () {
    test('builds constraints from narrowphase contacts', () {
      final hA = _createDynamic(0, 0);
      final hB = _createStatic(2, 0);

      final cA = engine.createCollider(ColliderShapeType.circle, hA);
      final cB = engine.createCollider(ColliderShapeType.circle, hB);
      engine.getCollider(cA).friction = 0.5;
      engine.getCollider(cB).friction = 0.8;

      final contacts = [
        NarrowphaseContact(
          colliderA: cA,
          colliderB: cB,
          bodyA: hA,
          bodyB: hB,
          manifold: ContactManifold(
            Vector2(1, 0),
            [ContactVertex(Vector2(1, 0), 0.1)],
          ),
        ),
      ];

      final constraints = buildConstraints(engine, contacts);
      expect(constraints, hasLength(1));
      expect(constraints[0].points, hasLength(1));
      expect(constraints[0].friction, closeTo(0.632, 0.01));
    });
  });

  group('solveVelocityConstraints', () {
    test('dynamic body hitting static body decelerates along normal', () {
      final hA = _createDynamic(0, 1);
      engine.getBody(hA).linearVelocity = Vector2(0, -5);
      final hB = _createStatic(0, 0);

      final cA = engine.createCollider(ColliderShapeType.circle, hA);
      final cB = engine.createCollider(ColliderShapeType.circle, hB);
      // Set bounciness to 0 so velocity should be killed
      engine.getCollider(cA).bounciness = 0;
      engine.getCollider(cB).bounciness = 0;

      final contacts = [
        NarrowphaseContact(
          colliderA: cA,
          colliderB: cB,
          bodyA: hA,
          bodyB: hB,
          manifold: ContactManifold(
            Vector2(0, -1), // Normal from A to B (downward)
            [ContactVertex(Vector2(0, 0.5), 0.1)],
          ),
        ),
      ];

      final constraints = buildConstraints(engine, contacts);
      initializeConstraints(constraints, engine);

      // After solving, normal velocity should be reduced
      for (var i = 0; i < 10; i++) {
        solveVelocityConstraints(constraints, engine);
      }

      // The constraint should push velocity toward 0 (or positive)
      // along the normal direction (y)
      final vy = engine.getBody(hA).linearVelocity.y;
      // Should be >= 0 (stopped or bouncing)
      expect(vy, greaterThanOrEqualTo(-0.01));
    });

    test('two static bodies do not move', () {
      final hA = _createStatic(0, 0);
      final hB = _createStatic(1, 0);

      final cA = engine.createCollider(ColliderShapeType.circle, hA);
      final cB = engine.createCollider(ColliderShapeType.circle, hB);

      final contacts = [
        NarrowphaseContact(
          colliderA: cA,
          colliderB: cB,
          bodyA: hA,
          bodyB: hB,
          manifold: ContactManifold(
            Vector2(1, 0),
            [ContactVertex(Vector2(0.5, 0), 0.1)],
          ),
        ),
      ];

      final constraints = buildConstraints(engine, contacts);
      initializeConstraints(constraints, engine);
      solveVelocityConstraints(constraints, engine);

      expect(engine.getBody(hA).linearVelocity.length, closeTo(0, 1e-10));
      expect(engine.getBody(hB).linearVelocity.length, closeTo(0, 1e-10));
    });
  });

  group('solvePositionConstraints', () {
    test('reports convergence state', () {
      final hA = _createDynamic(0, 0);
      final hB = _createStatic(0.5, 0);

      final cA = engine.createCollider(ColliderShapeType.circle, hA);
      final cB = engine.createCollider(ColliderShapeType.circle, hB);

      final contacts = [
        NarrowphaseContact(
          colliderA: cA,
          colliderB: cB,
          bodyA: hA,
          bodyB: hB,
          manifold: ContactManifold(
            Vector2(1, 0),
            [ContactVertex(Vector2(0.25, 0), 0.5)],
          ),
        ),
      ];

      final constraints = buildConstraints(engine, contacts);
      initializeConstraints(constraints, engine);

      final result = solvePositionConstraints(constraints, engine, 0.2, 0.2);
      expect(result, isA<bool>());
    });
  });
}
