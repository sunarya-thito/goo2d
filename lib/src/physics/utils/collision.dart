import 'package:flutter/painting.dart';
import 'package:goo2d/goo2d.dart';

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
