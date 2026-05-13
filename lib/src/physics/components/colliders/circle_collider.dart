import 'dart:ui' as ui;
import 'package:meta/meta.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/src/physics/worker/direct/direct_collider_ops.dart';
import 'package:goo2d/src/physics/worker/data/collider_shape_type.dart';
import 'package:goo2d/goo2d.dart';

/// Collider for 2D physics representing a circle.
///
/// Equivalent to Unity's `CircleCollider2D`.
class CircleCollider extends Collider {
  @override
  ColliderShapeType get shapeType => ColliderShapeType.circle;

  @override
  @protected
  void syncAllProperties() {
    super.syncAllProperties();
    worker.setColliderProperty(handle, ColliderProp.circleRadius, _radius);
  }

  double _radius = 0.5;
  double get radius => _radius;
  set radius(double value) {
    _radius = value;
    if (isAttached) worker.setColliderProperty(handle, ColliderProp.circleRadius, value);
  }

  @override
  int getShapes(PhysicsShapeGroup shapeGroup, [int shapeIndex = 0, int shapeCount = 0]) {
    shapeGroup.addCircle(offset, _radius);
    return 1;
  }

  @override
  bool containsPoint(ui.Offset position) {
    final dx = position.dx - offset.x;
    final dy = position.dy - offset.y;
    return dx * dx + dy * dy <= _radius * _radius;
  }

  @override
  @protected
  ui.Rect computeShapeBounds(Vector2 center, double angle) {
    return ui.Rect.fromCircle(center: ui.Offset(center.x, center.y), radius: _radius);
  }
}
