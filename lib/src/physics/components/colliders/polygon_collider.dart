import 'dart:math' as math;
import 'dart:ui' show Offset;
import 'package:vector_math/vector_math_64.dart';
import 'package:meta/meta.dart';
import 'package:goo2d/src/physics/components/collider.dart';
import 'package:goo2d/src/physics/worker/direct/direct_collider_ops.dart';
import 'package:goo2d/src/physics/worker/data/collider_shape_type.dart';
import 'package:goo2d/goo2d.dart';

/// Collider for 2D physics representing an arbitrary polygon defined by its vertices.
/// 
/// Equivalent to Unity's `PolygonCollider2D`.
class PolygonCollider extends Collider {
  @override
  ColliderShapeType get shapeType => ColliderShapeType.polygon;

  @override
  @protected
  void syncProperties() {
    super.syncProperties();
    handle.then((h) {
      worker.setColliderProperty(h, ColliderProp.polygonUseDelaunayMesh, _useDelaunayMesh);
      worker.setColliderProperty(h, ColliderProp.polygonAutoTiling, _autoTiling);
      worker.setColliderProperty(h, ColliderProp.polygonPathCount, _pathCount);
      worker.setColliderProperty(h, ColliderProp.polygonPoints, _points);
    });
  }

  bool _useDelaunayMesh = false;
  /// When the value is true, the Collider uses an additional Delaunay triangulation step to produce the Collider mesh.
  bool get useDelaunayMesh => _useDelaunayMesh;
  set useDelaunayMesh(bool value) {
    _useDelaunayMesh = value;
    handle.then((h) => worker.setColliderProperty(h, ColliderProp.polygonUseDelaunayMesh, value));
  }

  bool _autoTiling = false;
  /// Determines whether the PolygonCollider2D's shape is automatically updated based on a SpriteRenderer's tiling properties.
  bool get autoTiling => _autoTiling;
  set autoTiling(bool value) {
    _autoTiling = value;
    handle.then((h) => worker.setColliderProperty(h, ColliderProp.polygonAutoTiling, value));
  }

  int _pathCount = 1;
  /// The number of paths in the polygon.
  int get pathCount => _pathCount;
  set pathCount(int value) {
    _pathCount = value;
    handle.then((h) => worker.setColliderProperty(h, ColliderProp.polygonPathCount, value));
  }

  List<Vector2> _points = [];
  /// Corner points that define the collider's shape in local space.
  List<Vector2> get points => _points;
  set points(List<Vector2> value) {
    _points = List.from(value);
    handle.then((h) => worker.setColliderProperty(h, ColliderProp.polygonPoints, _points));
  }

  /// Define a path by its constituent points.
  void setPath(int index, List<Vector2> points) {
    if (index == 0) {
      this.points = points;
    }
  }

  /// Creates a polygon shape from the Sprite outline.
  void createFromSprite(GameSprite sprite) {
    // TODO: Use SpritePolygonGenerator to generate points from sprite alpha
  }

  /// Get a path from the polygon by its index.
  List<Vector2> getPath(int index) {
    if (index == 0) return points;
    return [];
  }

  /// Return the total number of points in the polygon in all paths.
  int getTotalPointCount() => _points.length;

  @override
  bool containsPoint(Offset position) {
    if (_points.length < 3) return false;
    final px = position.dx - offset.x;
    final py = position.dy - offset.y;
    // Ray-casting algorithm
    bool inside = false;
    int j = _points.length - 1;
    for (int i = 0; i < _points.length; i++) {
      final xi = _points[i].x, yi = _points[i].y;
      final xj = _points[j].x, yj = _points[j].y;
      if ((yi > py) != (yj > py) && px < (xj - xi) * (py - yi) / (yj - yi) + xi) {
        inside = !inside;
      }
      j = i;
    }
    return inside;
  }

  /// Creates as regular primitive polygon with the specified number of sides.
  void createPrimitive(int sides, Vector2 scale, Vector2 offset) {
    final newPoints = <Vector2>[];
    final angleStep = (2 * math.pi) / sides;
    for (var i = 0; i < sides; i++) {
      final angle = i * angleStep;
      newPoints.add(Vector2(
        offset.x + scale.x * 0.5 * (1 + math.cos(angle)),
        offset.y + scale.y * 0.5 * (1 + math.sin(angle)),
      ));
    }
    points = newPoints;
  }
}
