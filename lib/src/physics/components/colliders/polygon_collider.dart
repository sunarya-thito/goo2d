import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/goo2d.dart';

/// Collider for 2D physics representing an arbitrary polygon defined by its vertices.
/// 
/// Equivalent to Unity's `PolygonCollider2D`.
class PolygonCollider extends Component {
  /// When the value is true, the Collider uses an additional Delaunay triangulation step to produce the Collider mesh. When the value is false, this additional step does not occur.
  bool get useDelaunayMesh => throw UnimplementedError('Implemented via Physics Worker');
  set useDelaunayMesh(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Determines whether the PolygonCollider2D's shape is automatically updated based on a SpriteRenderer's tiling properties.
  bool get autoTiling => throw UnimplementedError('Implemented via Physics Worker');
  set autoTiling(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The number of paths in the polygon.
  int get pathCount => throw UnimplementedError('Implemented via Physics Worker');
  set pathCount(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Corner points that define the collider's shape in local space.
  List<Vector2> get points => throw UnimplementedError('Implemented via Physics Worker');
  set points(List<Vector2> value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Define a path by its constituent points.
  /// - [index]: Index of the path to set.
  /// - [points]: An ordered span of the vertices (points) that define the path.
  void setPath(int index, List<Vector2> points) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Return the total number of points in the polygon in all paths.
  int getTotalPointCount() {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Create polygon shapes using the selected sprite.
  /// - [sprite]: The sprite to extract the polygon shape data from.
  /// - [detail]: The detail used when tessellating the sprite outline, in the range [0, 1]. This is only used if the sprite doesn't already have its own PhysicsShape outline(s) or usePhysicsShapes is false. This value has the same meaning as the similarly named property in the Sprite Editor.
  /// - [alphaTolerance]: The alpha tolerance used to separate the sprite from its background, in the range [0, 255]. This is only used if the sprite doesn't already have its own PhysicsShape outline(s) or usePhysicsShapes is false. This value has the same meaning as the similarly named property in the Sprite Editor.
  /// - [holeDetection]: Selects whether internal holes should be detected when creating the sprite outlines. This is only used if the sprite doesn't already have its own PhysicsShape outline(s) or usePhysicsShapes is false. This value has the same meaning as the similarly named property in the Sprite Editor.
  /// - [usePhysicsShapes]: Selects whether the outline should use the PhysicsShape outline(s) defined in the sprite. If true, they are used (if available) however if false then they are never used even if available.
  bool createFromSprite(GameSprite sprite, double detail, int alphaTolerance, bool holeDetection, bool usePhysicsShapes) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Creates as regular primitive polygon with the specified number of sides.
  /// - [sides]: The number of sides in the polygon. This must be greater than two.
  /// - [scale]: The X/Y scale of the polygon. These must be greater than zero.
  /// - [offset]: The X/Y offset of the polygon.
  void createPrimitive(int sides, Vector2 scale, Vector2 offset) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Gets a path from the Collider by its index.
  /// - [index]: The index of the path to retrieve.
  /// - [allocator]: The memory allocator to use for the results. This can only be Allocator.Temp, Allocator.TempJob or Allocator.Persistent.
  List<Vector2> getPath(int index, int allocator) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

}