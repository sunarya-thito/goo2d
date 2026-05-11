import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:vector_math/vector_math_64.dart';
import 'package:meta/meta.dart';
import 'package:goo2d/src/physics/components/collider.dart';
import 'package:goo2d/src/physics/worker/direct/direct_collider_ops.dart';
import 'package:goo2d/src/physics/worker/data/collider_shape_type.dart';
import 'package:goo2d/goo2d.dart';

/// Collider for 2D physics representing an axis-aligned rectangle.
///
/// Equivalent to Unity's `BoxCollider2D`.
class BoxCollider extends Collider {
  @override
  ColliderShapeType get shapeType => ColliderShapeType.box;

  @override
  @protected
  void syncProperties() {
    super.syncProperties();
    handleIfAttached?.then((h) {
      worker.setColliderProperty(h, ColliderProp.boxEdgeRadius, _edgeRadius);
      worker.setColliderProperty(h, ColliderProp.boxSize, _size);
      worker.setColliderProperty(h, ColliderProp.boxAutoTiling, _autoTiling);
    });
  }

  double _edgeRadius = 0;
  /// Controls the radius of all edges created by the collider.
  double get edgeRadius => _edgeRadius;
  set edgeRadius(double value) {
    _edgeRadius = value;
    handleIfAttached?.then((h) => worker.setColliderProperty(h, ColliderProp.boxEdgeRadius, value));
  }

  Vector2 _size = Vector2(1, 1);
  /// The width and height of the rectangle.
  Vector2 get size => _size;
  set size(Vector2 value) {
    _size.setFrom(value);
    handleIfAttached?.then((h) => worker.setColliderProperty(h, ColliderProp.boxSize, value));
  }

  bool _autoTiling = false;
  /// Determines whether the BoxCollider2D's shape is automatically updated based on a SpriteRenderer's tiling properties.
  bool get autoTiling => _autoTiling;
  set autoTiling(bool value) {
    _autoTiling = value;
    handleIfAttached?.then((h) => worker.setColliderProperty(h, ColliderProp.boxAutoTiling, value));
  }

  @override
  int getShapes(PhysicsShapeGroup shapeGroup, [int shapeIndex = 0, int shapeCount = 0]) {
    shapeGroup.addBox(offset, _size, 0, _edgeRadius);
    return 1;
  }

  @override
  bool containsPoint(ui.Offset position) {
    final dx = position.dx - offset.x;
    final dy = position.dy - offset.y;
    return dx.abs() <= _size.x / 2 && dy.abs() <= _size.y / 2;
  }

  @override
  @protected
  ui.Rect computeShapeBounds(Vector2 center, double angle) {
    final hx = _size.x / 2;
    final hy = _size.y / 2;
    final c = math.cos(angle).abs();
    final s = math.sin(angle).abs();
    final ex = hx * c + hy * s;
    final ey = hx * s + hy * c;
    return ui.Rect.fromLTRB(center.x - ex, center.y - ey, center.x + ex, center.y + ey);
  }
}
