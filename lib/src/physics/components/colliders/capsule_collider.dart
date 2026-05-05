import 'package:vector_math/vector_math_64.dart';
import 'package:meta/meta.dart';
import 'package:goo2d/src/physics/components/collider.dart';
import 'package:goo2d/src/physics/worker/direct/direct_collider_ops.dart';
import 'package:goo2d/src/physics/worker/data/collider_shape_type.dart';
import 'package:goo2d/goo2d.dart';

/// A capsule-shaped primitive collider.
/// 
/// Equivalent to Unity's `CapsuleCollider2D`.
class CapsuleCollider extends Collider {
  @override
  ColliderShapeType get shapeType => ColliderShapeType.capsule;

  @override
  @protected
  void syncProperties() {
    super.syncProperties();
    handle.then((h) {
      worker.setColliderProperty(h, ColliderProp.capsuleSize, _size);
      worker.setColliderProperty(h, ColliderProp.capsuleDirection, _direction.index);
    });
  }

  Vector2 _size = Vector2(1, 2);
  /// The width and height of the capsule area.
  Vector2 get size => _size;
  set size(Vector2 value) {
    _size.setFrom(value);
    handle.then((h) => worker.setColliderProperty(h, ColliderProp.capsuleSize, value));
  }

  CapsuleDirection _direction = CapsuleDirection.vertical;
  /// The direction that the capsule sides can extend.
  CapsuleDirection get direction => _direction;
  set direction(CapsuleDirection value) {
    _direction = value;
    handle.then((h) => worker.setColliderProperty(h, ColliderProp.capsuleDirection, value.index));
  }
}
