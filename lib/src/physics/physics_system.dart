import 'package:flutter/foundation.dart';
import 'package:goo2d/goo2d.dart';
import 'package:goo2d/src/physics/worker/physics_worker.dart';
import 'package:goo2d/src/physics/worker/data/contact_point_data.dart';
import 'package:goo2d/src/physics/worker/direct/direct_body_ops.dart';
import 'package:goo2d/src/physics/worker/direct/direct_physics_worker.dart';
import 'package:goo2d/src/physics/worker/isolate/isolate_physics_worker.dart';

/// The [GameSystem] that manages the physics worker lifecycle and dispatches
/// per-frame collision and trigger events to [CollisionListener] components.
class PhysicsSystem implements GameSystem {
  final bool forceDirectWorker;

  PhysicsWorker? _worker;
  GameEngine? _game;

  PhysicsSystem({this.forceDirectWorker = false});

  PhysicsWorker get worker {
    assert(_worker != null, 'PhysicsSystem has not been initialized.');
    return _worker!;
  }

  static bool get platformSupportsIsolate => !kIsWeb;

  @override
  GameEngine get game => _game!;

  @override
  bool get gameAttached => _game != null;

  @override
  void attach(GameEngine game) {
    _game = game;
    if (!forceDirectWorker && platformSupportsIsolate) {
      _worker = IsolatePhysicsWorker();
    } else {
      _worker = DirectPhysicsWorker();
    }
    _worker!.initialize();
    Physics.initialize(_worker!);
  }

  /// Steps the physics simulation then dispatches collision/trigger events.
  Future<void> step() async {
    await _syncTransformsToPhysics();
    await _worker!.step(_game!.getSystem<TickerState>()!.fixedDeltaTime);
    await _syncTransformsFromPhysics();
    await _dispatchCollisionEvents();
  }

  /// Pushes game-driven (kinematic) positions to the physics body before each step
  /// so the physics engine sees the correct positions for contact detection.
  Future<void> _syncTransformsToPhysics() async {
    if (_worker == null) return;
    final entries = _rigidbodyRegistry.entries.toList();
    for (final entry in entries) {
      final rb = entry.value;
      if (!rb.isAttached || rb.bodyType != RigidbodyType.kinematic) continue;
      final transform = rb.gameObject.tryGetComponent<ObjectTransform>();
      if (transform == null) continue;
      await _worker!.bodyMovePositionAndRotation(entry.key, transform.position, transform.angle);
    }
  }

  /// Pulls simulation results back to game transforms — only for dynamic bodies
  /// whose positions are owned by the physics engine, not the game.
  Future<void> _syncTransformsFromPhysics() async {
    if (_worker == null) return;
    final entries = _rigidbodyRegistry.entries.toList();
    for (final entry in entries) {
      final rb = entry.value;
      if (!rb.isAttached || rb.bodyType != RigidbodyType.dynamic) continue;
      final pos = (await _worker!.getBodyProperty(entry.key, BodyProp.position)) as Vector2;
      final rot = (await _worker!.getBodyProperty(entry.key, BodyProp.rotation)) as double;
      rb.gameObject.tryGetComponent<ObjectTransform>()
        ?..position = pos
        ..angle = rot;
    }
  }

  @override
  void dispose() {
    _worker?.dispose();
    _worker = null;
    _game = null;
    _colliderRegistry.clear();
    _rigidbodyRegistry.clear();
    _prevContacts.clear();
    _prevTriggers.clear();
  }

  // ── Collider registry ────────────────────────────────────────────────────

  static final Map<int, Collider> _colliderRegistry = {};

  static void registerCollider(int handle, Collider collider) =>
      _colliderRegistry[handle] = collider;

  static void unregisterCollider(int handle) =>
      _colliderRegistry.remove(handle);

  static Collider? getCollider(int handle) => _colliderRegistry[handle];

  Iterable<Collider> get activeColliders => _colliderRegistry.values;

  // ── Rigidbody registry ───────────────────────────────────────────────────

  static final Map<int, Rigidbody> _rigidbodyRegistry = {};

  static void registerRigidbody(int handle, Rigidbody rb) =>
      _rigidbodyRegistry[handle] = rb;

  static void unregisterRigidbody(int handle) =>
      _rigidbodyRegistry.remove(handle);

  static Rigidbody? getRigidbody(int handle) => _rigidbodyRegistry[handle];

  // ── Collision event dispatch ─────────────────────────────────────────────

  // handle → { otherHandle → otherCollider } from the previous step
  final Map<int, Map<int, Collider>> _prevContacts = {};
  final Map<int, Map<int, Collider>> _prevTriggers = {};

  Collision? _buildCollision(
    Collider self,
    Collider other,
    List<ContactPointData> allContacts,
    int otherHandle,
  ) {
    if (!self.isAttached || !other.isAttached) return null;
    final contacts = allContacts
        .where((d) =>
            d.colliderHandle == otherHandle ||
            d.otherColliderHandle == otherHandle)
        .map(ContactPoint.fromData)
        .whereType<ContactPoint>()
        .toList();
    return Collision()
      ..collider = self
      ..otherCollider = other
      ..gameObject = other.gameObject
      ..rigidbody = self.tryGetComponent<Rigidbody>()
      ..otherRigidbody = other.tryGetComponent<Rigidbody>()
      ..transform = other.tryGetComponent<ObjectTransform>()
      ..contacts = contacts
      ..contactCount = contacts.length;
  }

  Future<void> _dispatchCollisionEvents() async {
    if (_worker == null) return;

    final currentContacts = <int, Map<int, Collider>>{};
    final currentTriggers = <int, Map<int, Collider>>{};

    // Build current contact sets for this step
    final colliderEntries = _colliderRegistry.entries.toList();
    for (final entry in colliderEntries) {
      final handle = entry.key;
      final collider = entry.value;
      if (!collider.isAttached) continue;
      final otherHandles = await _worker!.getContactColliders(handle);
      for (final otherHandle in otherHandles) {
        final other = _colliderRegistry[otherHandle];
        if (other == null || !other.isAttached) continue;
        if (collider.isTrigger || other.isTrigger) {
          currentTriggers.putIfAbsent(handle, () => {})[otherHandle] = other;
        } else {
          currentContacts.putIfAbsent(handle, () => {})[otherHandle] = other;
        }
      }
    }

    // Dispatch events by comparing current vs previous
    for (final entry in colliderEntries) {
      final handle = entry.key;
      final collider = entry.value;
      if (!collider.isAttached) continue;

      // --- solid collisions ---
      final prevC = _prevContacts[handle] ?? const {};
      final currC = currentContacts[handle] ?? const {};

      if (currC.isNotEmpty) {
        final contactData = await _worker!.getContacts(handle);
        for (final otherEntry in currC.entries) {
          final other = otherEntry.value;
          if (!other.isAttached) continue;
          final collision = _buildCollision(collider, other, contactData, otherEntry.key);
          if (collision == null) continue;
          if (prevC.containsKey(otherEntry.key)) {
            await CollisionStayEvent(collision).dispatchTo(collider.gameObject);
          } else {
            await CollisionEnterEvent(collision).dispatchTo(collider.gameObject);
          }
        }
      }

      for (final otherEntry in prevC.entries) {
        if (!currC.containsKey(otherEntry.key)) {
          final other = otherEntry.value;
          if (!other.isAttached) continue;
          final collision = _buildCollision(collider, other, const [], otherEntry.key);
          if (collision == null) continue;
          await CollisionExitEvent(collision).dispatchTo(collider.gameObject);
        }
      }

      // --- triggers ---
      final prevT = _prevTriggers[handle] ?? const {};
      final currT = currentTriggers[handle] ?? const {};

      for (final otherEntry in currT.entries) {
        final other = otherEntry.value;
        if (!other.isAttached) continue;
        if (prevT.containsKey(otherEntry.key)) {
          await TriggerStayEvent(other).dispatchTo(collider.gameObject);
        } else {
          await TriggerEnterEvent(other).dispatchTo(collider.gameObject);
        }
      }

      for (final otherEntry in prevT.entries) {
        if (!currT.containsKey(otherEntry.key)) {
          final other = otherEntry.value;
          if (!other.isAttached) continue;
          await TriggerExitEvent(other).dispatchTo(collider.gameObject);
        }
      }
    }

    _prevContacts
      ..clear()
      ..addAll(currentContacts);
    _prevTriggers
      ..clear()
      ..addAll(currentTriggers);
  }
}
