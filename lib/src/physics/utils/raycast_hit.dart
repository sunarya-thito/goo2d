import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/goo2d.dart';

/// Returns information about 2D Colliders detected by a 2D physics query in the scene.
/// 
/// Equivalent to Unity's `RaycastHit2D`.
class RaycastHit {
  /// The Transform on the GameObject that the Collider2D is attached to.
  ObjectTransform get transform => throw UnimplementedError('Implemented via Physics Worker');
  set transform(ObjectTransform value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The Rigidbody2D that the Collider2D detected by the physics query is attached to.
  Rigidbody get rigidbody => throw UnimplementedError('Implemented via Physics Worker');
  set rigidbody(Rigidbody value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The distance the physics query traversed before it detected a Collider2D.
  double get distance => throw UnimplementedError('Implemented via Physics Worker');
  set distance(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The fraction of the distance specified to the physics query before it detected a Collider2D.
  double get fraction => throw UnimplementedError('Implemented via Physics Worker');
  set fraction(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The surface normal of the detected Collider2D.
  Vector2 get normal => throw UnimplementedError('Implemented via Physics Worker');
  set normal(Vector2 value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The world space centroid (center) of the physics query shape when it intersects.
  Vector2 get centroid => throw UnimplementedError('Implemented via Physics Worker');
  set centroid(Vector2 value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The Collider2D detected by the physics query.
  Collider get collider => throw UnimplementedError('Implemented via Physics Worker');
  set collider(Collider value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The world space position where the physics query shape intersected with the detected Collider2D surface.
  Vector2 get point => throw UnimplementedError('Implemented via Physics Worker');
  set point(Vector2 value) => throw UnimplementedError('Implemented via Physics Worker');

}