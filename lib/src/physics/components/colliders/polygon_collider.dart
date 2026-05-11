import 'dart:math' as math;
import 'dart:ui' as ui;
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
    handleIfAttached?.then((h) {
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
    handleIfAttached?.then((h) => worker.setColliderProperty(h, ColliderProp.polygonUseDelaunayMesh, value));
  }

  bool _autoTiling = false;
  /// Determines whether the PolygonCollider2D's shape is automatically updated based on a SpriteRenderer's tiling properties.
  bool get autoTiling => _autoTiling;
  set autoTiling(bool value) {
    _autoTiling = value;
    handleIfAttached?.then((h) => worker.setColliderProperty(h, ColliderProp.polygonAutoTiling, value));
  }

  int _pathCount = 1;
  /// The number of paths in the polygon.
  int get pathCount => _pathCount;
  set pathCount(int value) {
    _pathCount = value;
    handleIfAttached?.then((h) => worker.setColliderProperty(h, ColliderProp.polygonPathCount, value));
  }

  List<Vector2> _points = [];
  /// Corner points that define the collider's shape in local space.
  List<Vector2> get points => _points;
  set points(List<Vector2> value) {
    _points = List.from(value);
    handleIfAttached?.then((h) => worker.setColliderProperty(h, ColliderProp.polygonPoints, _points));
  }

  /// Define a path by its constituent points.
  void setPath(int index, List<Vector2> points) {
    if (index == 0) {
      this.points = points;
    }
  }

  /// Creates a polygon shape from the Sprite outline.
  /// Generates polygon collision shapes from the alpha outline of [sprite].
  ///
  /// - [detail] controls outline density (0–1); smaller values simplify more aggressively.
  /// - [alphaTolerance] sets the minimum alpha value for a pixel to count as opaque (0–255).
  /// - [holeDetection] is accepted for API compatibility but hole detection is not yet implemented.
  ///
  /// Returns `true` if shapes were created, `false` if the sprite has no opaque pixels.
  Future<bool> createFromSprite(
    GameSprite sprite, {
    double detail = 0.25,
    int alphaTolerance = 200,
    bool holeDetection = true,
  }) async {
    final texture = sprite.texture;
    if (!texture.isLoaded) return false;
    final byteData = await texture.image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) return false;

    final bytes = byteData.buffer.asUint8List();
    final tw = texture.width;
    final sr = sprite.rect;
    final x0 = sr.left.round(), y0 = sr.top.round();
    final sw = sr.width.round(), sh = sr.height.round();
    final ppu = sprite.pixelsPerUnit;

    bool isOpaque(int col, int row) {
      final px = (x0 + col) + (y0 + row) * tw;
      return bytes[px * 4 + 3] >= alphaTolerance;
    }

    // For each column find the topmost / bottommost opaque row.
    final upperRow = List<int?>.filled(sw, null);
    final lowerRow = List<int?>.filled(sw, null);
    for (var col = 0; col < sw; col++) {
      for (var row = 0; row < sh; row++) {
        if (isOpaque(col, row)) {
          upperRow[col] ??= row;
          lowerRow[col] = row;
        }
      }
    }

    // Step size based on detail: detail=1 → every pixel, detail=0.25 → every 4 pixels.
    final step = (1.0 / detail.clamp(0.01, 1.0)).round().clamp(1, sw);

    Vector2 toWorld(double col, double row) =>
        Vector2((col - sw / 2) / ppu, -(row - sh / 2) / ppu);

    // Walk left→right along the top boundary, right→left along the bottom.
    final outline = <Vector2>[];
    for (var col = 0; col < sw; col += step) {
      if (upperRow[col] != null) outline.add(toWorld(col.toDouble(), upperRow[col]!.toDouble()));
    }
    for (var col = sw - 1; col >= 0; col -= step) {
      final b = lowerRow[col];
      if (b != null && b != upperRow[col]) outline.add(toWorld(col.toDouble(), b.toDouble()));
    }

    if (outline.length < 3) return false;
    points = outline;
    return true;
  }

  /// Get a path from the polygon by its index.
  List<Vector2> getPath(int index) {
    if (index == 0) return points;
    return [];
  }

  /// Return the total number of points in the polygon in all paths.
  int getTotalPointCount() => _points.length;

  @override
  int getShapes(PhysicsShapeGroup shapeGroup, [int shapeIndex = 0, int shapeCount = 0]) {
    if (_points.length < 3) return 0;
    shapeGroup.addPolygon(_points.map((p) => p + offset).toList());
    return 1;
  }

  @override
  bool containsPoint(ui.Offset position) {
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
