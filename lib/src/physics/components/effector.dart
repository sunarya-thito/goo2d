import 'dart:math' as math;
import 'package:flutter/painting.dart';
import 'package:goo2d/goo2d.dart';

/// Base class for components that apply physical forces to objects in a zone.
/// 
/// [Effector] components provide a standard way to influence the movement 
/// of [Rigidbody] objects within a specific area defined by a [Collider]. 
/// They use [TriggerListener] to detect when objects enter their zone 
/// and automatically apply forces according to the effector's specific logic.
/// 
/// Subclasses must implement [applyEffectorForce] to define how forces are 
/// calculated and applied to target bodies.
/// 
/// ```dart
/// class MyWindEffector extends Effector {
///   @override
///   void applyEffectorForce(Rigidbody rb, Collider other) {
///     rb.addForce(const Offset(100, 0));
///   }
/// }
/// ```
/// 
/// See also:
/// * [AreaEffector] for constant directional forces.
/// * [PointEffector] for radial attraction/repulsion.
abstract class Effector extends Component with TriggerListener {
  /// Whether the effector is currently applying forces.
  /// 
  /// When disabled, the effector will still receive trigger events but 
  /// will skip the force application step. This is useful for toggling 
  /// environmental effects like fans or magnets at runtime.
  bool enabled = true;

  /// The base magnitude of the force applied by this effector.
  /// 
  /// This value is typically used as a multiplier for the calculated force 
  /// direction. For [PointEffector], positive values attract while negative 
  /// values repel.
  double forceMagnitude = 1000.0;

  /// Retrieves the transform component of the parent object.
  /// 
  /// Provides access to the effector's world-space position and rotation, 
  /// which is essential for calculating relative force directions in 
  /// subclasses like [AreaEffector] and [PointEffector].
  ObjectTransform get transform => gameObject.getComponent<ObjectTransform>();

  @override
  void onTriggerStay(Collider other) {
    if (!enabled) return;
    
    final rb = other.gameObject.tryGetComponent<Rigidbody>();
    if (rb != null && rb.type == RigidbodyType.dynamic) {
      applyEffectorForce(rb, other);
    }
  }

  /// Internal method implemented by subclasses to apply specific force logic.
  /// 
  /// This method is called every frame for every [Rigidbody] that remains 
  /// inside the effector's trigger zone.
  /// 
  /// * [rb]: The target dynamic body.
  /// * [other]: The collider belonging to the target body.
  void applyEffectorForce(Rigidbody rb, Collider other);
}

/// Applies a constant force in a world or local direction.
/// 
/// [AreaEffector] is designed for large-scale environmental forces like 
/// wind zones, localized gravity, or conveyor areas. It applies a uniform 
/// force vector to all dynamic [Rigidbody]s within its volume.
/// 
/// The force direction can be fixed in world space or tied to the effector's 
/// own rotation, allowing for rotating fans or directional boosters.
/// 
/// ```dart
/// // Create a wind zone blowing Right
/// final wind = GameObject()
///   ..addComponent(BoxCollider()..isTrigger = true)
///   ..addComponent(AreaEffector()..forceAngle = 0..forceMagnitude = 500);
/// ```
/// 
/// See also:
/// * [PointEffector] for radial forces.
/// * [SurfaceEffector] for contact-based forces.
class AreaEffector extends Effector {
  /// The direction of the force in radians.
  /// 
  /// If [useGlobalAngle] is false, this angle is added to the effector's 
  /// transform rotation. 0 radians points towards the positive X-axis.
  double forceAngle = 0.0;

  /// Whether the [forceAngle] is relative to the world or the local transform.
  /// 
  /// When true, the force direction remains constant regardless of how 
  /// the effector's [GameObject] is rotated. When false, rotating the 
  /// object will rotate the force direction accordingly.
  bool useGlobalAngle = false;

  @override
  void applyEffectorForce(Rigidbody rb, Collider other) {
    double angle = forceAngle;
    if (!useGlobalAngle) {
      angle += transform.angle;
    }
    
    final force = Offset(math.cos(angle), math.sin(angle)) * forceMagnitude;
    rb.addForce(force);
  }
}

/// Applies force towards or away from the effector's center.
/// 
/// [PointEffector] simulates radial forces such as magnetism, gravity 
/// wells, or explosions. It calculates a vector between its own position 
/// and the target [Rigidbody]'s position to determine the force direction.
/// 
/// Unlike [AreaEffector], the direction varies for every object depending 
/// on where they are relative to the center of the effector.
/// 
/// ```dart
/// // Create a magnet that attracts objects
/// final magnet = GameObject()
///   ..addComponent(CircleCollider()..radius = 200..isTrigger = true)
///   ..addComponent(PointEffector()..forceMagnitude = 2000);
/// ```
/// 
/// See also:
/// * [AreaEffector] for directional forces.
/// * [Rigidbody] for the target physical body.
class PointEffector extends Effector {
  @override
  void applyEffectorForce(Rigidbody rb, Collider other) {
    final diff = transform.position - rb.gameObject.getComponent<ObjectTransform>().position;
    if (diff.distanceSquared > 0) {
      final direction = diff / diff.distance;
      rb.addForce(direction * forceMagnitude);
    }
  }
}

/// Applies tangential force to objects touching a surface.
/// 
/// [SurfaceEffector] differs from other effectors as it requires solid 
/// contact to function. It uses [CollisionListener] instead of triggers 
/// to detect surfaces and applies forces along the tangent of the collision 
/// normal.
/// 
/// This is the primary component for implementing conveyor belts, speed 
/// pads, or slippery ice surfaces.
/// 
/// ```dart
/// // Create a conveyor belt
/// final belt = GameObject()
///   ..addComponent(BoxCollider())
///   ..addComponent(SurfaceEffector()..speed = 300);
/// ```
/// 
/// See also:
/// * [PlatformEffector] for one-way collision logic.
/// * [Collision] for the contact data used by this effector.
class SurfaceEffector extends Component with CollisionListener {
  /// Whether the effector is currently active.
  /// 
  /// When disabled, collisions are still resolved normally by the physics 
  /// engine, but no additional surface force is applied to the objects.
  bool enabled = true;

  /// The target speed the surface attempts to impart to objects.
  /// 
  /// The effector calculates the difference between the object's current 
  /// velocity and this target speed along the surface tangent.
  double speed = 200.0;

  /// The strength of the force applied to maintain the surface speed.
  /// 
  /// Higher values make the surface feel more "grippy" and cause objects 
  /// to reach the target [speed] faster.
  double forceMagnitude = 5000.0;

  /// Retrieves the transform component of the parent object.
  /// 
  /// Used to identify the spatial context of the surface during collision.
  ObjectTransform get transform => gameObject.getComponent<ObjectTransform>();

  @override
  void onCollisionStay(Collision collision) {
    if (!enabled) return;
    
    final rb = collision.rigidbody;
    if (rb != null && rb.type == RigidbodyType.dynamic) {
      // Calculate tangent (perpendicular to contact normal)
      final normal = collision.normal;
      final tangent = Offset(-normal.dy, normal.dx);
      
      // Apply directional force along the surface
      rb.addForce(tangent * speed * forceMagnitude * 0.01); 
    }
  }
}

/// Simulates buoyancy and drag within a fluid volume.
/// 
/// [BuoyancyEffector] provides fluid physics simulation, applying upward 
/// force to submerged objects and increasing movement resistance. It is 
/// ideal for water, lava, or thick gas clouds.
/// 
/// The component uses the target object's position relative to a [surfaceLevel] 
/// to calculate how much buoyancy to apply, simulating Archimedes' principle.
/// 
/// ```dart
/// // Create a pool of water
/// final water = GameObject()
///   ..addComponent(BoxCollider()..isTrigger = true)
///   ..addComponent(BuoyancyEffector()
///     ..surfaceLevel = 100
///     ..density = 1.2
///     ..linearDrag = 5.0);
/// ```
/// 
/// See also:
/// * [AreaEffector] for flowing water (currents).
/// * [Rigidbody.drag] for the default air resistance.
class BuoyancyEffector extends Effector {
  /// The density of the fluid. Higher values increase upward force.
  /// 
  /// A density of 1.0 typically balances an object of equal mass and volume. 
  /// Increase this for "heavy" fluids like mercury or salt water.
  double density = 1.0;

  /// The Y-coordinate in world space representing the fluid surface.
  /// 
  /// Buoyancy is only applied when the target object's center is below 
  /// this line. The force increases linearly with depth.
  double surfaceLevel = 0.0;

  /// Linear drag multiplier applied to objects inside the fluid.
  /// 
  /// Simulates viscosity by reducing the linear velocity of objects over 
  /// time. Higher values make the fluid feel "thicker".
  double linearDrag = 2.0;

  /// Rotational drag multiplier applied to objects inside the fluid.
  /// 
  /// Simulates fluid resistance against rotation. High values prevent 
  /// objects from spinning rapidly underwater.
  double angularDrag = 1.0;

  @override
  void applyEffectorForce(Rigidbody rb, Collider other) {
    final pos = rb.gameObject.getComponent<ObjectTransform>().position;
    if (pos.dy > surfaceLevel) {
       final depth = pos.dy - surfaceLevel;
       final buoyancy = Offset(0, -depth * density * 1000);
       rb.addForce(buoyancy);
       
       // Apply damping to simulate fluid resistance
       rb.velocity *= (1.0 - linearDrag * 0.01);
       rb.angularVelocity *= (1.0 - angularDrag * 0.01);
    }
  }
}

/// Configures one-way collision logic on the attached collider.
/// 
/// [PlatformEffector] allows for the creation of "cloud platforms" common 
/// in platformer games. Objects can jump through the platform from the 
/// bottom (pass-through) but land solidly on the top.
/// 
/// It works by dynamically updating the [Collider.isOneWay] properties 
/// of its parent [GameObject] every frame based on the current transform.
/// 
/// ```dart
/// // Create a one-way platform
/// final platform = GameObject()
///   ..addComponent(BoxCollider())
///   ..addComponent(PlatformEffector());
/// ```
/// 
/// See also:
/// * [Collider.isOneWay] for the underlying physics property.
/// * [SurfaceEffector] for moving platforms.
class PlatformEffector extends Component with LifecycleListener, Tickable {
  /// Whether one-way collision logic is currently active.
  /// 
  /// If false, the platform behaves like a regular solid wall.
  bool useOneWay = true;

  /// The width of the arc (in radians) that constitutes the "solid" side.
  /// 
  /// A value of PI (180 degrees) means any collision coming from above 
  /// the platform is solid.
  double oneWayArc = math.pi;

  /// Rotational offset for the one-way direction relative to the transform.
  /// 
  /// By default, 0 means the solid side is aligned with the object's 
  /// Up direction.
  double rotationalOffset = 0.0;

  /// Retrieves the transform component of the parent object.
  /// 
  /// Used to synchronize the one-way direction with the platform's rotation.
  ObjectTransform get transform => gameObject.getComponent<ObjectTransform>();

  @override
  void onMounted() {
    _updateCollider();
  }

  /// Internal method to synchronize platform settings with the collider.
  void _updateCollider() {
    final collider = gameObject.tryGetComponent<Collider>();
    if (collider != null) {
      collider.isOneWay = useOneWay;
      collider.oneWayArc = oneWayArc;
      // Pass-through direction is opposite to the solid surface normal
      final angle = transform.angle + rotationalOffset;
      collider.oneWayAngle = angle;

      if (collider is CompositeCollider) {
        for (final shape in collider.shapes) {
          shape.isOneWay = useOneWay;
          shape.oneWayArc = oneWayArc;
          shape.oneWayAngle = angle;
        }
      }
    }
  }
  
  @override
  void onUpdate(double dt) {
     _updateCollider();
  }
}
