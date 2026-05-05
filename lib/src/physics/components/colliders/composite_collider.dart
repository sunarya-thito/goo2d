import 'package:vector_math/vector_math_64.dart';
import 'package:meta/meta.dart';
import 'package:goo2d/src/physics/worker/data/collider_shape_type.dart';
import 'package:goo2d/src/physics/worker/direct/direct_collider_ops.dart';
import 'package:goo2d/goo2d.dart';

/// A Collider that can merge other Colliders together.
/// 
/// Equivalent to Unity's `CompositeCollider2D`.
class CompositeCollider extends Collider {
  @override
  ColliderShapeType get shapeType => ColliderShapeType.composite;

  @override
  @protected
  void syncProperties() {
    super.syncProperties();
    handle.then((h) {
      worker.setColliderProperty(h, ColliderProp.compositeEdgeRadius, _edgeRadius);
      worker.setColliderProperty(h, ColliderProp.compositeVertexDistance, _vertexDistance);
      worker.setColliderProperty(h, ColliderProp.compositeOffsetDistance, _offsetDistance);
      worker.setColliderProperty(h, ColliderProp.compositeUseDelaunayMesh, _useDelaunayMesh);
      worker.setColliderProperty(h, ColliderProp.compositeGeometryType, _geometryType.index);
      worker.setColliderProperty(h, ColliderProp.compositeGenerationType, _generationType.index);
    });
  }

  double _edgeRadius = 0.0;
  /// Controls the radius of all edges created by the Collider.
  double get edgeRadius => _edgeRadius;
  set edgeRadius(double value) {
    _edgeRadius = value;
    handle.then((h) => worker.setColliderProperty(h, ColliderProp.compositeEdgeRadius, value));
  }

  double _vertexDistance = 0.0005;
  /// Controls the minimum distance allowed between generated vertices.
  double get vertexDistance => _vertexDistance;
  set vertexDistance(double value) {
    _vertexDistance = value;
    handle.then((h) => worker.setColliderProperty(h, ColliderProp.compositeVertexDistance, value));
  }

  double _offsetDistance = 0.00005;
  /// Vertices are offset by this distance when compositing multiple physic shapes. Any vertices between shapes within this distance are combined.
  double get offsetDistance => _offsetDistance;
  set offsetDistance(double value) {
    _offsetDistance = value;
    handle.then((h) => worker.setColliderProperty(h, ColliderProp.compositeOffsetDistance, value));
  }

  bool _useDelaunayMesh = false;
  /// When the value is true, the Collider uses an additional Delaunay triangulation step to produce the Collider mesh. When the value is false, this additional step does not occur.
  bool get useDelaunayMesh => _useDelaunayMesh;
  set useDelaunayMesh(bool value) {
    _useDelaunayMesh = value;
    handle.then((h) => worker.setColliderProperty(h, ColliderProp.compositeUseDelaunayMesh, value));
  }

  GeometryType _geometryType = GeometryType.outlines;
  /// Specifies the type of geometry the Composite Collider should generate.
  GeometryType get geometryType => _geometryType;
  set geometryType(GeometryType value) {
    _geometryType = value;
    handle.then((h) => worker.setColliderProperty(h, ColliderProp.compositeGeometryType, value.index));
  }

  GenerationType _generationType = GenerationType.synchronous;
  /// Specifies when to generate the Composite Collider geometry.
  GenerationType get generationType => _generationType;
  set generationType(GenerationType value) {
    _generationType = value;
    handle.then((h) => worker.setColliderProperty(h, ColliderProp.compositeGenerationType, value.index));
  }

  /// The number of paths in the Collider.
  Future<int> get pathCount async => (await worker.getColliderProperty(await handle, ColliderProp.polygonPathCount)) as int;

  /// Gets the total number of points in all the paths within the Collider.
  Future<int> get pointCount async => (await worker.getColliderProperty(await handle, ColliderProp.shapeCount)) as int;

  /// Gets a path from the Collider by its index.
  Future<List<Vector2>> getPath(int index) async => const [];

  /// Gets the number of points in a path at the specified index.
  Future<int> getPathPointCount(int index) async => 0;

  /// Returns all colliders composited into this CompositeCollider.
  Future<List<Collider>> getCompositedColliders() async {
    final handles = await worker.getContactColliders(await handle);
    return handles.map((h) => PhysicsSystem.getCollider(h)).whereType<Collider>().toList();
  }

  /// Regenerates the Composite Collider geometry.
  void generateGeometry() {
    handle.then((h) => worker.colliderGenerateGeometry(h));
  }
}