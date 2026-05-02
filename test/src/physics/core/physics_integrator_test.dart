import 'package:flutter_test/flutter_test.dart';
import 'package:goo2d/src/physics/core/physics_body.dart';
import 'package:goo2d/src/physics/core/world/integrator.dart';

void main() {
  group('Physics Integrator', () {
    test('Gravity application', () {
      final body = PhysicsBody(id: 1, type: 0); // Dynamic
      body.position = Offset.zero;
      body.velocity = Offset.zero;
      
      final gravity = const Offset(0, 10);
      integrateBodies({1: body}, gravity, 1.0);
      
      // velocity = (force/mass + gravity) * dt = (0 + 10) * 1 = 10
      // position = velocity * dt = 10 * 1 = 10
      expect(body.velocity.dy, 10.0);
      expect(body.position.dy, 10.0);
    });

    test('Force application', () {
      final body = PhysicsBody(id: 1, type: 0)..setMass(2.0);
      body.applyForce(const Offset(10, 0));
      
      integrateBodies({1: body}, Offset.zero, 1.0);
      
      // acc = force / mass = 10 / 2 = 5
      // velocity = 5 * 1 = 5
      expect(body.velocity.dx, 5.0);
      expect(body.force, Offset.zero); // Reset after integration
    });

    test('Drag application', () {
      final body = PhysicsBody(id: 1, type: 0)..velocity = const Offset(10, 0)..drag = 0.5;
      
      integrateBodies({1: body}, Offset.zero, 1.0);
      
      // velocity *= (1.0 - drag * dt) = 10 * (1.0 - 0.5 * 1) = 5
      expect(body.velocity.dx, 5.0);
    });

    test('Torque and Rotation', () {
      final body = PhysicsBody(id: 1, type: 0)..setInertia(2.0)..angularDrag = 0.0;
      body.applyTorque(10.0);
      
      integrateBodies({1: body}, Offset.zero, 1.0);
      
      // angAcc = torque / inertia = 10 / 2 = 5
      // angVel = 5 * 1 = 5
      expect(body.angularVelocity, 5.0);
      expect(body.rotation, 5.0);
    });

    test('Freeze Rotation', () {
      final body = PhysicsBody(id: 1, type: 0)..freezeRotation = true;
      body.applyTorque(10.0);
      
      integrateBodies({1: body}, Offset.zero, 1.0);
      
      expect(body.angularVelocity, 0.0);
      expect(body.rotation, 0.0);
    });

    test('Static body does not move', () {
      final body = PhysicsBody(id: 1, type: 2); // Static
      body.velocity = const Offset(10, 10);
      body.applyForce(const Offset(100, 100));
      
      integrateBodies({1: body}, const Offset(0, 10), 1.0);
      
      expect(body.position, Offset.zero);
      expect(body.velocity, const Offset(10, 10)); // Velocity stays if set manually, but integration doesn't touch it
    });
  });
}
