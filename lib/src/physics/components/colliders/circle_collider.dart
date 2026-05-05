import 'dart:ui' show Offset;
import 'package:meta/meta.dart';
import 'package:goo2d/src/physics/components/collider.dart';
import 'package:goo2d/src/physics/worker/direct/direct_collider_ops.dart';
import 'package:goo2d/src/physics/worker/data/collider_shape_type.dart';
import 'package:goo2d/goo2d.dart';

/// Collider for 2D physics representing an circle.
/// 
/// Equivalent to Unity's `CircleCollider2D`.
class CircleCollider extends Collider {
  @override
  ColliderShapeType get shapeType => ColliderShapeType.circle;

  @override
  @protected
  void syncProperties() {
    super.syncProperties();
    handle.then((h) {
      worker.setColliderProperty(h, ColliderProp.circleRadius, _radius);
    });
  }

  double _radius = 0.5;
  /// Radius of the circle.
  double get radius => _radius;
  set radius(double value) {
    _radius = value;
    handle.then((h) => worker.setColliderProperty(h, ColliderProp.circleRadius, value));
  }

  @override
  bool containsPoint(Offset position) {
    final dx = position.dx - offset.x;
    final dy = position.dy - offset.y;
    return dx * dx + dy * dy <= _radius * _radius;
  }
}
