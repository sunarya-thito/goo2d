import 'package:flutter/painting.dart';
import 'package:goo2d/src/physics/core/physics_body.dart';

void integrateBodies(Map<int, PhysicsBody> bodies, Offset gravity, double dt) {
  for (final body in bodies.values) {
    body.integrate(dt, gravity);
  }
}
