import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/goo2d.dart';
import 'package:goo2d/src/physics/worker/data/contact_point_data.dart';

/// Details about a specific point of contact involved in a 2D physics collision.
/// 
/// Equivalent to Unity's `ContactPoint2D`.
class ContactPoint {
  final double _separation;
  final double _normalImpulse;
  final double _tangentImpulse;
  final Vector2 _point;
  final Vector2 _normal;
  final Vector2 _relativeVelocity;
  final Collider _collider;
  final Collider _otherCollider;

  final bool _enabled;
  final double _friction;
  final double _bounciness;

  ContactPoint._({
    required double separation,
    required double normalImpulse,
    required double tangentImpulse,
    required Vector2 point,
    required Vector2 normal,
    required Vector2 relativeVelocity,
    required Collider collider,
    required Collider otherCollider,
    required bool enabled,
    required double friction,
    required double bounciness,
  })  : _separation = separation,
        _normalImpulse = normalImpulse,
        _tangentImpulse = tangentImpulse,
        _point = point,
        _normal = normal,
        _relativeVelocity = relativeVelocity,
        _collider = collider,
        _otherCollider = otherCollider,
        _enabled = enabled,
        _friction = friction,
        _bounciness = bounciness;

  /// Internal factory to create a [ContactPoint] from [ContactPointData].
  static ContactPoint? fromData(ContactPointData data) {
    final collider = PhysicsSystem.getCollider(data.colliderHandle);
    final otherCollider = PhysicsSystem.getCollider(data.otherColliderHandle);
    if (collider == null || otherCollider == null) return null;

    return ContactPoint._(
      separation: data.separation,
      normalImpulse: data.normalImpulse,
      tangentImpulse: data.tangentImpulse,
      point: data.point,
      normal: data.normal,
      relativeVelocity: data.relativeVelocity,
      collider: collider,
      otherCollider: otherCollider,
      enabled: data.enabled,
      friction: data.friction,
      bounciness: data.bounciness,
    );
  }

  /// Gets the distance between the colliders at the contact point.
  double get separation => _separation;

  /// Gets the impulse applied at the contact point along the ContactPoint2D.normal.
  double get normalImpulse => _normalImpulse;

  /// Gets the impulse applied at the contact point which is perpendicular to the ContactPoint2D.normal.
  double get tangentImpulse => _tangentImpulse;

  /// Whether the contact is enabled or not.
  bool get enabled => _enabled;

  /// The combined friction of the two colliders at the contact point.
  double get friction => _friction;

  /// The combined bounciness of the two colliders at the contact point.
  double get bounciness => _bounciness;

  /// The incoming Rigidbody2D involved in the collision.
  Rigidbody get rigidbody => _collider.attachedRigidbody;

  /// The other Collider2D involved in the collision.
  Collider get otherCollider => _otherCollider;

  /// Surface normal at the contact point.
  Vector2 get normal => _normal;

  /// The other Rigidbody2D involved in the collision.
  Rigidbody get otherRigidbody => _otherCollider.attachedRigidbody;

  /// Gets the relative velocity of the two colliders at the contact point (Read Only).
  Vector2 get relativeVelocity => _relativeVelocity;

  /// The incoming Collider2D involved in the collision.
  Collider get collider => _collider;

  /// The point of contact between the two colliders in world space.
  Vector2 get point => _point;
}