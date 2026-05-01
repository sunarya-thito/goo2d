import 'package:goo2d/src/physics/core/physics_body.dart';
import 'package:goo2d/src/physics/core/physics_joint.dart';

/// Resolves velocity constraints for all joints in the world.
void resolveJointConstraints(
  Map<int, Joint> joints,
  Map<int, PhysicsBody> bodies,
  double dt,
) {
  const iterations = 4;
  for (int i = 0; i < iterations; i++) {
    for (final joint in joints.values) {
      joint.solveVelocityConstraints(bodies, dt);
    }
  }
}
