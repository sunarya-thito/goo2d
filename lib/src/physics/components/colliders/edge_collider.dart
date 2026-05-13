import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:meta/meta.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/src/physics/worker/direct/direct_collider_ops.dart';
import 'package:goo2d/src/physics/worker/data/collider_shape_type.dart';
import 'package:goo2d/goo2d.dart';

/// Collider for 2D physics representing an arbitrary set of connected edges (lines) defined by its vertices.
///
/// Equivalent to Unity's `EdgeCollider2D`.
class EdgeCollider extends Collider {
  @override
  ColliderShapeType get shapeType => ColliderShapeType.edge;

  @override
  @protected
  void syncAllProperties() {
    super.syncAllProperties();
    worker.setColliderProperty(handle, ColliderProp.edgePoints, List.from(_points));
    worker.setColliderProperty(handle, ColliderProp.edgeUseAdjacentStartPoint, _useAdjacentStartPoint);
    worker.setColliderProperty(handle, ColliderProp.edgeUseAdjacentEndPoint, _useAdjacentEndPoint);
    worker.setColliderProperty(handle, ColliderProp.edgeAdjacentStartPoint, _adjacentStartPoint.clone());
    worker.setColliderProperty(handle, ColliderProp.edgeAdjacentEndPoint, _adjacentEndPoint.clone());
    worker.setColliderProperty(handle, ColliderProp.edgeRadius, _edgeRadius);
  }

  List<Vector2> _points = [];
  List<Vector2> get points => _points;
  set points(List<Vector2> value) {
    _points = List.from(value);
    if (isAttached) worker.setColliderProperty(handle, ColliderProp.edgePoints, List.from(_points));
  }

  bool _useAdjacentStartPoint = false;
  bool get useAdjacentStartPoint => _useAdjacentStartPoint;
  set useAdjacentStartPoint(bool value) {
    _useAdjacentStartPoint = value;
    if (isAttached) worker.setColliderProperty(handle, ColliderProp.edgeUseAdjacentStartPoint, value);
  }

  bool _useAdjacentEndPoint = false;
  bool get useAdjacentEndPoint => _useAdjacentEndPoint;
  set useAdjacentEndPoint(bool value) {
    _useAdjacentEndPoint = value;
    if (isAttached) worker.setColliderProperty(handle, ColliderProp.edgeUseAdjacentEndPoint, value);
  }

  Vector2 _adjacentStartPoint = Vector2.zero();
  Vector2 get adjacentStartPoint => _adjacentStartPoint;
  set adjacentStartPoint(Vector2 value) {
    _adjacentStartPoint.setFrom(value);
    if (isAttached) worker.setColliderProperty(handle, ColliderProp.edgeAdjacentStartPoint, value.clone());
  }

  Vector2 _adjacentEndPoint = Vector2.zero();
  Vector2 get adjacentEndPoint => _adjacentEndPoint;
  set adjacentEndPoint(Vector2 value) {
    _adjacentEndPoint.setFrom(value);
    if (isAttached) worker.setColliderProperty(handle, ColliderProp.edgeAdjacentEndPoint, value.clone());
  }

  double _edgeRadius = 0;
  double get edgeRadius => _edgeRadius;
  set edgeRadius(double value) {
    _edgeRadius = value;
    if (isAttached) worker.setColliderProperty(handle, ColliderProp.edgeRadius, value);
  }

  int get edgeCount => _points.length > 1 ? _points.length - 1 : 0;
  int get pointCount => _points.length;

  void reset() {
    points = [Vector2(-1, 0), Vector2(1, 0)];
  }

  List<Vector2> getPoints() => points;

  bool setPoints(List<Vector2> points) {
    if (points.length < 2) return false;
    this.points = points;
    return true;
  }

  @override
  int getShapes(PhysicsShapeGroup shapeGroup, [int shapeIndex = 0, int shapeCount = 0]) {
    if (_points.length < 2) return 0;
    final worldPoints = _points.map((p) => p + offset).toList();
    final idx = shapeGroup.addEdges(worldPoints, _edgeRadius);
    if (_useAdjacentStartPoint || _useAdjacentEndPoint) {
      shapeGroup.setShapeAdjacentVertices(idx, _useAdjacentStartPoint, _useAdjacentEndPoint, _adjacentStartPoint, _adjacentEndPoint);
    }
    return 1;
  }

  @override
  bool containsPoint(ui.Offset position) => false;

  @override
  @protected
  ui.Rect computeShapeBounds(Vector2 center, double angle) {
    if (_points.isEmpty) return ui.Rect.fromCenter(center: ui.Offset(center.x, center.y), width: 0, height: 0);
    final c = math.cos(angle);
    final s = math.sin(angle);
    var minX = double.infinity, minY = double.infinity;
    var maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    for (final p in _points) {
      final wx = p.x * c - p.y * s + center.x;
      final wy = p.x * s + p.y * c + center.y;
      if (wx < minX) minX = wx;
      if (wy < minY) minY = wy;
      if (wx > maxX) maxX = wx;
      if (wy > maxY) maxY = wy;
    }
    return ui.Rect.fromLTRB(minX, minY, maxX, maxY);
  }
}
