import 'package:meta/meta.dart';
import 'package:goo2d/src/physics/worker/physics_worker.dart';
import 'package:goo2d/src/physics/worker/direct/direct_body_ops.dart';
import 'package:goo2d/goo2d.dart';

/// Provides physics movement and other dynamics, and the ability to attach Collider2D to it.
///
/// Equivalent to Unity's `Rigidbody2D`.
class Rigidbody extends Component {
  late int _handle;

  /// The internal physics handle for this rigidbody.
  int get handle {
    assert(isAttached, 'Rigidbody must be attached to a GameObject before accessing handle.');
    return _handle;
  }

  @protected
  PhysicsWorker get worker => game.getSystem<PhysicsSystem>()!.worker;

  @override
  void internalAttach(GameObject gameObject) {
    super.internalAttach(gameObject);
    _handle = worker.createBody();
    _syncAllProperties();
    PhysicsSystem.registerRigidbody(_handle, this);
  }

  @override
  void internalDetach() {
    PhysicsSystem.unregisterRigidbody(_handle, this);
    worker.destroyBody(_handle);
    super.internalDetach();
  }

  void _syncAllProperties() {
    final transform = gameObject.tryGetComponent<ObjectTransform>();
    if (transform != null) {
      worker.setBodyProperty(_handle, BodyProp.position, transform.position.clone());
      worker.setBodyProperty(_handle, BodyProp.rotation, transform.angle);
    }
    worker.setBodyProperty(_handle, BodyProp.bodyType, _bodyType.index);
    worker.setBodyProperty(_handle, BodyProp.interpolation, _interpolation.index);
    worker.setBodyProperty(_handle, BodyProp.linearDamping, _linearDamping);
    worker.setBodyProperty(_handle, BodyProp.angularDamping, _angularDamping);
    worker.setBodyProperty(_handle, BodyProp.gravityScale, _gravityScale);
    worker.setBodyProperty(_handle, BodyProp.mass, _mass);
    worker.setBodyProperty(_handle, BodyProp.inertia, _inertia);
    worker.setBodyProperty(_handle, BodyProp.freezeRotation, _freezeRotation);
    worker.setBodyProperty(_handle, BodyProp.simulated, _simulated);
    worker.setBodyProperty(_handle, BodyProp.useAutoMass, _useAutoMass);
    worker.setBodyProperty(_handle, BodyProp.useFullKinematicContacts, _useFullKinematicContacts);
    worker.setBodyProperty(_handle, BodyProp.constraints, _constraints);
    worker.setBodyProperty(_handle, BodyProp.collisionDetectionMode, _collisionDetectionMode.index);
    worker.setBodyProperty(_handle, BodyProp.sleepMode, _sleepMode.index);
    worker.setBodyProperty(_handle, BodyProp.excludeLayers, _excludeLayers);
    worker.setBodyProperty(_handle, BodyProp.includeLayers, _includeLayers);
    worker.setBodyProperty(_handle, BodyProp.centerOfMass, _centerOfMass.clone());
  }

  // --- Configuration Properties ---

  RigidbodyType _bodyType = RigidbodyType.dynamic;
  RigidbodyType get bodyType => _bodyType;
  set bodyType(RigidbodyType value) {
    _bodyType = value;
    if (isAttached) worker.setBodyProperty(_handle, BodyProp.bodyType, value.index);
  }

  RigidbodyInterpolation _interpolation = RigidbodyInterpolation.none;
  RigidbodyInterpolation get interpolation => _interpolation;
  set interpolation(RigidbodyInterpolation value) {
    _interpolation = value;
    if (isAttached) worker.setBodyProperty(_handle, BodyProp.interpolation, value.index);
  }

  double _linearDamping = 0;
  double get linearDamping => _linearDamping;
  set linearDamping(double value) {
    _linearDamping = value;
    if (isAttached) worker.setBodyProperty(_handle, BodyProp.linearDamping, value);
  }

  double _angularDamping = 0.05;
  double get angularDamping => _angularDamping;
  set angularDamping(double value) {
    _angularDamping = value;
    if (isAttached) worker.setBodyProperty(_handle, BodyProp.angularDamping, value);
  }

  double _gravityScale = 1.0;
  double get gravityScale => _gravityScale;
  set gravityScale(double value) {
    _gravityScale = value;
    if (isAttached) worker.setBodyProperty(_handle, BodyProp.gravityScale, value);
  }

  double _mass = 1.0;
  double get mass => _mass;
  set mass(double value) {
    _mass = value;
    if (isAttached) worker.setBodyProperty(_handle, BodyProp.mass, value);
  }

  double _inertia = 0;
  double get inertia => _inertia;
  set inertia(double value) {
    _inertia = value;
    if (isAttached) worker.setBodyProperty(_handle, BodyProp.inertia, value);
  }

  bool _freezeRotation = false;
  bool get freezeRotation => _freezeRotation;
  set freezeRotation(bool value) {
    _freezeRotation = value;
    if (isAttached) worker.setBodyProperty(_handle, BodyProp.freezeRotation, value);
  }

  bool _simulated = true;
  bool get simulated => _simulated;
  set simulated(bool value) {
    _simulated = value;
    if (isAttached) worker.setBodyProperty(_handle, BodyProp.simulated, value);
  }

  bool _useAutoMass = false;
  bool get useAutoMass => _useAutoMass;
  set useAutoMass(bool value) {
    _useAutoMass = value;
    if (isAttached) worker.setBodyProperty(_handle, BodyProp.useAutoMass, value);
  }

  bool _useFullKinematicContacts = false;
  bool get useFullKinematicContacts => _useFullKinematicContacts;
  set useFullKinematicContacts(bool value) {
    _useFullKinematicContacts = value;
    if (isAttached) worker.setBodyProperty(_handle, BodyProp.useFullKinematicContacts, value);
  }

  int _constraints = 0;
  int get constraints => _constraints;
  set constraints(int value) {
    _constraints = value;
    if (isAttached) worker.setBodyProperty(_handle, BodyProp.constraints, value);
  }

  CollisionDetectionMode _collisionDetectionMode = CollisionDetectionMode.discrete;
  CollisionDetectionMode get collisionDetectionMode => _collisionDetectionMode;
  set collisionDetectionMode(CollisionDetectionMode value) {
    _collisionDetectionMode = value;
    if (isAttached) worker.setBodyProperty(_handle, BodyProp.collisionDetectionMode, value.index);
  }

  RigidbodySleepMode _sleepMode = RigidbodySleepMode.startAwake;
  RigidbodySleepMode get sleepMode => _sleepMode;
  set sleepMode(RigidbodySleepMode value) {
    _sleepMode = value;
    if (isAttached) worker.setBodyProperty(_handle, BodyProp.sleepMode, value.index);
  }

  int _excludeLayers = 0;
  int get excludeLayers => _excludeLayers;
  set excludeLayers(int value) {
    _excludeLayers = value;
    if (isAttached) worker.setBodyProperty(_handle, BodyProp.excludeLayers, value);
  }

  int _includeLayers = 0;
  int get includeLayers => _includeLayers;
  set includeLayers(int value) {
    _includeLayers = value;
    if (isAttached) worker.setBodyProperty(_handle, BodyProp.includeLayers, value);
  }

  Vector2 _centerOfMass = Vector2.zero();
  Vector2 get centerOfMass => _centerOfMass;
  set centerOfMass(Vector2 value) {
    _centerOfMass.setFrom(value);
    if (isAttached) worker.setBodyProperty(_handle, BodyProp.centerOfMass, value.clone());
  }

  // --- Simulated State Properties (Async reads, sync writes) ---

  Future<Vector2> get linearVelocity async => (await worker.getBodyProperty(_handle, BodyProp.linearVelocity)) as Vector2;
  set linearVelocity(Vector2 value) {
    if (isAttached) worker.setBodyProperty(_handle, BodyProp.linearVelocity, value);
  }

  Future<double> get angularVelocity async => (await worker.getBodyProperty(_handle, BodyProp.angularVelocity)) as double;
  set angularVelocity(double value) {
    if (isAttached) worker.setBodyProperty(_handle, BodyProp.angularVelocity, value);
  }

  Future<Vector2> get position async => (await worker.getBodyProperty(_handle, BodyProp.position)) as Vector2;
  set position(Vector2 value) {
    if (isAttached) worker.setBodyProperty(_handle, BodyProp.position, value);
  }

  Future<double> get rotation async => (await worker.getBodyProperty(_handle, BodyProp.rotation)) as double;
  set rotation(double value) {
    if (isAttached) worker.setBodyProperty(_handle, BodyProp.rotation, value);
  }

  Future<Vector2> get totalForce async => (await worker.getBodyProperty(_handle, BodyProp.totalForce)) as Vector2;
  Future<double> get totalTorque async => (await worker.getBodyProperty(_handle, BodyProp.totalTorque)) as double;
  Future<Vector2> get worldCenterOfMass async => (await worker.getBodyProperty(_handle, BodyProp.worldCenterOfMass)) as Vector2;
  Future<double> get linearVelocityX async => (await linearVelocity).x;
  Future<double> get linearVelocityY async => (await linearVelocity).y;

  // --- Local/Computed Properties ---

  int get attachedColliderCount => gameObject.getComponents<Collider>().length;
  Matrix4 get worldMatrix => gameObject.getComponent<ObjectTransform>().worldMatrix;
  Matrix4 get localToWorldMatrix => worldMatrix;

  PhysicsMaterial? _sharedMaterial;
  PhysicsMaterial? get sharedMaterial => _sharedMaterial;
  set sharedMaterial(PhysicsMaterial? value) {
    _sharedMaterial = value;
    if (value == null || !isAttached) return;
    for (final c in gameObject.getComponents<Collider>()) {
      c.sharedMaterial = value;
    }
  }

  // --- Methods ---

  Future<List<RaycastHit>> cast(Vector2 direction, double distance, [int layerMask = Physics.defaultRaycastLayers]) async {
    final results = await worker.raycast(await position, direction, distance, layerMask, -double.infinity, double.infinity);
    return results.map((d) => RaycastHit.fromData(d)).whereType<RaycastHit>().toList();
  }

  Future<double> distance(Collider collider) async => worker.colliderDistance(_handle, collider.handle);

  List<Collider> getAttachedColliders() => gameObject.getComponents<Collider>().toList();

  int getShapes(PhysicsShapeGroup shapeGroup, [int shapeIndex = 0, int shapeCount = 0]) {
    var total = 0;
    for (final c in gameObject.getComponents<Collider>()) {
      total += c.getShapes(shapeGroup);
    }
    return total;
  }

  Future<List<Collider>> overlap(int layerMask, double minDepth, double maxDepth) async {
    final handles = <int>{};
    for (final c in gameObject.getComponents<Collider>()) {
      handles.addAll(await worker.overlapCollider(c.handle));
    }
    return handles.map((h) => PhysicsSystem.getCollider(h)).whereType<Collider>().toList();
  }

  Future<bool> overlapPoint(Vector2 point) async => worker.colliderIsTouchingLayers(_handle, ~0);

  Future<void> slide(Vector2 displacement) async => movePosition(await position + displacement);

  Future<void> addForce(Vector2 force, ForceMode mode) async => worker.bodyAddForce(_handle, force, mode.index);
  Future<void> addForceAtPosition(Vector2 force, Vector2 position, ForceMode mode) async => worker.bodyAddForceAtPosition(_handle, force, position, mode.index);
  Future<void> addForceX(double force, ForceMode mode) => addForce(Vector2(force, 0), mode);
  Future<void> addForceY(double force, ForceMode mode) => addForce(Vector2(0, force), mode);
  Future<void> addTorque(double torque, ForceMode mode) async => worker.bodyAddTorque(_handle, torque, mode.index);
  Future<void> addRelativeForce(Vector2 relativeForce, ForceMode mode) async => worker.bodyAddRelativeForce(_handle, relativeForce, mode.index);
  Future<void> addRelativeForceX(double force, ForceMode mode) => addRelativeForce(Vector2(force, 0), mode);
  Future<void> addRelativeForceY(double force, ForceMode mode) => addRelativeForce(Vector2(0, force), mode);
  Future<void> movePosition(Vector2 position) async => worker.bodyMovePosition(_handle, position);
  Future<void> movePositionAndRotation(Vector2 position, double angle) async => worker.bodyMovePositionAndRotation(_handle, position, angle);
  Future<void> moveRotation(double angle) async => worker.bodyMoveRotation(_handle, angle);
  Future<void> setRotation(double angle) async => worker.bodySetRotation(_handle, angle);
  Future<void> wakeUp() async => worker.bodyWakeUp(_handle);
  Future<void> sleep() async => worker.bodySleep(_handle);
  Future<bool> isAwake() async => worker.bodyIsAwake(_handle);
  Future<bool> isSleeping() async => worker.bodyIsSleeping(_handle);
  Future<Vector2> getPoint(Vector2 point) async => worker.bodyGetPoint(_handle, point);
  Future<Vector2> getRelativePoint(Vector2 relativePoint) async => worker.bodyGetRelativePoint(_handle, relativePoint);
  Future<Vector2> getVector(Vector2 vector) async => worker.bodyGetVector(_handle, vector);
  Future<Vector2> getRelativeVector(Vector2 relativeVector) async => worker.bodyGetRelativeVector(_handle, relativeVector);
  Future<Vector2> getPointVelocity(Vector2 point) async => worker.bodyGetPointVelocity(_handle, point);
  Future<Vector2> getRelativePointVelocity(Vector2 relativePoint) async => worker.bodyGetRelativePointVelocity(_handle, relativePoint);
  Future<Vector2> closestPoint(Vector2 position) async => worker.bodyClosestPoint(_handle, position);
  Future<bool> isTouching(Collider collider) async => worker.colliderIsTouching(_handle, collider.handle);
  Future<bool> isTouchingLayers(int layerMask) async => worker.colliderIsTouchingLayers(_handle, layerMask);

  Future<List<ContactPoint>> getContacts() async {
    final data = await worker.getContacts(_handle);
    return data.map((d) => ContactPoint.fromData(d)).whereType<ContactPoint>().toList();
  }

  Future<List<Collider>> getContactColliders() async {
    final handles = await worker.getContactColliders(_handle);
    return handles.map((h) => PhysicsSystem.getCollider(h)).whereType<Collider>().toList();
  }
}
