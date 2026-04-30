import 'package:flutter/painting.dart';
import 'package:goo2d/goo2d.dart';

/// Defines the physical properties of a collider's surface.
/// 
/// Materials control how objects slide and bounce during physical resolution. 
/// Every [Collider] has an associated [PhysicsMaterial].
/// 
/// ```dart
/// const bouncyMetal = PhysicsMaterial(
///   bounciness: 0.8,
///   friction: 0.1,
/// );
/// ```
class PhysicsMaterial {
  /// The restitution coefficient (0.0 to 1.0+). 
  /// 
  /// A value of 0.0 means no bounce, while 1.0 means a perfect 
  /// elastic collision where no energy is lost.
  final double bounciness;
  
  /// The friction coefficient (0.0 to 1.0+).
  /// 
  /// Higher values cause more resistance when sliding against other surfaces, 
  /// simulating rough materials like sandpaper or rubber.
  final double friction;

  /// Creates a [PhysicsMaterial] with the given properties.
  /// 
  /// * [bounciness]: Energy retention multiplier.
  /// * [friction]: Sliding resistance multiplier.
  const PhysicsMaterial({
    this.bounciness = 0.0,
    this.friction = 0.4,
  });

  /// The default material used when none is specified.
  /// 
  /// This material has medium friction and zero bounciness.
  static const defaultMaterial = PhysicsMaterial();
}

/// Information about a raycast intersection.
/// 
/// [RaycastHit] contains the point of contact, the surface normal, and the 
/// distance from the origin. It is returned by [PhysicsWorld.raycast].
/// 
/// ```dart
/// final hit = world.raycast(origin, direction);
/// if (hit != null) {
///   print('Hit ${hit.collider.gameObject.name} at ${hit.point}');
/// }
/// ```
class RaycastHit {
  /// The collider that was hit.
  /// 
  /// Use this to access the [GameObject] or other components of the target.
  final Collider collider;
  
  /// The world-space position of the intersection.
  /// 
  /// This is the exact coordinate where the ray intersected the collider surface.
  final Offset point;
  
  /// The surface normal at the hit point.
  /// 
  /// The normal vector points away from the surface and can be used for 
  /// calculating bounce directions or placing decals.
  final Offset normal;
  
  /// The absolute distance from the ray origin to the hit point.
  /// 
  /// This value is measured in world units along the ray's path.
  final double distance;
  
  /// The relative fraction (0.0 to 1.0) along the ray's maximum distance.
  /// 
  /// Useful for determining which of multiple hits is closer without 
  /// comparing absolute distances.
  final double fraction;

  /// Creates a [RaycastHit] data container.
  /// 
  /// * [collider]: The shape that was hit.
  /// * [point]: World-space hit position.
  /// * [normal]: Surface normal vector.
  /// * [distance]: Distance from origin.
  /// * [fraction]: Normalized distance (0-1).
  RaycastHit({
    required this.collider,
    required this.point,
    required this.normal,
    required this.distance,
    required this.fraction,
  });
}

/// Information about a collision between two colliders.
/// 
/// This data is passed to [CollisionListener] methods during physical 
/// contact resolution. It provides details about the impact point and impulse.
/// 
/// ```dart
/// @override
/// void onCollisionEnter(Collision collision) {
///   if (collision.impulse > 10.0) playThudSound();
/// }
/// ```
class Collision {
  /// The collider on the receiving [GameObject].
  /// 
  /// This is the collider that "owns" the listener receiving this event.
  final Collider collider;
  
  /// The other collider involved in the collision.
  /// 
  /// Use this to identify what was hit (e.g. checking tags or layers).
  final Collider otherCollider;
  
  /// The [GameObject] that was hit.
  /// 
  /// Shortcut for [otherCollider.gameObject].
  final GameObject gameObject;
  
  /// The [Rigidbody] of the other object, if it has one.
  /// 
  /// Allows you to apply forces or impulses back to the attacker.
  final Rigidbody? rigidbody;
  
  /// The point of contact in world space.
  /// 
  /// The location where the two shapes are touching or overlapping.
  final Offset contactPoint;
  
  /// The contact normal pointing towards the receiving collider.
  /// 
  /// This vector represents the direction of the impact force.
  final Offset normal;
  
  /// The magnitude of the impulse applied during resolution.
  /// 
  /// Represents the "forcefulness" of the impact. Higher values indicate 
  /// higher velocity changes during the collision.
  final double impulse;

  /// Creates a [Collision] data object.
  /// 
  /// * [collider]: Local collider.
  /// * [otherCollider]: Distant collider.
  /// * [gameObject]: Distant object.
  /// * [rigidbody]: Distant body (optional).
  /// * [contactPoint]: World-space contact location.
  /// * [normal]: Contact normal vector.
  /// * [impulse]: Impact magnitude.
  const Collision({
    required this.collider,
    required this.otherCollider,
    required this.gameObject,
    this.rigidbody,
    required this.contactPoint,
    required this.normal,
    required this.impulse,
  });
}

/// Event dispatched when a collision occurs between two solid colliders.
/// 
/// This is an internal event used by the [PhysicsSystem] to notify 
/// [GameObject] components about physical interactions. It encapsulates 
/// the [Collision] data and the lifecycle [CollisionState].
/// 
/// ```dart
/// // Internal usage by PhysicsSystem
/// game.events.dispatch(CollisionEvent(data, CollisionState.enter));
/// ```
class CollisionEvent extends Event<CollisionListener> {
  /// The detailed collision data.
  /// 
  /// Includes point of contact, normal, and impulse.
  final Collision collision;
  
  /// The current state of the collision (enter, stay, or exit).
  /// 
  /// Determines which method of the [CollisionListener] will be called.
  final CollisionState state;

  /// Creates a [CollisionEvent].
  /// 
  /// * [collision]: Detailed impact data.
  /// * [state]: Lifecycle phase of the contact.
  const CollisionEvent(this.collision, this.state);

  @override
  void dispatch(CollisionListener listener) {
    switch (state) {
      case CollisionState.enter:
        listener.onCollisionEnter(collision);
      case CollisionState.stay:
        listener.onCollisionStay(collision);
      case CollisionState.exit:
        listener.onCollisionExit(collision);
    }
  }
}

/// The lifecycle state of a collision or trigger overlap.
/// 
/// Used to distinguish between the initial impact, sustained contact, 
/// and the final separation of two colliders.
enum CollisionState { 
  /// The first frame where overlap is detected.
  enter, 
  
  /// Subsequent frames where overlap continues.
  stay, 
  
  /// The frame where objects stop overlapping.
  exit 
}

/// Interface for components that want to listen for physical collisions.
/// 
/// To receive these events, the [GameObject] must have at least one [Collider] 
/// and be registered with the [PhysicsSystem].
mixin CollisionListener implements EventListener {
  /// Called when a collision begins.
  /// 
  /// * [collision]: Impact details and contact point.
  void onCollisionEnter(Collision collision) {}
  
  /// Called every frame while the collision continues.
  /// 
  /// * [collision]: Sustained contact details.
  void onCollisionStay(Collision collision) {}
  
  /// Called when the collision ends.
  /// 
  /// * [collision]: Final contact state before separation.
  void onCollisionExit(Collision collision) {}
}

/// Event dispatched when a collider enters or exits a trigger volume.
/// 
/// Triggers do not resolve physically but generate these events to 
/// detect region occupancy. This is primarily used by the [PhysicsSystem] 
/// to notify [TriggerListener]s.
/// 
/// ```dart
/// // Internal usage by PhysicsSystem
/// game.events.dispatch(TriggerEvent(trigger, other, CollisionState.enter));
/// ```
class TriggerEvent extends Event<TriggerListener> {
  /// The trigger collider that detected the overlap.
  /// 
  /// This is the collider with [Collider.isTrigger] set to true.
  final Collider trigger;
  
  /// The other collider that entered the trigger.
  /// 
  /// This can be either a solid or another trigger collider.
  final Collider other;
  
  /// The current state of the overlap.
  /// 
  /// Determines whether the enter, stay, or exit callback is triggered.
  final CollisionState state;

  /// Creates a [TriggerEvent].
  /// 
  /// * [trigger]: The detecting volume.
  /// * [other]: The overlapping object.
  /// * [state]: Lifecycle phase of the overlap.
  const TriggerEvent(this.trigger, this.other, this.state);

  @override
  void dispatch(TriggerListener listener) {
    switch (state) {
      case CollisionState.enter:
        listener.onTriggerEnter(other);
      case CollisionState.stay:
        listener.onTriggerStay(other);
      case CollisionState.exit:
        listener.onTriggerExit(other);
    }
  }
}

/// Interface for components that want to listen for trigger volume overlaps.
/// 
/// Triggers are ideal for zone detection, power-ups, or area-of-effect logic.
mixin TriggerListener implements EventListener {
  /// Called when another collider enters the trigger.
  /// 
  /// * [other]: The collider that entered the zone.
  void onTriggerEnter(Collider other) {}
  
  /// Called every frame while the other collider remains inside.
  /// 
  /// * [other]: The collider currently inside the zone.
  void onTriggerStay(Collider other) {}
  
  /// Called when the other collider exits the trigger.
  /// 
  /// * [other]: The collider that just left the zone.
  void onTriggerExit(Collider other) {}
}
