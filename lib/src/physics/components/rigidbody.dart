import 'package:flutter/painting.dart';
import 'package:goo2d/goo2d.dart';

/// Defines how a [Rigidbody] interacts with the physics simulation.
/// 
/// The type determines whether an object responds to external forces and 
/// gravity, or if its movement is controlled exclusively via script.
enum RigidbodyType {
  /// Fully simulated by the physics engine. 
  /// 
  /// Reacts to forces, gravity, and collisions. This is the default type 
  /// for objects that should bounce and fall.
  dynamic,
  
  /// Not affected by forces or gravity. 
  /// 
  /// Only moves via its [Rigidbody.velocity]. Often used for moving 
  /// platforms or player-controlled characters that require precise movement.
  kinematic,
  
  /// Does not move and is not affected by forces. 
  /// 
  /// Acts as a solid obstacle for other bodies. Use this for floors, 
  /// walls, and other unmovable scenery.
  static,
}

/// A component that allows a [GameObject] to participate in physics simulation.
/// 
/// [Rigidbody] enables an object to have mass, velocity, drag, and gravity. 
/// For an object to collide with others, it should typically have a [Rigidbody] 
/// (for dynamic movement) or be marked as static (for background geometry).
/// 
/// ```dart
/// class FallingBox extends GameObject {
///   @override
///   void onAwake() {
///     addComponent(BoxCollider()..size = Size(50, 50));
///     addComponent(Rigidbody()
///       ..mass = 5.0
///       ..gravityScale = 2.0);
///   }
/// }
/// ```
class Rigidbody extends Component with LifecycleListener {
  /// The movement type of the body (dynamic, kinematic, or static).
  /// 
  /// Changing the type will update the body's behavior in the simulation.
  RigidbodyType type = RigidbodyType.dynamic;

  double _mass = 1.0;
  double _drag = 0.0;
  double _angularDrag = 0.05;
  double _gravityScale = 1.0;
  bool _freezeRotation = false;

  /// The simulated mass of the object.
  /// 
  /// Higher mass requires more force to accelerate and affects 
  /// collision energy transfer.
  double get mass => _mass;

  /// Sets the simulated mass of the object.
  /// 
  /// Values must be greater than zero. Notifies the physics engine of 
  /// the change immediately.
  /// 
  /// * [value]: The mass in units.
  set mass(double value) {
    if (_mass == value) return;
    _mass = value;
    if (isAttached) game.physics.updateRigidbody(this);
  }

  /// Resistance to linear movement.
  /// 
  /// Simulates air resistance or friction. Higher values cause the 
  /// object to slow down faster.
  double get drag => _drag;

  /// Sets the linear drag coefficient.
  /// 
  /// Updates the physical properties of the body in the background 
  /// simulation.
  /// 
  /// * [value]: The friction/resistance value.
  set drag(double value) {
    if (_drag == value) return;
    _drag = value;
    if (isAttached) game.physics.updateRigidbody(this);
  }

  /// Resistance to rotational movement.
  /// 
  /// Higher values cause the object to stop spinning faster.
  double get angularDrag => _angularDrag;

  /// Sets the rotational drag coefficient.
  /// 
  /// Affects how quickly rotational energy is dissipated over time.
  /// 
  /// * [value]: The angular resistance value.
  set angularDrag(double value) {
    if (_angularDrag == value) return;
    _angularDrag = value;
    if (isAttached) game.physics.updateRigidbody(this);
  }

  /// Multiplier for the global gravity vector.
  /// 
  /// Use 0.0 for weightless objects or higher values for heavy objects.
  double get gravityScale => _gravityScale;

  /// Sets the gravity multiplier for this body.
  /// 
  /// Allows for individual objects to behave differently under global gravity.
  /// 
  /// * [value]: The scale factor.
  set gravityScale(double value) {
    if (_gravityScale == value) return;
    _gravityScale = value;
    if (isAttached) game.physics.updateRigidbody(this);
  }

  /// Whether the body's rotation is locked.
  /// 
  /// If true, the object will not rotate regardless of forces or collisions.
  bool get freezeRotation => _freezeRotation;

  /// Sets whether the rotation should be frozen.
  /// 
  /// When frozen, the moment of inertia is effectively set to infinity 
  /// in the physics engine.
  /// 
  /// * [value]: True to lock rotation.
  set freezeRotation(bool value) {
    if (_freezeRotation == value) return;
    _freezeRotation = value;
    if (isAttached) game.physics.updateRigidbody(this);
  }

  Offset _velocity = Offset.zero;
  double _angularVelocity = 0.0;

  /// The current world-space linear velocity.
  /// 
  /// Directly setting this value will synchronize with the physics worker.
  Offset get velocity => _velocity;

  /// Sets the current linear velocity.
  /// 
  /// This will overwrite any velocity calculated by the physics simulation 
  /// in the next step.
  /// 
  /// * [value]: The velocity vector.
  set velocity(Offset value) {
    if (_velocity == value) return;
    _velocity = value;
    if (isAttached) game.physics.internalSyncVelocity(this, value);
  }

  /// The current rotational velocity in radians per second.
  /// 
  /// Positive values indicate clockwise rotation in Goo2D's coordinate system.
  double get angularVelocity => _angularVelocity;

  /// Sets the current rotational velocity.
  /// 
  /// Synchronizes the new angular velocity with the background simulation.
  /// 
  /// * [value]: The radians per second value.
  set angularVelocity(double value) {
    if (_angularVelocity == value) return;
    _angularVelocity = value;
    if (isAttached) game.physics.internalSyncAngularVelocity(this, value);
  }

  /// Internal method used by PhysicsSystem to update velocity without triggering a sync.
  /// 
  /// This is called during the physics step result processing to update 
  /// local state from the worker simulation.
  /// 
  /// * [vel]: The new linear velocity.
  /// * [angVel]: The new angular velocity.
  void internalSetVelocity(Offset vel, double angVel) {
    _velocity = vel;
    _angularVelocity = angVel;
  }

  /// Whether the body is kinematic.
  /// 
  /// Kinematic bodies move via script but still interact as solid 
  /// objects with dynamic bodies.
  bool get isKinematic => type == RigidbodyType.kinematic;
  
  /// Whether the body is dynamic.
  /// 
  /// Dynamic bodies are fully simulated with forces and gravity.
  bool get isDynamic => type == RigidbodyType.dynamic;
  
  /// Whether the body is static.
  /// 
  /// Static bodies do not move and are optimized for background scenery.
  bool get isStatic => type == RigidbodyType.static;

  /// The transform component of the parent object.
  /// 
  /// Used to synchronize physics state with the world-space position 
  /// and rotation of the [GameObject].
  ObjectTransform get transform => gameObject.getComponent<ObjectTransform>();
  
  /// Safely attempts to retrieve the transform component.
  /// 
  /// Returns null if the parent [GameObject] has been destroyed or 
  /// detached during the physics step.
  ObjectTransform? get tryTransform =>
      gameObject.tryGetComponent<ObjectTransform>();

  @override
  void onMounted() {
    game.physics.registerRigidbody(this);
  }

  @override
  void onUnmounted() {
    game.physics.unregisterRigidbody(this);
  }

  /// Applies a continuous [force] to the body.
  /// 
  /// Force is applied over time (Newtons). Use this for constant 
  /// propulsion like wind or rocket engines.
  /// 
  /// * [force]: The force vector in world units/sec^2.
  void addForce(Offset force) {
    game.physics.internalQueueForce(this, force);
  }

  /// Applies an instantaneous [impulse] to the body.
  /// 
  /// Impulse changes velocity immediately. Use this for events like 
  /// jumping, explosions, or being hit by a projectile.
  /// 
  /// * [impulse]: The impulse vector in world units/sec.
  void addImpulse(Offset impulse) {
    game.physics.internalQueueImpulse(this, impulse);
  }

  /// Applies an instantaneous rotational [impulse].
  /// 
  /// This causes the body to start spinning immediately. The effect 
  /// is proportional to the object's moment of inertia.
  /// 
  /// * [impulse]: The angular impulse in radians/sec.
  void addAngularImpulse(double impulse) {
    game.physics.internalQueueAngularImpulse(this, impulse);
  }
}
