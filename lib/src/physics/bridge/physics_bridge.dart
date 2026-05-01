import 'package:flutter/painting.dart';
import 'package:goo2d/src/physics/components/rigidbody.dart';
import 'package:goo2d/src/physics/components/collider.dart';
import 'package:goo2d/src/physics/core/physics_joint.dart';
import 'package:goo2d/src/physics/bridge/physics_bridge_data.dart';

/// Abstract bridge between the game engine and the physics simulation.
/// 
/// This interface allows the engine to swap between different simulation 
/// environments. The [DirectPhysicsBridge] is used for synchronous main-thread 
/// execution (required for Web), while [WorkerPhysicsBridge] offloads calculations 
/// to a background Isolate for native platforms.
/// 
/// ```dart
/// final bridge = kIsWeb ? DirectPhysicsBridge() : WorkerPhysicsBridge();
/// await bridge.init(0, (res) => handleResult(res), (id, hit, data) => {});
/// ```
abstract class PhysicsBridge {
  /// Initializes the bridge and sets up result callbacks.
  /// 
  /// The [worldId] must be unique if multiple simulations are running. 
  /// [onStepResult] is called after every simulation step with updated transforms.
  /// [onRaycastResult] is called when a raycast request completes.
  /// 
  /// * [worldId]: Unique identifier for the physics world.
  /// * [onStepResult]: Callback for physics step updates.
  /// * [onRaycastResult]: Callback for raycast completion.
  Future<void> init(int worldId, void Function(PhysicsStepResult) onStepResult,
      void Function(int, bool, PhysicsRaycastHitData?) onRaycastResult);

  /// Creates a new physics world instance in the simulation environment.
  /// 
  /// This should be called once the bridge is initialized but before any 
  /// bodies or shapes are added.
  void createWorld();
  
  /// Destroys the current physics world and releases all resources.
  /// 
  /// This will clear all bodies, shapes, and simulation state from the 
  /// worker or main-thread world instance.
  void destroyWorld();

  /// Adds a new [PhysicsBody] to the simulation.
  /// 
  /// * [id]: Unique ID for the body.
  /// * [type]: Physics behavior (static, kinematic, or dynamic).
  /// * [mass]: Total mass of the body.
  /// * [drag]: Linear friction applied to movement.
  /// * [angularDrag]: Rotational friction.
  /// * [freezeRotation]: If true, prevents rotation via forces.
  /// * [gravityScale]: Multiplier for global gravity.
  /// * [position]: Starting world-space position.
  /// * [rotation]: Starting rotation in radians.
  void addBody(
    int id,
    RigidbodyType type, {
    double mass = 1.0,
    double drag = 0.0,
    double angularDrag = 0.05,
    bool freezeRotation = false,
    double gravityScale = 1.0,
    Offset position = Offset.zero,
    double rotation = 0.0,
  });

  /// Removes a body and all its associated shapes from the simulation.
  /// 
  /// * [id]: The ID of the body to remove.
  void removeBody(int id);

  /// Updates the physical properties of an existing body.
  /// 
  /// * [id]: The body to update.
  /// * [mass]: New mass value.
  /// * [drag]: New linear drag.
  /// * [angularDrag]: New angular drag.
  /// * [freezeRotation]: Updated rotation lock.
  /// * [gravityScale]: Updated gravity multiplier.
  void updateBody(
    int id, {
    double mass = 1.0,
    double drag = 0.0,
    double angularDrag = 0.05,
    bool freezeRotation = false,
    double gravityScale = 1.0,
  });

  /// Adds a [PhysicsShape] to a specific body.
  /// 
  /// Shapes define the volume of the body used for collision detection.
  /// 
  /// * [id]: Unique ID for the shape.
  /// * [bodyId]: The body to attach this shape to.
  /// * [collider]: The configuration for the shape (box, circle, etc).
  void addShape(int id, int bodyId, Collider collider);
  
  /// Removes a shape from its parent body.
  /// 
  /// * [id]: The ID of the shape to remove.
  void removeShape(int id);

  /// Adds a physical joint between two bodies.
  /// 
  /// * [id]: Unique ID for the joint.
  /// * [joint]: The joint configuration.
  void addJoint(int id, Joint joint);

  /// Removes a joint from the simulation.
  /// 
  /// * [id]: The ID of the joint to remove.
  void removeJoint(int id);

  /// Applies a continuous force vector to a body.
  /// 
  /// * [bodyId]: Target body.
  /// * [force]: Force vector in world units/sec^2.
  void applyForce(int bodyId, Offset force);
  
  /// Applies an instantaneous impulse vector to a body.
  /// 
  /// * [bodyId]: Target body.
  /// * [impulse]: Impulse vector in world units/sec.
  void applyImpulse(int bodyId, Offset impulse);
  
  /// Applies a rotational force (torque) to a body.
  /// 
  /// * [bodyId]: Target body.
  /// * [torque]: Rotational force in rad/sec^2.
  void applyTorque(int bodyId, double torque);
  
  /// Applies an instantaneous rotational impulse to a body.
  /// 
  /// * [bodyId]: Target body.
  /// * [impulse]: Rotational impulse in rad/sec.
  void applyAngularImpulse(int bodyId, double impulse);

  /// Sets the global gravity vector for the world.
  /// 
  /// * [gravity]: Gravity vector (default is [0, 9.8]).
  void setGravity(Offset gravity);
  
  /// Manually sets the linear velocity of a body.
  /// 
  /// * [bodyId]: Target body.
  /// * [velocity]: New velocity vector.
  void syncVelocity(int bodyId, Offset velocity);
  
  /// Manually sets the angular velocity of a body.
  /// 
  /// * [bodyId]: Target body.
  /// * [velocity]: New angular velocity.
  void syncAngularVelocity(int bodyId, double velocity);

  /// Commands the simulation to advance by [dt].
  /// 
  /// This is the primary simulation loop entry point. The [sync] map is used 
  /// to update the positions of non-dynamic bodies that were moved by 
  /// the engine since the last step.
  /// 
  /// * [dt]: Time delta since last step.
  /// * [sync]: Map of bodies requiring transform synchronization.
  void step(double dt, Map<int, PhysicsTransformSync> sync);
  
  /// Commands the simulation to perform a raycast.
  /// 
  /// Results will be returned asynchronously via the [onRaycastResult] 
  /// callback provided in [init].
  /// 
  /// * [requestId]: Unique ID for this request to track results.
  /// * [origin]: Ray start point.
  /// * [direction]: Normalized ray direction.
  /// * [maxDistance]: Maximum ray length.
  void raycast(
      int requestId, Offset origin, Offset direction, double maxDistance);
}
