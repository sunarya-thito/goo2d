import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/goo2d.dart';

/// Collision details returned by 2D physics callback functions.
/// 
/// Equivalent to Unity's `Collision2D`.
class Collision {
  /// Gets the number of contacts for this collision.
  int get contactCount => throw UnimplementedError('Implemented via Physics Worker');
  set contactCount(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The incoming GameObject involved in the collision.
  GameObject get gameObject => throw UnimplementedError('Implemented via Physics Worker');
  set gameObject(GameObject value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The incoming Collider2D involved in the collision with the otherCollider.
  Collider get collider => throw UnimplementedError('Implemented via Physics Worker');
  set collider(Collider value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Indicates whether the collision response or reaction is enabled or disabled.
  bool get enabled => throw UnimplementedError('Implemented via Physics Worker');
  set enabled(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The incoming Rigidbody2D involved in the collision with the otherRigidbody.
  Rigidbody get rigidbody => throw UnimplementedError('Implemented via Physics Worker');
  set rigidbody(Rigidbody value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The other Collider2D involved in the collision with the collider.
  Collider get otherCollider => throw UnimplementedError('Implemented via Physics Worker');
  set otherCollider(Collider value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The other Rigidbody2D involved in the collision with the rigidbody.
  Rigidbody get otherRigidbody => throw UnimplementedError('Implemented via Physics Worker');
  set otherRigidbody(Rigidbody value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The Transform of the incoming object involved in the collision.
  ObjectTransform get transform => throw UnimplementedError('Implemented via Physics Worker');
  set transform(ObjectTransform value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The specific points of contact with the incoming Collider2D. You should avoid using this as it produces memory garbage. Use GetContact or GetContacts instead.
  List<ContactPoint> get contacts => throw UnimplementedError('Implemented via Physics Worker');
  set contacts(List<ContactPoint> value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The relative linear velocity of the two colliding objects (Read Only).
  Vector2 get relativeVelocity => throw UnimplementedError('Implemented via Physics Worker');
  set relativeVelocity(Vector2 value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Gets the contact point at the specified index.
  /// - [index]: The index of the contact to retrieve.
  ContactPoint getContact(int index) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Retrieves all contact points for contacts between collider and otherCollider.
  /// - [contacts]: An array of ContactPoint2D used to receive the results.
  int getContacts(List<ContactPoint> contacts) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

}