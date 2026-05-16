import 'package:goo2d/goo2d.dart';

/// Collision details returned by 2D physics callback functions.
///
/// Equivalent to Unity's `Collision2D`.
class Collision {
  /// Gets the number of contacts for this collision.
  int contactCount = 0;

  /// The incoming GameObject involved in the collision.
  late GameObject gameObject;

  /// The incoming Collider2D involved in the collision with the otherCollider.
  late Collider collider;

  /// Indicates whether the collision response or reaction is enabled or disabled.
  bool enabled = true;

  /// The incoming Rigidbody2D involved in the collision with the otherRigidbody.
  /// Null when the object has no Rigidbody (e.g. static colliders).
  Rigidbody? rigidbody;

  /// The other Collider2D involved in the collision with the collider.
  late Collider otherCollider;

  /// The other Rigidbody2D involved in the collision with the rigidbody.
  /// Null when the other object has no Rigidbody (e.g. static colliders).
  Rigidbody? otherRigidbody;

  /// The Transform of the incoming object involved in the collision.
  ObjectTransform? transform;

  /// The specific points of contact with the incoming Collider2D.
  List<ContactPoint> contacts = const [];

  /// The relative linear velocity of the two colliding objects (Read Only).
  Vector2 relativeVelocity = Vector2.zero();

  /// Gets the contact point at the specified index.
  ContactPoint getContact(int index) => contacts[index];

  /// Retrieves all contact points for contacts between collider and otherCollider.
  int getContacts(List<ContactPoint> result) {
    result.clear();
    result.addAll(contacts);
    return contacts.length;
  }
}
