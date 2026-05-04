import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/src/physics/worker/data/collider_shape_type.dart';

/// Internal collider representation matching Unity's Collider2D state.
class PhysicsCollider {
  final int handle;
  final ColliderShapeType shapeType;
  int bodyHandle;

  // Common
  Vector2 offset = Vector2.zero();
  bool isTrigger = false;
  double density = 1.0;
  double friction = 0.4;
  double bounciness = 0.0;
  int frictionCombine = 0;
  int bounceCombine = 0;
  int compositeOperation = 2; // none
  int compositeOrder = 0;
  bool usedByEffector = false;
  int sharedMaterialHandle = -1;
  int excludeLayers = 0;
  int includeLayers = 0;
  int callbackLayers = ~0;
  int contactCaptureLayers = ~0;
  int forceReceiveLayers = ~0;
  int forceSendLayers = ~0;
  int layerOverridePriority = 0;
  int errorState = 0;
  int shapeCount = 1;
  bool compositeCapable = true;

  // Box
  Vector2 boxSize = Vector2(1, 1);
  double boxEdgeRadius = 0.0;
  bool boxAutoTiling = false;

  // Circle
  double circleRadius = 0.5;

  // Capsule
  Vector2 capsuleSize = Vector2(1, 2);
  int capsuleDirection = 0;

  // Polygon
  List<Vector2> polygonPoints = [];
  int polygonPathCount = 1;
  bool polygonAutoTiling = false;
  bool polygonUseDelaunayMesh = false;

  // Edge
  List<Vector2> edgePoints = [];
  double edgeRadius = 0.0;
  bool edgeUseAdjacentStartPoint = false;
  bool edgeUseAdjacentEndPoint = false;
  Vector2 edgeAdjacentStartPoint = Vector2.zero();
  Vector2 edgeAdjacentEndPoint = Vector2.zero();

  // Composite
  double compositeEdgeRadius = 0.0;
  double compositeVertexDistance = 0.0;
  double compositeOffsetDistance = 0.0;
  bool compositeUseDelaunayMesh = false;
  int compositeGenerationType = 1;
  int compositeGeometryType = 0;

  PhysicsCollider(this.handle, this.shapeType, this.bodyHandle);
}
