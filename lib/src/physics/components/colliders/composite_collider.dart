import 'dart:ui' as ui;
import 'package:meta/meta.dart';
import 'package:vector_math/vector_math_64.dart';
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
  void syncAllProperties() {
    super.syncAllProperties();
    worker.setColliderProperty(handle, ColliderProp.compositeEdgeRadius, _edgeRadius);
    worker.setColliderProperty(handle, ColliderProp.compositeVertexDistance, _vertexDistance);
    worker.setColliderProperty(handle, ColliderProp.compositeOffsetDistance, _offsetDistance);
    worker.setColliderProperty(handle, ColliderProp.compositeUseDelaunayMesh, _useDelaunayMesh);
    worker.setColliderProperty(handle, ColliderProp.compositeGeometryType, _geometryType.index);
    worker.setColliderProperty(handle, ColliderProp.compositeGenerationType, _generationType.index);
  }

  double _edgeRadius = 0.0;
  double get edgeRadius => _edgeRadius;
  set edgeRadius(double value) {
    _edgeRadius = value;
    if (isAttached) worker.setColliderProperty(handle, ColliderProp.compositeEdgeRadius, value);
  }

  double _vertexDistance = 0.0005;
  double get vertexDistance => _vertexDistance;
  set vertexDistance(double value) {
    _vertexDistance = value;
    if (isAttached) worker.setColliderProperty(handle, ColliderProp.compositeVertexDistance, value);
  }

  double _offsetDistance = 0.00005;
  double get offsetDistance => _offsetDistance;
  set offsetDistance(double value) {
    _offsetDistance = value;
    if (isAttached) worker.setColliderProperty(handle, ColliderProp.compositeOffsetDistance, value);
  }

  bool _useDelaunayMesh = false;
  bool get useDelaunayMesh => _useDelaunayMesh;
  set useDelaunayMesh(bool value) {
    _useDelaunayMesh = value;
    if (isAttached) worker.setColliderProperty(handle, ColliderProp.compositeUseDelaunayMesh, value);
  }

  GeometryType _geometryType = GeometryType.outlines;
  GeometryType get geometryType => _geometryType;
  set geometryType(GeometryType value) {
    _geometryType = value;
    if (isAttached) worker.setColliderProperty(handle, ColliderProp.compositeGeometryType, value.index);
  }

  GenerationType _generationType = GenerationType.synchronous;
  GenerationType get generationType => _generationType;
  set generationType(GenerationType value) {
    _generationType = value;
    if (isAttached) worker.setColliderProperty(handle, ColliderProp.compositeGenerationType, value.index);
  }

  Future<int> get pathCount async => (await worker.getColliderProperty(handle, ColliderProp.polygonPathCount)) as int;
  Future<int> get pointCount async => (await worker.getColliderProperty(handle, ColliderProp.shapeCount)) as int;

  Future<List<Vector2>> getPath(int index) async => const [];
  Future<int> getPathPointCount(int index) async => 0;

  Future<List<Collider>> getCompositedColliders() async {
    final handles = await worker.getContactColliders(handle);
    return handles.map((h) => PhysicsSystem.getCollider(h)).whereType<Collider>().toList();
  }

  void generateGeometry() {
    if (isAttached) worker.colliderGenerateGeometry(handle);
  }

  @override
  bool containsPoint(ui.Offset position) => false;
}
