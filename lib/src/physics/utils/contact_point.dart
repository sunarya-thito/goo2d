import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/goo2d.dart';

/// Details about a specific point of contact involved in a 2D physics collision.
/// 
/// Equivalent to Unity's `ContactPoint2D`.
class ContactPoint {
  /// Gets the distance between the colliders at the contact point.
  double get separation => throw UnimplementedError('Implemented via Physics Worker');
  set separation(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Gets the impulse applied at the contact point along the ContactPoint2D.normal.
  double get normalImpulse => throw UnimplementedError('Implemented via Physics Worker');
  set normalImpulse(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Gets the impulse applied at the contact point which is perpendicular to the ContactPoint2D.normal.
  double get tangentImpulse => throw UnimplementedError('Implemented via Physics Worker');
  set tangentImpulse(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The incoming Rigidbody2D involved in the collision with the otherRigidbody.
  Rigidbody get rigidbody => throw UnimplementedError('Implemented via Physics Worker');
  set rigidbody(Rigidbody value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The other Collider2D involved in the collision with the collider.
  Collider get otherCollider => throw UnimplementedError('Implemented via Physics Worker');
  set otherCollider(Collider value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Surface normal at the contact point.
  Vector2 get normal => throw UnimplementedError('Implemented via Physics Worker');
  set normal(Vector2 value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The other Rigidbody2D involved in the collision with the rigidbody.
  Rigidbody get otherRigidbody => throw UnimplementedError('Implemented via Physics Worker');
  set otherRigidbody(Rigidbody value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Indicates whether the collision response or reaction is enabled or disabled.
  bool get enabled => throw UnimplementedError('Implemented via Physics Worker');
  set enabled(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Gets the relative velocity of the two colliders at the contact point (Read Only).
  Vector2 get relativeVelocity => throw UnimplementedError('Implemented via Physics Worker');
  set relativeVelocity(Vector2 value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The effective friction used for the ContactPoint2D.
  double get friction => throw UnimplementedError('Implemented via Physics Worker');
  set friction(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The incoming Collider2D involved in the collision with the otherCollider.
  Collider get collider => throw UnimplementedError('Implemented via Physics Worker');
  set collider(Collider value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The effective bounciness used for the ContactPoint2D.
  double get bounciness => throw UnimplementedError('Implemented via Physics Worker');
  set bounciness(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The point of contact between the two colliders in world space.
  Vector2 get point => throw UnimplementedError('Implemented via Physics Worker');
  set point(Vector2 value) => throw UnimplementedError('Implemented via Physics Worker');

}