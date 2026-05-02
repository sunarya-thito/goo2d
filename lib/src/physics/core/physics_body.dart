import 'package:flutter/painting.dart';
import 'package:goo2d/src/physics/core/physics_shape.dart';

class PhysicsBody {
  final int id;
  int type; // 0: dynamic, 1: kinematic, 2: static
  Offset position = Offset.zero;
  double rotation = 0.0;
  Offset velocity = Offset.zero;
  double angularVelocity = 0.0;
  double mass = 1.0;
  double invMass = 1.0;
  double inertia = 1.0;
  double invInertia = 1.0;
  double gravityScale = 1.0;
  double drag = 0.0;
  double angularDrag = 0.05;

  bool _freezeRotation = false;
  bool get freezeRotation => _freezeRotation;
  set freezeRotation(bool value) {
    _freezeRotation = value;
    setInertia(inertia);
  }

  Offset force = Offset.zero;
  double torque = 0.0;
  final List<PhysicsShape> shapes = [];
  PhysicsBody({required this.id, this.type = 0});
  void applyForce(Offset f) {
    if (type != 0) return;
    force += f;
  }

  void applyImpulse(Offset j) {
    if (type != 0) return;
    velocity += j * invMass;
  }

  void applyTorque(double t) {
    if (type != 0) return;
    torque += t;
  }

  void applyAngularImpulse(double j) {
    if (type != 0) return;
    angularVelocity += j * invInertia;
  }

  void setMass(double m) {
    mass = m;
    invMass = m > 0 ? 1.0 / m : 0.0;
  }

  void setInertia(double i) {
    inertia = i;
    invInertia = i > 0 && !freezeRotation ? 1.0 / i : 0.0;
  }

  void integrate(double dt, Offset gravity) {
    if (type != 0) return; // Only dynamic bodies integrate

    // Apply accumulated forces
    velocity += (force * invMass + gravity * gravityScale) * dt;
    angularVelocity += torque * invInertia * dt;

    // Apply drag
    velocity *= (1.0 - drag * dt);
    angularVelocity *= (1.0 - angularDrag * dt);

    // Apply velocity
    position += velocity * dt;
    rotation += angularVelocity * dt;

    // Reset forces
    force = Offset.zero;
    torque = 0.0;
  }
}
