import 'package:flutter_test/flutter_test.dart';
import 'package:goo2d/src/physics/core/physics_body.dart';
import 'package:goo2d/src/physics/core/physics_shape.dart';
import 'package:goo2d/src/physics/core/world/collision/narrow_phase.dart';

void main() {
  group('Collision Narrow Phase', () {
    test('Circle vs Circle collision', () {
      final bA = PhysicsBody(id: 1, type: 0)..position = const Offset(0, 0);
      final sA = PhysicsCircle(10.0)..body = bA;

      final bB = PhysicsBody(id: 2, type: 0)..position = const Offset(15, 0);
      final sB = PhysicsCircle(10.0)..body = bB;

      final manifold = checkCollision(sA, bA, sB, bB);
      expect(manifold, isNotNull);
      expect(manifold!.depth, closeTo(5.0, 0.001));
      expect(manifold.normal.dx, closeTo(1.0, 0.001));
      expect(manifold.normal.dy, 0.0);
    });

    test('Circle vs Circle no collision', () {
      final bA = PhysicsBody(id: 1, type: 0)..position = const Offset(0, 0);
      final sA = PhysicsCircle(10.0)..body = bA;

      final bB = PhysicsBody(id: 2, type: 0)..position = const Offset(25, 0);
      final sB = PhysicsCircle(10.0)..body = bB;

      final manifold = checkCollision(sA, bA, sB, bB);
      expect(manifold, isNull);
    });

    test('Box vs Box collision', () {
      final bA = PhysicsBody(id: 1, type: 0)..position = const Offset(0, 0);
      final sA = PhysicsBox(20, 20)..body = bA;

      final bB = PhysicsBody(id: 2, type: 0)..position = const Offset(15, 0);
      final sB = PhysicsBox(20, 20)..body = bB;

      final manifold = checkCollision(sA, bA, sB, bB);
      expect(manifold, isNotNull);
      expect(manifold!.depth, closeTo(5.0, 0.001));
      expect(manifold.normal.dx, closeTo(1.0, 0.001));
    });

    test('Box vs Circle collision', () {
      final bA = PhysicsBody(id: 1, type: 0)..position = const Offset(0, 0);
      final sA = PhysicsBox(20, 20)..body = bA;

      final bB = PhysicsBody(id: 2, type: 0)..position = const Offset(15, 0);
      final sB = PhysicsCircle(10.0)..body = bB;

      final manifold = checkCollision(sA, bA, sB, bB);
      expect(manifold, isNotNull);
      expect(manifold!.depth, closeTo(5.0, 0.001));
      expect(manifold.normal.dx, closeTo(1.0, 0.001));
    });

    test('Capsule vs Circle collision', () {
      final bA = PhysicsBody(id: 1, type: 0)..position = const Offset(0, 0);
      final sA = PhysicsCapsule(10, 40, CapsuleDirection.vertical)..body = bA;

      final bB = PhysicsBody(id: 2, type: 0)..position = const Offset(0, 25);
      final sB = PhysicsCircle(10.0)..body = bB;

      final manifold = checkCollision(sA, bA, sB, bB);
      expect(manifold, isNotNull);
      expect(manifold!.depth, closeTo(5.0, 0.001));
      expect(manifold.normal.dy, closeTo(1.0, 0.001));
    });

    test('Capsule vs Box collision', () {
      final bA = PhysicsBody(id: 1, type: 0)..position = const Offset(0, 0);
      final sA = PhysicsCapsule(10, 40, CapsuleDirection.vertical)..body = bA;

      final bB = PhysicsBody(id: 2, type: 0)..position = const Offset(15, 0);
      final sB = PhysicsBox(20, 20)..body = bB;

      final manifold = checkCollision(sA, bA, sB, bB);
      expect(manifold, isNotNull);
      expect(manifold!.depth, closeTo(5.0, 0.001));
      expect(manifold.normal.dx, closeTo(1.0, 0.001));
    });

    test('Capsule vs Polygon collision', () {
      final bA = PhysicsBody(id: 1, type: 0)..position = const Offset(0, 0);
      final sA = PhysicsCapsule(10, 40, CapsuleDirection.vertical)..body = bA;

      final bB = PhysicsBody(id: 2, type: 0)..position = const Offset(15, 0);
      final sB = PhysicsPolygon([
        const Offset(-10, -10),
        const Offset(10, -10),
        const Offset(10, 10),
        const Offset(-10, 10),
      ])..body = bB;

      final manifold = checkCollision(sA, bA, sB, bB);
      expect(manifold, isNotNull);
      expect(manifold!.depth, closeTo(5.0, 0.001));
    });

    test('Polygon vs Box collision', () {
      final bA = PhysicsBody(id: 1, type: 0)..position = const Offset(0, 0);
      final sA = PhysicsPolygon([
        const Offset(-10, -10),
        const Offset(10, -10),
        const Offset(10, 10),
        const Offset(-10, 10),
      ])..body = bA;

      final bB = PhysicsBody(id: 2, type: 0)..position = const Offset(15, 0);
      final sB = PhysicsBox(20, 20)..body = bB;

      final manifold = checkCollision(sA, bA, sB, bB);
      expect(manifold, isNotNull);
      expect(manifold!.depth, closeTo(5.0, 0.001));
    });

    test('Flipped manifold check', () {
      final bA = PhysicsBody(id: 1, type: 0)..position = const Offset(15, 0);
      final sA = PhysicsCircle(10.0)..body = bA;

      final bB = PhysicsBody(id: 2, type: 0)..position = const Offset(0, 0);
      final sB = PhysicsBox(20, 20)..body = bB;

      final manifold = checkCollision(sA, bA, sB, bB);
      expect(manifold, isNotNull);
      expect(manifold!.depth, closeTo(5.0, 0.001));
      expect(manifold.normal.dx, closeTo(-1.0, 0.001));
    });
  });
}
