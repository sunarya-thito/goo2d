import 'dart:ui' show Offset;
import 'package:vector_math/vector_math_64.dart';
import 'package:meta/meta.dart';
import 'package:goo2d/src/physics/components/collider.dart';
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
  void syncProperties() {
    super.syncProperties();
    handle.then((h) {
      worker.setColliderProperty(h, ColliderProp.edgePoints, _points);
      worker.setColliderProperty(h, ColliderProp.edgeUseAdjacentStartPoint, _useAdjacentStartPoint);
      worker.setColliderProperty(h, ColliderProp.edgeUseAdjacentEndPoint, _useAdjacentEndPoint);
      worker.setColliderProperty(h, ColliderProp.edgeAdjacentStartPoint, _adjacentStartPoint);
      worker.setColliderProperty(h, ColliderProp.edgeAdjacentEndPoint, _adjacentEndPoint);
      worker.setColliderProperty(h, ColliderProp.edgeRadius, _edgeRadius);
    });
  }

  List<Vector2> _points = [];
  /// Get or set the points defining multiple continuous edges.
  List<Vector2> get points => _points;
  set points(List<Vector2> value) {
    _points = List.from(value);
    handle.then((h) => worker.setColliderProperty(h, ColliderProp.edgePoints, _points));
  }

  bool _useAdjacentStartPoint = false;
  /// Set this to true to use the adjacentStartPoint to form the collision normal.
  bool get useAdjacentStartPoint => _useAdjacentStartPoint;
  set useAdjacentStartPoint(bool value) {
    _useAdjacentStartPoint = value;
    handle.then((h) => worker.setColliderProperty(h, ColliderProp.edgeUseAdjacentStartPoint, value));
  }

  bool _useAdjacentEndPoint = false;
  /// Set this to true to use the adjacentEndPoint to form the collision normal.
  bool get useAdjacentEndPoint => _useAdjacentEndPoint;
  set useAdjacentEndPoint(bool value) {
    _useAdjacentEndPoint = value;
    handle.then((h) => worker.setColliderProperty(h, ColliderProp.edgeUseAdjacentEndPoint, value));
  }

  Vector2 _adjacentStartPoint = Vector2.zero();
  /// Defines the position of a virtual point adjacent to the start point.
  Vector2 get adjacentStartPoint => _adjacentStartPoint;
  set adjacentStartPoint(Vector2 value) {
    _adjacentStartPoint.setFrom(value);
    handle.then((h) => worker.setColliderProperty(h, ColliderProp.edgeAdjacentStartPoint, value));
  }

  Vector2 _adjacentEndPoint = Vector2.zero();
  /// Defines the position of a virtual point adjacent to the end point.
  Vector2 get adjacentEndPoint => _adjacentEndPoint;
  set adjacentEndPoint(Vector2 value) {
    _adjacentEndPoint.setFrom(value);
    handle.then((h) => worker.setColliderProperty(h, ColliderProp.edgeAdjacentEndPoint, value));
  }

  double _edgeRadius = 0;
  /// Controls the radius of all edges created by the collider.
  double get edgeRadius => _edgeRadius;
  set edgeRadius(double value) {
    _edgeRadius = value;
    handle.then((h) => worker.setColliderProperty(h, ColliderProp.edgeRadius, value));
  }

  /// Gets the number of edges.
  int get edgeCount => _points.length > 1 ? _points.length - 1 : 0;

  /// Gets the number of points.
  int get pointCount => _points.length;

  /// Reset to a single edge consisting of two points.
  void reset() {
    points = [Vector2(-1, 0), Vector2(1, 0)];
  }

  /// Gets all the points that define a set of continuous edges.
  List<Vector2> getPoints() => points;

  /// Sets all the points that define a set of continuous edges.
  bool setPoints(List<Vector2> points) {
    if (points.length < 2) return false;
    this.points = points;
    return true;
  }

  // Edge colliders have no area — hit testing is not supported.
  @override
  bool containsPoint(Offset position) => false;
}
