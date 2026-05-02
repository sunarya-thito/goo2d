import 'package:flutter_test/flutter_test.dart';
import 'package:goo2d/src/physics/core/physics_body.dart';
import 'package:goo2d/src/physics/core/physics_joint.dart';

void main() {
  group('Core Physics Joints', () {
    late Map<int, PhysicsBody> bodies;

    setUp(() {
      bodies = {
        1: PhysicsBody(id: 1, type: 0)..position = const Offset(0, 0),
        2: PhysicsBody(id: 2, type: 0)..position = const Offset(100, 0),
      };
    });

    test('DistanceJoint constraint', () {
      final joint = DistanceJoint(
        id: 1,
        bodyAId: 1,
        bodyBId: 2,
        anchorA: Offset.zero,
        anchorB: Offset.zero,
        length: 50.0,
      );

      // Current distance is 100. Length is 50.
      // After one step, bodies should move towards each other.
      joint.solveVelocityConstraints(bodies, 1.0 / 60.0);
      
      expect(bodies[1]!.velocity.dx, greaterThan(0));
      expect(bodies[2]!.velocity.dx, lessThan(0));
    });

    test('HingeJoint constraint', () {
      final joint = HingeJoint(
        id: 1,
        bodyAId: 1,
        bodyBId: 2,
        anchorA: const Offset(10, 0),
        anchorB: const Offset(-10, 0),
      );

      bodies[2]!.position = const Offset(30, 0); // Distance between anchors is 10.
      joint.solveVelocityConstraints(bodies, 1.0 / 60.0);
      
      expect(bodies[1]!.velocity.dx, greaterThan(0));
      expect(bodies[2]!.velocity.dx, lessThan(0));
    });

    test('SpringJoint constraint', () {
      final joint = SpringJoint(
        id: 1,
        bodyAId: 1,
        bodyBId: 2,
        anchorA: Offset.zero,
        anchorB: Offset.zero,
        restLength: 50.0,
        stiffness: 100.0,
        damping: 10.0,
      );

      joint.solveVelocityConstraints(bodies, 1.0 / 60.0);
      
      expect(bodies[1]!.velocity.dx, greaterThan(0));
      expect(bodies[2]!.velocity.dx, lessThan(0));
    });

    test('SliderJoint constraint', () {
      final joint = SliderJoint(
        id: 1,
        bodyAId: 1,
        bodyBId: 2,
        anchorA: Offset.zero,
        anchorB: Offset.zero,
        axis: const Offset(1, 0), // Move only on X
      );

      bodies[2]!.velocity = const Offset(10, 10);
      joint.solveVelocityConstraints(bodies, 1.0 / 60.0);
      
      // Y velocity should be zeroed out (roughly)
      expect(bodies[2]!.velocity.dy, lessThan(10.0));
    });

    test('FixedJoint constraint', () {
      final joint = FixedJoint(
        id: 1,
        bodyAId: 1,
        bodyBId: 2,
        localAnchorA: Offset.zero,
        localAnchorB: Offset.zero,
        referenceAngle: 0.0,
      );

      bodies[2]!.rotation = 0.5;
      joint.solveVelocityConstraints(bodies, 1.0 / 60.0);
      
      expect(bodies[2]!.angularVelocity, lessThan(0));
    });

    test('FrictionJoint constraint', () {
      final joint = FrictionJoint(
        id: 1,
        bodyAId: 1,
        bodyBId: 2,
        localAnchorA: Offset.zero,
        localAnchorB: Offset.zero,
        maxForce: 100.0,
        maxTorque: 10.0,
      );

      bodies[2]!.velocity = const Offset(10, 0);
      joint.solveVelocityConstraints(bodies, 1.0 / 60.0);
      
      expect(bodies[2]!.velocity.dx, lessThan(10.0));
    });

    test('RelativeJoint constraint', () {
      final joint = RelativeJoint(
        id: 1,
        bodyAId: 1,
        bodyBId: 2,
        linearOffset: const Offset(50, 0),
        angularOffset: 0.0,
        maxForce: 1000.0,
        maxTorque: 1000.0,
      );

      joint.solveVelocityConstraints(bodies, 1.0 / 60.0);
      
      // bodies are at 0 and 100. Offset is 50. 
      // bodyB should move towards 50.
      expect(bodies[2]!.velocity.dx, lessThan(0));
    });

    test('TargetJoint constraint', () {
      final joint = TargetJoint(
        id: 1,
        bodyAId: 1,
        bodyBId: -1,
        target: const Offset(50, 0),
        maxForce: 1000.0,
        frequency: 5.0,
        dampingRatio: 0.7,
      );

      joint.solveVelocityConstraints(bodies, 1.0 / 60.0);
      
      expect(bodies[1]!.velocity.dx, greaterThan(0));
    });
  });
}
