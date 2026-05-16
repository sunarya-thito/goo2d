import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:vector_math/vector_math_64.dart';
import 'package:meta/meta.dart';
import 'package:goo2d/src/physics/worker/physics_worker.dart';
import 'package:goo2d/src/physics/worker/direct/direct_collider_ops.dart';
import 'package:goo2d/src/physics/worker/data/collider_shape_type.dart';
import 'package:goo2d/goo2d.dart';

/// The parent class for collider types used with 2D gameplay. Provides methods to defines the shape and physical behavior for 2D object interactions, used to detect collisions, and trigger events in 2D game environments.
/// 
/// Equivalent to Unity's `Collider2D`.
abstract class Collider extends Behavior {
  late int _handle;

  /// The internal physics handle for this collider.
  int get handle {
    assert(isAttached, 'Collider must be attached to a GameObject before accessing handle.');
    return _handle;
  }

  /// The shape type of this collider.
  ColliderShapeType get shapeType;

  @protected
  PhysicsWorker get worker => game.getSystem<PhysicsSystem>()!.worker;

  @override
  void internalAttach(GameObject gameObject) {
    super.internalAttach(gameObject);
    final rb = gameObject.tryGetComponent<Rigidbody>();
    if (rb == null) {
      throw StateError('Collider requires a Rigidbody component on the same GameObject.');
    }
    _handle = worker.createCollider(shapeType, rb.handle);
    PhysicsSystem.registerCollider(_handle, this);
    syncAllProperties();
  }

  @override
  void internalDetach() {
    PhysicsSystem.unregisterCollider(_handle, this);
    worker.destroyCollider(_handle);
    super.internalDetach();
  }

  @override
  set enabled(bool value) {
    super.enabled = value;
    if (isAttached) worker.setColliderProperty(_handle, ColliderProp.enabled, value);
  }

  @protected
  void syncAllProperties() {
    worker.setColliderProperty(_handle, ColliderProp.enabled, enabled);
    worker.setColliderProperty(_handle, ColliderProp.offset, _offset.clone());
    worker.setColliderProperty(_handle, ColliderProp.isTrigger, _isTrigger);
    worker.setColliderProperty(_handle, ColliderProp.density, _density);
    worker.setColliderProperty(_handle, ColliderProp.friction, _friction);
    worker.setColliderProperty(_handle, ColliderProp.bounciness, _bounciness);
    worker.setColliderProperty(_handle, ColliderProp.frictionCombine, _frictionCombine.index);
    worker.setColliderProperty(_handle, ColliderProp.bounceCombine, _bounceCombine.index);
    worker.setColliderProperty(_handle, ColliderProp.compositeOperation, _compositeOperation.index);
    worker.setColliderProperty(_handle, ColliderProp.compositeOrder, _compositeOrder);
    worker.setColliderProperty(_handle, ColliderProp.usedByEffector, _usedByEffector);
    worker.setColliderProperty(_handle, ColliderProp.excludeLayers, _excludeLayers);
    worker.setColliderProperty(_handle, ColliderProp.includeLayers, _includeLayers);
    worker.setColliderProperty(_handle, ColliderProp.callbackLayers, _callbackLayers);
    worker.setColliderProperty(_handle, ColliderProp.contactCaptureLayers, _contactCaptureLayers);
    worker.setColliderProperty(_handle, ColliderProp.forceReceiveLayers, _forceReceiveLayers);
    worker.setColliderProperty(_handle, ColliderProp.forceSendLayers, _forceSendLayers);
    worker.setColliderProperty(_handle, ColliderProp.layerOverridePriority, _layerOverridePriority);
  }

  // --- Configuration Properties (Sync) ---

  Vector2 _offset = Vector2.zero();
  Vector2 get offset => _offset;
  set offset(Vector2 value) {
    _offset.setFrom(value);
    if (isAttached) worker.setColliderProperty(_handle, ColliderProp.offset, value.clone());
  }

  bool _isTrigger = false;
  bool get isTrigger => _isTrigger;
  set isTrigger(bool value) {
    _isTrigger = value;
    if (isAttached) worker.setColliderProperty(_handle, ColliderProp.isTrigger, value);
  }

  double _density = 1.0;
  double get density => _density;
  set density(double value) {
    _density = value;
    if (isAttached) worker.setColliderProperty(_handle, ColliderProp.density, value);
  }

  double _friction = 0.4;
  double get friction => _friction;
  set friction(double value) {
    _friction = value;
    if (isAttached) worker.setColliderProperty(_handle, ColliderProp.friction, value);
  }

  double _bounciness = 0.0;
  double get bounciness => _bounciness;
  set bounciness(double value) {
    _bounciness = value;
    if (isAttached) worker.setColliderProperty(_handle, ColliderProp.bounciness, value);
  }

  PhysicsMaterialCombine _frictionCombine = PhysicsMaterialCombine.average;
  PhysicsMaterialCombine get frictionCombine => _frictionCombine;
  set frictionCombine(PhysicsMaterialCombine value) {
    _frictionCombine = value;
    if (isAttached) worker.setColliderProperty(_handle, ColliderProp.frictionCombine, value.index);
  }

  PhysicsMaterialCombine _bounceCombine = PhysicsMaterialCombine.average;
  PhysicsMaterialCombine get bounceCombine => _bounceCombine;
  set bounceCombine(PhysicsMaterialCombine value) {
    _bounceCombine = value;
    if (isAttached) worker.setColliderProperty(_handle, ColliderProp.bounceCombine, value.index);
  }

  CompositeOperation _compositeOperation = CompositeOperation.none;
  CompositeOperation get compositeOperation => _compositeOperation;
  set compositeOperation(CompositeOperation value) {
    _compositeOperation = value;
    if (isAttached) worker.setColliderProperty(_handle, ColliderProp.compositeOperation, value.index);
  }

  int _compositeOrder = 0;
  int get compositeOrder => _compositeOrder;
  set compositeOrder(int value) {
    _compositeOrder = value;
    if (isAttached) worker.setColliderProperty(_handle, ColliderProp.compositeOrder, value);
  }

  bool _usedByEffector = false;
  bool get usedByEffector => _usedByEffector;
  set usedByEffector(bool value) {
    _usedByEffector = value;
    if (isAttached) worker.setColliderProperty(_handle, ColliderProp.usedByEffector, value);
  }

  int _excludeLayers = 0;
  int get excludeLayers => _excludeLayers;
  set excludeLayers(int value) {
    _excludeLayers = value;
    if (isAttached) worker.setColliderProperty(_handle, ColliderProp.excludeLayers, value);
  }

  int _includeLayers = 0;
  int get includeLayers => _includeLayers;
  set includeLayers(int value) {
    _includeLayers = value;
    if (isAttached) worker.setColliderProperty(_handle, ColliderProp.includeLayers, value);
  }

  int _callbackLayers = ~0;
  int get callbackLayers => _callbackLayers;
  set callbackLayers(int value) {
    _callbackLayers = value;
    if (isAttached) worker.setColliderProperty(_handle, ColliderProp.callbackLayers, value);
  }

  int _contactCaptureLayers = ~0;
  int get contactCaptureLayers => _contactCaptureLayers;
  set contactCaptureLayers(int value) {
    _contactCaptureLayers = value;
    if (isAttached) worker.setColliderProperty(_handle, ColliderProp.contactCaptureLayers, value);
  }

  int _forceReceiveLayers = ~0;
  int get forceReceiveLayers => _forceReceiveLayers;
  set forceReceiveLayers(int value) {
    _forceReceiveLayers = value;
    if (isAttached) worker.setColliderProperty(_handle, ColliderProp.forceReceiveLayers, value);
  }

  int _forceSendLayers = ~0;
  int get forceSendLayers => _forceSendLayers;
  set forceSendLayers(int value) {
    _forceSendLayers = value;
    if (isAttached) worker.setColliderProperty(_handle, ColliderProp.forceSendLayers, value);
  }

  int _layerOverridePriority = 0;
  int get layerOverridePriority => _layerOverridePriority;
  set layerOverridePriority(int value) {
    _layerOverridePriority = value;
    if (isAttached) worker.setColliderProperty(_handle, ColliderProp.layerOverridePriority, value);
  }

  // --- Read-Only / Computed Properties ---

  Future<ColliderErrorState> get errorState async => (await worker.getColliderProperty(_handle, ColliderProp.errorState)) as ColliderErrorState;
  Future<int> get shapeCount async => (await worker.getColliderProperty(_handle, ColliderProp.shapeCount)) as int;
  Future<bool> get compositeCapable async => (await worker.getColliderProperty(_handle, ColliderProp.compositeCapable)) as bool;

  /// The world space bounding area of the collider.
  ui.Rect get bounds {
    final t = gameObject.getComponent<ObjectTransform>();
    final pos = t.position;
    final wm = t.worldMatrix;
    final angle = math.atan2(wm.entry(1, 0), wm.entry(0, 0));
    return computeShapeBounds(Vector2(pos.x + _offset.x, pos.y + _offset.y), angle);
  }

  @protected
  ui.Rect computeShapeBounds(Vector2 center, double angle) =>
      ui.Rect.fromCenter(center: ui.Offset(center.x, center.y), width: 0, height: 0);

  /// Alias for [bounds] used by screen visibility tracking.
  ui.Rect get worldBounds => bounds;

  /// Internal screen state — whether this collider overlapped the screen last frame.
  bool wasOverlappingScreen = false;

  /// Internal screen state — whether this collider was fully inside the screen last frame.
  bool wasFullyInsideScreen = false;

  /// The transformation matrix used to transform the Collider physics shapes to world space.
  Matrix4 get localToWorldMatrix => gameObject.getComponent<ObjectTransform>().worldMatrix;

  /// The Rigidbody2D attached to the Collider2D.
  Rigidbody get attachedRigidbody => gameObject.getComponent<Rigidbody>();

  /// Get the CompositeCollider2D that is available to be attached to the collider.
  CompositeCollider? get composite => gameObject.getComponent<CompositeCollider>();

  /// Calculates the effective LayerMask that the Collider2D will use when determining if it can contact another Collider2D.
  int get contactMask => _callbackLayers & ~_excludeLayers | _includeLayers;

  // --- Methods ---

  /// This method determines if both Colliders can ever come into contact.
  bool canContact(Collider collider) => (contactMask & (1 << collider.gameObject.layer)) != 0;

  /// Returns a point on the perimeter of this Collider that is closest to the specified position.
  Future<Vector2> closestPoint(Vector2 position) => worker.colliderClosestPoint(_handle, position);

  /// Calculates the minimum separation of this collider against another collider.
  Future<double> distance(Collider collider) => worker.colliderDistance(_handle, collider._handle);

  /// Check whether this collider is touching the collider or not.
  Future<bool> isTouching(Collider collider) => worker.colliderIsTouching(_handle, collider._handle);

  /// Checks whether this collider is touching any colliders on the specified layerMask or not.
  Future<bool> isTouchingLayers(int layerMask) => worker.colliderIsTouchingLayers(_handle, layerMask);

  /// Check if a collider overlaps a point in space.
  Future<bool> overlapPoint(Vector2 point) async => (await worker.overlapPoint(point, 1 << gameObject.layer, 0, 0)).contains(_handle);

  /// Synchronous point-in-shape test in the object's local coordinate space.
  ///
  /// Used by the render hit-test system. The [position] is already transformed
  /// into local game-unit space by [GameRenderObject.hitTest] before this is
  /// called. Each Collider subclass overrides this with its own geometry test.
  bool containsPoint(ui.Offset position) => false;

  PhysicsMaterial? _sharedMaterial;

  /// The PhysicsMaterial2D that is shared by this Collider2D.
  PhysicsMaterial? get sharedMaterial => _sharedMaterial;
  set sharedMaterial(PhysicsMaterial? value) {
    _sharedMaterial = value;
    if (value == null) return;
    friction = value.friction;
    bounciness = value.bounciness;
    frictionCombine = value.frictionCombine;
    bounceCombine = value.bounceCombine;
  }

  /// Casts the Collider shape into the Scene starting at the Collider position.
  Future<List<RaycastHit>> cast(Vector2 direction, [double distance = double.infinity, bool ignoreSiblingColliders = true]) async {
    final transform = gameObject.getComponent<ObjectTransform>();
    return Physics.boxCastAll(transform.position, Vector2(1, 1), transform.angle, direction, distance, ~0, -double.infinity, double.infinity);
  }

  /// Creates a mesh representation of the Collider2D shape.
  /// Returns null — the engine has no Mesh asset class yet; this is a stub until one is added.
  Object? createMesh(bool useDelaunayMesh, double extrusionAmount) => null;

  /// Retrieves all colliders in contact with this Collider2D.
  Future<List<Collider>> getContactColliders() async {
    final handles = await worker.getContactColliders(_handle);
    return handles.map((h) => PhysicsSystem.getCollider(h)).whereType<Collider>().toList();
  }

  /// Fills [shapeGroup] with the physics shapes used by this Collider2D.
  /// Returns the number of shapes added.
  int getShapes(PhysicsShapeGroup shapeGroup, [int shapeIndex = 0, int shapeCount = 0]) => 0;

  /// Returns a hash of the current physics shapes, useful for change detection.
  int getShapeHash() {
    final group = PhysicsShapeGroup();
    final count = getShapes(group);
    if (count == 0) return 0;
    var hash = count;
    for (var i = 0; i < count; i++) {
      final s = group.getShape(i);
      hash = hash ^ (s.shapeType.index * 397) ^ (s.radius * 1000).toInt() ^ (s.vertexCount * 31);
    }
    return hash;
  }

  /// Retrieves all contact points for all the contacts currently involving this Collider2D.
  Future<List<ContactPoint>> getContacts() async {
    final data = await worker.getContacts(_handle);
    return data.map((d) => ContactPoint.fromData(d)).whereType<ContactPoint>().toList();
  }

  /// Returns the world-space bounding area for a specific shape in the Collider2D.
  ui.Rect getShapeBounds(int shapeIndex) => bounds;

  /// Casts a ray into the Scene that starts at the Collider2D position and ignores the Collider2D itself.
  Future<List<RaycastHit>> raycast(Vector2 direction, [double distance = double.infinity, int layerMask = ~0, double minDepth = -double.infinity, double maxDepth = double.infinity]) async {
    final pos = gameObject.getComponent<ObjectTransform>().position;
    return Physics.raycastAll(Vector2(pos.x, pos.y), direction, distance, layerMask, minDepth, maxDepth);
  }

  /// Get a list of all Colliders that overlap this Collider2D.
  Future<List<Collider>> overlap() async {
    final handles = await worker.overlapCollider(_handle);
    return handles.map((h) => PhysicsSystem.getCollider(h)).whereType<Collider>().toList();
  }
}
