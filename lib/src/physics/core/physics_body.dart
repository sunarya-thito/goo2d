import 'package:flutter/painting.dart';
import 'package:goo2d/src/physics/core/physics_shape.dart';

/// Represents a physical object in the [PhysicsWorld].
/// 
/// A [PhysicsBody] holds physical properties like mass, velocity, and 
/// forces, and contains one or more [PhysicsShape]s that define its volume. 
/// It is the primary unit of simulation in the engine's internal physics.
/// 
/// ```dart
/// final body = PhysicsBody(id: 1, type: 0);
/// body.position = Offset(100, 100);
/// ```
class PhysicsBody {
  /// Unique identifier for this body.
  /// 
  /// Used by the [PhysicsSystem] to track bodies across frames and 
  /// synchronize their state with the worker.
  final int id;
  /// The type of body (0: dynamic, 1: kinematic, 2: static).
  /// 
  /// 0: Dynamic bodies respond to forces and gravity.
  /// 1: Kinematic bodies move only via velocity.
  /// 2: Static bodies are immovable.
  /// 
  /// The type determines which integration path the [PhysicsWorld] 
  /// uses for the body.
  int type; // 0: dynamic, 1: kinematic, 2: static

  /// World-space position.
  /// 
  /// Represents the center of mass of the body. Updated by the 
  /// integrator every step based on velocity and forces.
  Offset position = Offset.zero;
  /// Rotation in radians.
  /// 
  /// The orientation of the body in world space. Affects the 
  /// orientation of all attached [PhysicsShape]s.
  double rotation = 0.0;
  /// Linear velocity in pixels per second.
  /// 
  /// The current speed and direction of the body. Subject to 
  /// [drag] and external impulses.
  Offset velocity = Offset.zero;
  /// Angular velocity in radians per second.
  /// 
  /// The current rotational speed. Subject to [angularDrag] and 
  /// torque-induced acceleration.
  double angularVelocity = 0.0;

  /// The mass of the body.
  /// 
  /// Determines resistance to linear acceleration. Must be positive 
  /// for dynamic bodies to avoid infinite acceleration.
  double mass = 1.0;
  /// The inverse mass (1/mass). Used to optimize integration.
  /// 
  /// Cached to avoid division in the hot path of the simulation loop.
  double invMass = 1.0;
  /// The moment of inertia.
  /// 
  /// Determines resistance to rotational acceleration based on mass 
  /// distribution relative to the center.
  double inertia = 1.0;
  /// The inverse moment of inertia (1/inertia).
  /// 
  /// Used for rotational integration. Setting this to 0.0 effectively 
  /// freezes rotation.
  double invInertia = 1.0;

  /// Multiplier for the global gravity vector.
  /// 
  /// Allows individual bodies to fall faster or slower than the 
  /// world's base gravity setting.
  double gravityScale = 1.0;
  /// Linear damping coefficient.
  /// 
  /// Simulates air resistance or friction. Gradually reduces linear 
  /// velocity over time.
  double drag = 0.0;
  /// Angular damping coefficient.
  /// 
  /// Simulates rotational resistance. Gradually reduces angular 
  /// velocity over time.
  double angularDrag = 0.05;

  bool _freezeRotation = false;
  /// Whether the body's rotation is locked.
  /// 
  /// When true, the body will not rotate regardless of forces or impulses applied.
  bool get freezeRotation => _freezeRotation;

  /// Sets whether the body's rotation is frozen.
  /// 
  /// Updates the internal inertia state to reflect the new rotation constraint.
  /// 
  /// * [value]: True to lock rotation, false to allow it.
  set freezeRotation(bool value) {
    _freezeRotation = value;
    setInertia(inertia);
  }

  /// Accumulated linear force for the current step.
  /// 
  /// Forces are reset at the end of each [integrate] call.
  Offset force = Offset.zero;
  /// Accumulated torque for the current step.
  /// 
  /// Torques affect angular acceleration and are reset every step.
  double torque = 0.0;

  /// The list of geometric shapes attached to this body.
  /// 
  /// Each shape defines a portion of the body's physical volume and 
  /// material properties like friction and bounciness.
  final List<PhysicsShape> shapes = [];

  /// Creates a [PhysicsBody] with a unique [id].
  /// 
  /// * [id]: The unique identifier for this body.
  /// * [type]: The body type (dynamic, kinematic, or static).
  PhysicsBody({required this.id, this.type = 0});

  /// Adds a [force] to be applied during the next integration step.
  /// 
  /// Only dynamic bodies respond to force accumulation.
  /// 
  /// * [f]: The force vector to apply.
  void applyForce(Offset f) {
    if (type != 0) return;
    force += f;
  }

  /// Applies an instantaneous change in linear velocity.
  /// 
  /// Impulses are applied directly to the velocity based on the inverse mass.
  /// 
  /// * [j]: The impulse vector to apply.
  void applyImpulse(Offset j) {
    if (type != 0) return;
    velocity += j * invMass;
  }

  /// Adds [torque] to be applied during the next integration step.
  /// 
  /// Only dynamic bodies respond to torque accumulation.
  /// 
  /// * [t]: The torque value to apply.
  void applyTorque(double t) {
    if (type != 0) return;
    torque += t;
  }

  /// Applies an instantaneous change in angular velocity.
  /// 
  /// The rotational velocity is modified based on the impulse and 
  /// the current [invInertia].
  /// 
  /// * [j]: The angular impulse to apply.
  void applyAngularImpulse(double j) {
    if (type != 0) return;
    angularVelocity += j * invInertia;
  }

  /// Sets the [mass] and updates the [invMass].
  /// 
  /// Providing a mass of 0.0 effectively makes the body's mass infinite, 
  /// preventing linear acceleration.
  /// 
  /// * [m]: The new mass value.
  void setMass(double m) {
    mass = m;
    invMass = m > 0 ? 1.0 / m : 0.0;
  }

  /// Sets the rotational [inertia] and updates the [invInertia].
  /// 
  /// If [freezeRotation] is active, the [invInertia] will be set to 0.0 
  /// regardless of the input value.
  /// 
  /// * [i]: The new moment of inertia.
  void setInertia(double i) {
    inertia = i;
    invInertia = i > 0 && !freezeRotation ? 1.0 / i : 0.0;
  }

  /// Advances the body's state by a single time step [dt].
  /// 
  /// This method applies forces, gravity, and drag to update velocities, 
  /// which are then used to increment [position] and [rotation].
  /// 
  /// * [dt]: The duration of the simulation step.
  /// * [gravity]: The global gravity vector to apply.
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
