import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/goo2d.dart';
import 'package:goo2d/src/physics/worker/data/raycast_hit_data.dart';

/// Returns information about 2D Colliders detected by a 2D physics query in the scene.
/// 
/// Equivalent to Unity's `RaycastHit2D`.
class RaycastHit {
  final Vector2 _point;
  final Vector2 _normal;
  final Vector2 _centroid;
  final double _distance;
  final double _fraction;
  final Collider _collider;

  RaycastHit._({
    required Vector2 point,
    required Vector2 normal,
    required Vector2 centroid,
    required double distance,
    required double fraction,
    required Collider collider,
  })  : _point = point,
        _normal = normal,
        _centroid = centroid,
        _distance = distance,
        _fraction = fraction,
        _collider = collider;

  /// Internal factory to create a [RaycastHit] from [RaycastHitData].
  static RaycastHit? fromData(RaycastHitData data) {
    final collider = PhysicsSystem.getCollider(data.colliderHandle);
    if (collider == null) return null;
    
    return RaycastHit._(
      point: data.point,
      normal: data.normal,
      centroid: data.centroid,
      distance: data.distance,
      fraction: data.fraction,
      collider: collider,
    );
  }

  /// The Transform on the GameObject that the Collider2D is attached to.
  ObjectTransform get transform => _collider.gameObject.getComponent<ObjectTransform>();

  /// The Rigidbody2D that the Collider2D detected by the physics query is attached to.
  Rigidbody get rigidbody => _collider.attachedRigidbody;

  /// The distance the physics query traversed before it detected a Collider2D.
  double get distance => _distance;

  /// The fraction of the distance specified to the physics query before it detected a Collider2D.
  double get fraction => _fraction;

  /// The surface normal of the detected Collider2D.
  Vector2 get normal => _normal;

  /// The world space centroid (center) of the physics query shape when it intersects.
  Vector2 get centroid => _centroid;

  /// The Collider2D detected by the physics query.
  Collider get collider => _collider;

  /// The world space position where the physics query shape intersected with the detected Collider2D surface.
  Vector2 get point => _point;
}