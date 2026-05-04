import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/src/physics/worker/engine/physics_engine.dart';
import 'package:goo2d/src/physics/worker/data/collider_shape_type.dart';

/// Collider property indices for generic get/set access.
class ColliderProp {
  static const int offset = 0;
  static const int isTrigger = 1;
  static const int density = 2;
  static const int friction = 3;
  static const int bounciness = 4;
  static const int frictionCombine = 5;
  static const int bounceCombine = 6;
  static const int compositeOperation = 7;
  static const int compositeOrder = 8;
  static const int usedByEffector = 9;
  static const int sharedMaterialHandle = 10;
  static const int excludeLayers = 11;
  static const int includeLayers = 12;
  static const int callbackLayers = 13;
  static const int contactCaptureLayers = 14;
  static const int forceReceiveLayers = 15;
  static const int forceSendLayers = 16;
  static const int layerOverridePriority = 17;
  static const int errorState = 18;
  static const int shapeCount = 19;
  static const int compositeCapable = 20;
  static const int layer = 21;
  // Box
  static const int boxSize = 100;
  static const int boxEdgeRadius = 101;
  static const int boxAutoTiling = 102;
  // Circle
  static const int circleRadius = 200;
  // Capsule
  static const int capsuleSize = 300;
  static const int capsuleDirection = 301;
  // Polygon
  static const int polygonPoints = 400;
  static const int polygonPathCount = 401;
  static const int polygonAutoTiling = 402;
  static const int polygonUseDelaunayMesh = 403;
  // Edge
  static const int edgePoints = 500;
  static const int edgeRadius = 501;
  static const int edgeUseAdjacentStartPoint = 502;
  static const int edgeUseAdjacentEndPoint = 503;
  static const int edgeAdjacentStartPoint = 504;
  static const int edgeAdjacentEndPoint = 505;
  // Composite
  static const int compositeEdgeRadius = 600;
  static const int compositeVertexDistance = 601;
  static const int compositeOffsetDistance = 602;
  static const int compositeUseDelaunayMesh = 603;
  static const int compositeGenerationType = 604;
  static const int compositeGeometryType = 605;
}

/// Direct collider operations. `object → invocation`.
class DirectColliderOps {
  DirectColliderOps._();

  static Future<int> create(PhysicsEngine e, ColliderShapeType t, int bh) => Future.value(e.createCollider(t, bh));
  static Future<void> destroy(PhysicsEngine e, int h) { e.destroyCollider(h); return Future.value(); }

  static Future<Object?> getProperty(PhysicsEngine e, int h, int p) {
    final c = e.getCollider(h);
    return Future.value(switch (p) {
      ColliderProp.offset => c.offset,
      ColliderProp.isTrigger => c.isTrigger,
      ColliderProp.density => c.density,
      ColliderProp.friction => c.friction,
      ColliderProp.bounciness => c.bounciness,
      ColliderProp.frictionCombine => c.frictionCombine,
      ColliderProp.bounceCombine => c.bounceCombine,
      ColliderProp.compositeOperation => c.compositeOperation,
      ColliderProp.compositeOrder => c.compositeOrder,
      ColliderProp.usedByEffector => c.usedByEffector,
      ColliderProp.sharedMaterialHandle => c.sharedMaterialHandle,
      ColliderProp.excludeLayers => c.excludeLayers,
      ColliderProp.includeLayers => c.includeLayers,
      ColliderProp.layer => c.layer,
      ColliderProp.callbackLayers => c.callbackLayers,
      ColliderProp.contactCaptureLayers => c.contactCaptureLayers,
      ColliderProp.forceReceiveLayers => c.forceReceiveLayers,
      ColliderProp.forceSendLayers => c.forceSendLayers,
      ColliderProp.layerOverridePriority => c.layerOverridePriority,
      ColliderProp.errorState => c.errorState,
      ColliderProp.shapeCount => c.shapeCount,
      ColliderProp.compositeCapable => c.compositeCapable,
      ColliderProp.boxSize => c.boxSize,
      ColliderProp.boxEdgeRadius => c.boxEdgeRadius,
      ColliderProp.boxAutoTiling => c.boxAutoTiling,
      ColliderProp.circleRadius => c.circleRadius,
      ColliderProp.capsuleSize => c.capsuleSize,
      ColliderProp.capsuleDirection => c.capsuleDirection,
      ColliderProp.polygonPoints => c.polygonPoints,
      ColliderProp.polygonPathCount => c.polygonPathCount,
      ColliderProp.polygonAutoTiling => c.polygonAutoTiling,
      ColliderProp.polygonUseDelaunayMesh => c.polygonUseDelaunayMesh,
      ColliderProp.edgePoints => c.edgePoints,
      ColliderProp.edgeRadius => c.edgeRadius,
      ColliderProp.edgeUseAdjacentStartPoint => c.edgeUseAdjacentStartPoint,
      ColliderProp.edgeUseAdjacentEndPoint => c.edgeUseAdjacentEndPoint,
      ColliderProp.edgeAdjacentStartPoint => c.edgeAdjacentStartPoint,
      ColliderProp.edgeAdjacentEndPoint => c.edgeAdjacentEndPoint,
      ColliderProp.compositeEdgeRadius => c.compositeEdgeRadius,
      ColliderProp.compositeVertexDistance => c.compositeVertexDistance,
      ColliderProp.compositeOffsetDistance => c.compositeOffsetDistance,
      ColliderProp.compositeUseDelaunayMesh => c.compositeUseDelaunayMesh,
      ColliderProp.compositeGenerationType => c.compositeGenerationType,
      ColliderProp.compositeGeometryType => c.compositeGeometryType,
      _ => throw ArgumentError('Unknown collider property: $p'),
    });
  }

  static Future<void> setProperty(PhysicsEngine e, int h, int p, Object? v) {
    final c = e.getCollider(h);
    switch (p) {
      case ColliderProp.offset: c.offset.setFrom(v as Vector2);
      case ColliderProp.isTrigger: c.isTrigger = v as bool;
      case ColliderProp.density: c.density = v as double;
      case ColliderProp.friction: c.friction = v as double;
      case ColliderProp.bounciness: c.bounciness = v as double;
      case ColliderProp.frictionCombine: c.frictionCombine = v as int;
      case ColliderProp.bounceCombine: c.bounceCombine = v as int;
      case ColliderProp.compositeOperation: c.compositeOperation = v as int;
      case ColliderProp.compositeOrder: c.compositeOrder = v as int;
      case ColliderProp.usedByEffector: c.usedByEffector = v as bool;
      case ColliderProp.sharedMaterialHandle: c.sharedMaterialHandle = v as int;
      case ColliderProp.excludeLayers: c.excludeLayers = v as int;
      case ColliderProp.includeLayers: c.includeLayers = v as int;
      case ColliderProp.layer: c.layer = v as int;
      case ColliderProp.callbackLayers: c.callbackLayers = v as int;
      case ColliderProp.contactCaptureLayers: c.contactCaptureLayers = v as int;
      case ColliderProp.forceReceiveLayers: c.forceReceiveLayers = v as int;
      case ColliderProp.forceSendLayers: c.forceSendLayers = v as int;
      case ColliderProp.layerOverridePriority: c.layerOverridePriority = v as int;
      case ColliderProp.errorState: c.errorState = v as int;
      case ColliderProp.shapeCount: c.shapeCount = v as int;
      case ColliderProp.compositeCapable: c.compositeCapable = v as bool;
      case ColliderProp.boxSize: c.boxSize.setFrom(v as Vector2);
      case ColliderProp.boxEdgeRadius: c.boxEdgeRadius = v as double;
      case ColliderProp.boxAutoTiling: c.boxAutoTiling = v as bool;
      case ColliderProp.circleRadius: c.circleRadius = v as double;
      case ColliderProp.capsuleSize: c.capsuleSize.setFrom(v as Vector2);
      case ColliderProp.capsuleDirection: c.capsuleDirection = v as int;
      case ColliderProp.polygonPoints: c.polygonPoints = v as List<Vector2>;
      case ColliderProp.polygonPathCount: c.polygonPathCount = v as int;
      case ColliderProp.polygonAutoTiling: c.polygonAutoTiling = v as bool;
      case ColliderProp.polygonUseDelaunayMesh: c.polygonUseDelaunayMesh = v as bool;
      case ColliderProp.edgePoints: c.edgePoints = v as List<Vector2>;
      case ColliderProp.edgeRadius: c.edgeRadius = v as double;
      case ColliderProp.edgeUseAdjacentStartPoint: c.edgeUseAdjacentStartPoint = v as bool;
      case ColliderProp.edgeUseAdjacentEndPoint: c.edgeUseAdjacentEndPoint = v as bool;
      case ColliderProp.edgeAdjacentStartPoint: c.edgeAdjacentStartPoint.setFrom(v as Vector2);
      case ColliderProp.edgeAdjacentEndPoint: c.edgeAdjacentEndPoint.setFrom(v as Vector2);
      case ColliderProp.compositeEdgeRadius: c.compositeEdgeRadius = v as double;
      case ColliderProp.compositeVertexDistance: c.compositeVertexDistance = v as double;
      case ColliderProp.compositeOffsetDistance: c.compositeOffsetDistance = v as double;
      case ColliderProp.compositeUseDelaunayMesh: c.compositeUseDelaunayMesh = v as bool;
      case ColliderProp.compositeGenerationType: c.compositeGenerationType = v as int;
      case ColliderProp.compositeGeometryType: c.compositeGeometryType = v as int;
      default: throw ArgumentError('Unknown collider property: $p');
    }
    return Future.value();
  }

  static Future<Vector2> closestPoint(PhysicsEngine e, int h, Vector2 p) => Future.value(e.closestPoint(p, h));
  static Future<double> distance(PhysicsEngine e, int a, int b) => Future.value(e.distanceBetween(a, b));
  static Future<bool> isTouching(PhysicsEngine e, int a, int b) => Future.value(e.isTouching(a, b));
  static Future<bool> isTouchingLayers(PhysicsEngine e, int h, int l) => Future.value(e.isTouchingLayers(h, l));
}
