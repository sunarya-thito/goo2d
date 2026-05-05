import 'dart:ui' show Offset;
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

  @override
  bool containsPoint(Offset position) {
    final px = position.dx - offset.x;
    final py = position.dy - offset.y;
    if (_direction == CapsuleDirection.vertical) {
      final radius = _size.x / 2;
      final halfBody = ((_size.y - _size.x) / 2).clamp(0.0, double.infinity);
      final cy = py.clamp(-halfBody, halfBody);
      return px * px + (py - cy) * (py - cy) <= radius * radius;
    } else {
      final radius = _size.y / 2;
      final halfBody = ((_size.x - _size.y) / 2).clamp(0.0, double.infinity);
      final cx = px.clamp(-halfBody, halfBody);
      return (px - cx) * (px - cx) + py * py <= radius * radius;
    }
  }
}
