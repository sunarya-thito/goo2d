import 'package:flutter_test/flutter_test.dart';
import 'package:goo2d/src/physics/physics_world.dart';

void main() {
  group('PhysicsWorld', () {
    late PhysicsWorld world;

    setUp(() {
      world = PhysicsWorld();
      world.gravity = Offset.zero; // Disable gravity for pure collision tests
    });

    test('should detect collision between two boxes', () {
      // Arrange
      final b1 = PhysicsBody(id: 1, type: 0); // Dynamic
      b1.position = const Offset(0, 0);
      b1.setMass(1.0);
      final s1 = PhysicsBox(10, 10)..id = 1;
      s1.body = b1;

      final b2 = PhysicsBody(id: 2, type: 0); // Dynamic
      b2.position = const Offset(8, 0); // Should overlap by 2 units
      b2.setMass(1.0);
      final s2 = PhysicsBox(10, 10)..id = 2;
      s2.body = b2;

      world.bodies[1] = b1;
      world.bodies[2] = b2;

      // Act
      final result = world.step(1 / 60);

      // Assert
      expect(result.contacts, isNotEmpty);
      expect(result.contacts.first.manifold.depth, closeTo(2.0, 0.001));
    });

    test('should resolve collision between two dynamic bodies', () {
      // Arrange
      final b1 = PhysicsBody(id: 1, type: 0);
      b1.position = const Offset(0, 0);
      b1.velocity = const Offset(100, 0);
      b1.setMass(1.0);
      final s1 = PhysicsBox(10, 10)
        ..id = 1
        ..body = b1;
      s1.bounciness = 1.0;

      final b2 = PhysicsBody(id: 2, type: 0);
      b2.position = const Offset(8, 0);
      b2.velocity = const Offset(-100, 0);
      b2.setMass(1.0);
      final s2 = PhysicsBox(10, 10)
        ..id = 2
        ..body = b2;
      s2.bounciness = 1.0;

      world.bodies[1] = b1;
      world.bodies[2] = b2;

      // Act
      world.step(1 / 60);

      // Assert
      expect(b1.velocity.dx, lessThan(0));
      expect(b2.velocity.dx, greaterThan(0));
    });

    test('should correctly raycast against a circle', () {
      // Arrange
      final b1 = PhysicsBody(id: 1, type: 2); // Static
      b1.position = const Offset(100, 100);
      final s1 = PhysicsCircle(20)..id = 1;
      s1.body = b1;
      world.bodies[1] = b1;

      // Act
      final hit = world.raycast(const Offset(0, 100), const Offset(1, 0), 200);

      // Assert
      expect(hit, isNotNull);
      expect(hit!.point.dx, closeTo(80, 0.001));
      expect(hit.distance, closeTo(80, 0.001));
    });
  });
}
