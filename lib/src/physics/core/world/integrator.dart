import 'package:flutter/painting.dart';
import 'package:goo2d/src/physics/core/physics_body.dart';

/// Integrates the state of all bodies in the world.
void integrateBodies(Map<int, PhysicsBody> bodies, Offset gravity, double dt) {
  for (final body in bodies.values) {
    body.integrate(dt, gravity);
  }
}
