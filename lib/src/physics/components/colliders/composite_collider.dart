import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/goo2d.dart';

/// A Collider that can merge other Colliders together.
/// 
/// Equivalent to Unity's `CompositeCollider2D`.
class CompositeCollider extends Component {
  /// Controls the radius of all edges created by the Collider.
  double get edgeRadius => throw UnimplementedError('Implemented via Physics Worker');
  set edgeRadius(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Controls the minimum distance allowed between generated vertices.
  double get vertexDistance => throw UnimplementedError('Implemented via Physics Worker');
  set vertexDistance(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Vertices are offset by this distance when compositing multiple physic shapes. Any vertices between shapes within this distance are combined.
  double get offsetDistance => throw UnimplementedError('Implemented via Physics Worker');
  set offsetDistance(double value) => throw UnimplementedError('Implemented via Physics Worker');

  /// When the value is true, the Collider uses an additional Delaunay triangulation step to produce the Collider mesh. When the value is false, this additional step does not occur.
  bool get useDelaunayMesh => throw UnimplementedError('Implemented via Physics Worker');
  set useDelaunayMesh(bool value) => throw UnimplementedError('Implemented via Physics Worker');

  /// The number of paths in the Collider.
  int get pathCount => throw UnimplementedError('Implemented via Physics Worker');
  set pathCount(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Specifies when to generate the Composite Collider geometry.
  GenerationType get generationType => throw UnimplementedError('Implemented via Physics Worker');
  set generationType(GenerationType value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Specifies the type of geometry the Composite Collider should generate.
  GeometryType get geometryType => throw UnimplementedError('Implemented via Physics Worker');
  set geometryType(GeometryType value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Gets the total number of points in all the paths within the Collider.
  int get pointCount => throw UnimplementedError('Implemented via Physics Worker');
  set pointCount(int value) => throw UnimplementedError('Implemented via Physics Worker');

  /// Gets a path from the Collider by its index.
  /// - [index]: The index of the path from 0 to pathCount minus 1.
  /// - [allocator]: The memory allocator to use for the results. This can only be Allocator.Temp, Allocator.TempJob or Allocator.Persistent.
  List<Vector2> getPath(int index, int allocator) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Gets the number of points in the specified path from the Collider by its index.
  /// - [index]: The index of the path from 0 to pathCount minus 1.
  int getPathPointCount(int index) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// TODO.
  /// - [allocator]: The memory allocator to use for the results. This can only be Allocator.Temp, Allocator.TempJob or Allocator.Persistent.
  List<Collider> getCompositedColliders(int allocator) {
    throw UnimplementedError('Implemented via Physics Worker');
  }

  /// Regenerates the Composite Collider geometry.
  void generateGeometry() {
    throw UnimplementedError('Implemented via Physics Worker');
  }

}