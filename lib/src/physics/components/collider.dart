import 'dart:async';
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
abstract class Collider extends Component {
  Future<int>? _handleFuture;

  /// The internal physics handle for this collider.
  Future<int> get handle {
    if (_handleFuture == null) {
      throw StateError('Collider must be attached to a GameObject before accessing handle.');
    }
    return _handleFuture!;
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

    _handleFuture = rb.handle.then((bodyHandle) => worker.createCollider(shapeType, bodyHandle));
    _handleFuture!.then((h) => PhysicsSystem.registerCollider(h, this));
    syncProperties();
  }

  @override
  void internalDetach() {
    _handleFuture?.then((h) {
      PhysicsSystem.unregisterCollider(h);
      worker.destroyCollider(h);
    });
    _handleFuture = null;
    super.internalDetach();
  }

  /// Synchronizes properties with the physics worker.
  @protected
  void syncProperties() {
    _handleFuture?.then((h) {
      worker.setColliderProperty(h, ColliderProp.offset, _offset);
      worker.setColliderProperty(h, ColliderProp.isTrigger, _isTrigger);
      worker.setColliderProperty(h, ColliderProp.density, _density);
      worker.setColliderProperty(h, ColliderProp.friction, _friction);
      worker.setColliderProperty(h, ColliderProp.bounciness, _bounciness);
      worker.setColliderProperty(h, ColliderProp.frictionCombine, _frictionCombine.index);
      worker.setColliderProperty(h, ColliderProp.bounceCombine, _bounceCombine.index);
      worker.setColliderProperty(h, ColliderProp.compositeOperation, _compositeOperation.index);
      worker.setColliderProperty(h, ColliderProp.compositeOrder, _compositeOrder);
      worker.setColliderProperty(h, ColliderProp.usedByEffector, _usedByEffector);
      worker.setColliderProperty(h, ColliderProp.excludeLayers, _excludeLayers);
      worker.setColliderProperty(h, ColliderProp.includeLayers, _includeLayers);
      worker.setColliderProperty(h, ColliderProp.callbackLayers, _callbackLayers);
      worker.setColliderProperty(h, ColliderProp.contactCaptureLayers, _contactCaptureLayers);
      worker.setColliderProperty(h, ColliderProp.forceReceiveLayers, _forceReceiveLayers);
      worker.setColliderProperty(h, ColliderProp.forceSendLayers, _forceSendLayers);
      worker.setColliderProperty(h, ColliderProp.layerOverridePriority, _layerOverridePriority);
    });
  }

  // --- Configuration Properties (Sync) ---

  Vector2 _offset = Vector2.zero();
  /// The local offset of the collider geometry.
  Vector2 get offset => _offset;
  set offset(Vector2 value) {
    _offset.setFrom(value);
    _handleFuture?.then((h) => worker.setColliderProperty(h, ColliderProp.offset, value));
  }

  bool _isTrigger = false;
  /// Is this collider configured as a trigger?
  bool get isTrigger => _isTrigger;
  set isTrigger(bool value) {
    _isTrigger = value;
    _handleFuture?.then((h) => worker.setColliderProperty(h, ColliderProp.isTrigger, value));
  }

  double _density = 1.0;
  /// The density of the collider used to calculate its mass (when auto mass is enabled).
  double get density => _density;
  set density(double value) {
    _density = value;
    _handleFuture?.then((h) => worker.setColliderProperty(h, ColliderProp.density, value));
  }

  double _friction = 0.4;
  /// The friction used by the Collider2D.
  double get friction => _friction;
  set friction(double value) {
    _friction = value;
    _handleFuture?.then((h) => worker.setColliderProperty(h, ColliderProp.friction, value));
  }

  double _bounciness = 0.0;
  /// The bounciness used by the Collider2D.
  double get bounciness => _bounciness;
  set bounciness(double value) {
    _bounciness = value;
    _handleFuture?.then((h) => worker.setColliderProperty(h, ColliderProp.bounciness, value));
  }

  PhysicsMaterialCombine _frictionCombine = PhysicsMaterialCombine.average;
  /// The friction combine mode used by the Collider2D.
  PhysicsMaterialCombine get frictionCombine => _frictionCombine;
  set frictionCombine(PhysicsMaterialCombine value) {
    _frictionCombine = value;
    _handleFuture?.then((h) => worker.setColliderProperty(h, ColliderProp.frictionCombine, value.index));
  }

  PhysicsMaterialCombine _bounceCombine = PhysicsMaterialCombine.average;
  /// The bounciness combine mode used by the Collider2D.
  PhysicsMaterialCombine get bounceCombine => _bounceCombine;
  set bounceCombine(PhysicsMaterialCombine value) {
    _bounceCombine = value;
    _handleFuture?.then((h) => worker.setColliderProperty(h, ColliderProp.bounceCombine, value.index));
  }

  CompositeOperation _compositeOperation = CompositeOperation.none;
  /// The composite operation to be used by a CompositeCollider2D.
  CompositeOperation get compositeOperation => _compositeOperation;
  set compositeOperation(CompositeOperation value) {
    _compositeOperation = value;
    _handleFuture?.then((h) => worker.setColliderProperty(h, ColliderProp.compositeOperation, value.index));
  }

  int _compositeOrder = 0;
  /// The composite operation order to be used when a CompositeCollider2D is used.
  int get compositeOrder => _compositeOrder;
  set compositeOrder(int value) {
    _compositeOrder = value;
    _handleFuture?.then((h) => worker.setColliderProperty(h, ColliderProp.compositeOrder, value));
  }

  bool _usedByEffector = false;
  /// Whether the collider is used by an attached effector or not.
  bool get usedByEffector => _usedByEffector;
  set usedByEffector(bool value) {
    _usedByEffector = value;
    _handleFuture?.then((h) => worker.setColliderProperty(h, ColliderProp.usedByEffector, value));
  }

  int _excludeLayers = 0;
  /// The additional Layers that this Collider2D should exclude when deciding if a contact with another Collider2D should happen or not.
  int get excludeLayers => _excludeLayers;
  set excludeLayers(int value) {
    _excludeLayers = value;
    _handleFuture?.then((h) => worker.setColliderProperty(h, ColliderProp.excludeLayers, value));
  }

  int _includeLayers = 0;
  /// The additional Layers that this Collider2D should include when deciding if a contact with another Collider2D should happen or not.
  int get includeLayers => _includeLayers;
  set includeLayers(int value) {
    _includeLayers = value;
    _handleFuture?.then((h) => worker.setColliderProperty(h, ColliderProp.includeLayers, value));
  }

  int _callbackLayers = ~0;
  /// The Layers that this Collider2D will report collision or trigger callbacks for during a contact with another Collider2D.
  int get callbackLayers => _callbackLayers;
  set callbackLayers(int value) {
    _callbackLayers = value;
    _handleFuture?.then((h) => worker.setColliderProperty(h, ColliderProp.callbackLayers, value));
  }

  int _contactCaptureLayers = ~0;
  /// The layers of other Collider2D involved in contacts with this Collider2D that will be captured.
  int get contactCaptureLayers => _contactCaptureLayers;
  set contactCaptureLayers(int value) {
    _contactCaptureLayers = value;
    _handleFuture?.then((h) => worker.setColliderProperty(h, ColliderProp.contactCaptureLayers, value));
  }

  int _forceReceiveLayers = ~0;
  /// The Layers that this Collider2D can receive forces from during a Collision contact with another Collider2D.
  int get forceReceiveLayers => _forceReceiveLayers;
  set forceReceiveLayers(int value) {
    _forceReceiveLayers = value;
    _handleFuture?.then((h) => worker.setColliderProperty(h, ColliderProp.forceReceiveLayers, value));
  }

  int _forceSendLayers = ~0;
  /// The Layers that this Collider2D is allowed to send forces to during a Collision contact with another Collider2D.
  int get forceSendLayers => _forceSendLayers;
  set forceSendLayers(int value) {
    _forceSendLayers = value;
    _handleFuture?.then((h) => worker.setColliderProperty(h, ColliderProp.forceSendLayers, value));
  }

  int _layerOverridePriority = 0;
  /// A decision priority assigned to this Collider2D used when there is a conflicting decision on whether a contact between itself and another Collision2D should happen or not.
  int get layerOverridePriority => _layerOverridePriority;
  set layerOverridePriority(int value) {
    _layerOverridePriority = value;
    _handleFuture?.then((h) => worker.setColliderProperty(h, ColliderProp.layerOverridePriority, value));
  }

  // --- Read-Only / Computed Properties ---

  /// The error state that indicates the state of the physics shapes the 2D Collider tried to create. (Read Only)
  Future<ColliderErrorState> get errorState async => (await worker.getColliderProperty(await handle, ColliderProp.errorState)) as ColliderErrorState;

  /// The number of active PhysicsShape2D the Collider2D is currently using.
  Future<int> get shapeCount async => (await worker.getColliderProperty(await handle, ColliderProp.shapeCount)) as int;

  /// Indicates if this Collider2D is capable of being composited by the CompositeCollider2D.
  Future<bool> get compositeCapable async => (await worker.getColliderProperty(await handle, ColliderProp.compositeCapable)) as bool;

  /// The world space bounding area of the collider.
  ui.Rect get bounds {
    final t = gameObject.getComponent<ObjectTransform>();
    return ui.Rect.fromLTWH(t.position.dx, t.position.dy, 1, 1); // TODO: Compute from AABB
  }

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
  Future<Vector2> closestPoint(Vector2 position) async => worker.colliderClosestPoint(await handle, position);

  /// Calculates the minimum separation of this collider against another collider.
  Future<double> distance(Collider collider) async => worker.colliderDistance(await handle, await collider.handle);

  /// Check whether this collider is touching the collider or not.
  Future<bool> isTouching(Collider collider) async => worker.colliderIsTouching(await handle, await collider.handle);

  /// Checks whether this collider is touching any colliders on the specified layerMask or not.
  Future<bool> isTouchingLayers(int layerMask) async => worker.colliderIsTouchingLayers(await handle, layerMask);

  /// Check if a collider overlaps a point in space.
  Future<bool> overlapPoint(Vector2 point) async => (await worker.overlapPoint(point, 1 << gameObject.layer, 0, 0)).contains(await handle);

  /// Synchronous point-in-shape test in the object's local coordinate space.
  ///
  /// Used by the render hit-test system. The [position] is already transformed
  /// into local game-unit space by [GameRenderObject.hitTest] before this is
  /// called. Each Collider subclass overrides this with its own geometry test.
  bool containsPoint(ui.Offset position) => false;

  /// The PhysicsMaterial2D that is shared by this Collider2D.
  PhysicsMaterial? get sharedMaterial => null;
  set sharedMaterial(PhysicsMaterial? value) {}

  /// Casts the Collider shape into the Scene starting at the Collider position.
  Future<List<RaycastHit>> cast(Vector2 direction, [double distance = double.infinity, bool ignoreSiblingColliders = true]) async {
    final transform = gameObject.getComponent<ObjectTransform>();
    return Physics.boxCastAll(Vector2(transform.position.dx, transform.position.dy), Vector2(1, 1), transform.angle, direction, distance, ~0, -double.infinity, double.infinity);
  }

  /// Creates a mesh for the Collider2D.
  Object? createMesh(bool useDelaunayMesh, double extrusionAmount) => null;

  /// Retrieves all colliders in contact with this Collider2D.
  Future<List<Collider>> getContactColliders() async {
    final handles = await worker.getContactColliders(await handle);
    return handles.map((h) => PhysicsSystem.getCollider(h)).whereType<Collider>().toList();
  }

  /// Returns the current physics shapes used by the Collider2D.
  List<PhysicsShape> getShapes() => [];

  /// Returns a hash of the current physics shapes used by the Collider2D.
  int getShapeHash() => 0;

  /// Retrieves all contact points for all the contacts currently involving this Collider2D.
  Future<List<ContactPoint>> getContacts() async {
    final data = await worker.getContacts(await handle);
    return data.map((d) => ContactPoint.fromData(d)).whereType<ContactPoint>().toList();
  }

  /// Returns the world-space bounding area for a specific shape in the Collider2D.
  ui.Rect getShapeBounds(int shapeIndex) => bounds;

  /// Casts a ray into the Scene that starts at the Collider2D position and ignores the Collider2D itself.
  Future<List<RaycastHit>> raycast(Vector2 direction, [double distance = double.infinity, int layerMask = ~0, double minDepth = -double.infinity, double maxDepth = double.infinity]) async {
    final pos = gameObject.getComponent<ObjectTransform>().position;
    return Physics.raycastAll(Vector2(pos.dx, pos.dy), direction, distance, layerMask, minDepth, maxDepth);
  }

  /// Get a list of all Colliders that overlap this Collider2D.
  Future<List<Collider>> overlap() async {
    final handles = await worker.overlapCollider(await handle);
    return handles.map((h) => PhysicsSystem.getCollider(h)).whereType<Collider>().toList();
  }
}
