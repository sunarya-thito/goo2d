import 'package:flutter/foundation.dart';
import 'package:goo2d/goo2d.dart';
import 'package:goo2d/src/physics/worker/physics_worker.dart';
import 'package:goo2d/src/physics/worker/data/contact_point_data.dart';
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
    _worker?.step(_game!.getSystem<TickerState>()!.fixedDeltaTime);
    await _dispatchCollisionEvents();
  }

  @override
  void dispose() {
    _worker?.dispose();
    _worker = null;
    _game = null;
    _colliderRegistry.clear();
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

  // ── Collision event dispatch ─────────────────────────────────────────────

  // handle → { otherHandle → otherCollider } from the previous step
  final Map<int, Map<int, Collider>> _prevContacts = {};
  final Map<int, Map<int, Collider>> _prevTriggers = {};

  Collision _buildCollision(
    Collider self,
    Collider other,
    List<ContactPointData> allContacts,
    int otherHandle,
  ) {
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
    for (final entry in _colliderRegistry.entries) {
      final handle = entry.key;
      final collider = entry.value;
      final otherHandles = await _worker!.getContactColliders(handle);
      for (final otherHandle in otherHandles) {
        final other = _colliderRegistry[otherHandle];
        if (other == null) continue;
        if (collider.isTrigger || other.isTrigger) {
          currentTriggers.putIfAbsent(handle, () => {})[otherHandle] = other;
        } else {
          currentContacts.putIfAbsent(handle, () => {})[otherHandle] = other;
        }
      }
    }

    // Dispatch events by comparing current vs previous
    for (final entry in _colliderRegistry.entries) {
      final handle = entry.key;
      final collider = entry.value;

      // --- solid collisions ---
      final prevC = _prevContacts[handle] ?? const {};
      final currC = currentContacts[handle] ?? const {};

      if (currC.isNotEmpty) {
        final contactData = await _worker!.getContacts(handle);
        for (final otherEntry in currC.entries) {
          final collision =
              _buildCollision(collider, otherEntry.value, contactData, otherEntry.key);
          if (prevC.containsKey(otherEntry.key)) {
            await CollisionStayEvent(collision).dispatchTo(collider.gameObject);
          } else {
            await CollisionEnterEvent(collision).dispatchTo(collider.gameObject);
          }
        }
      }

      for (final otherEntry in prevC.entries) {
        if (!currC.containsKey(otherEntry.key)) {
          final collision =
              _buildCollision(collider, otherEntry.value, const [], otherEntry.key);
          await CollisionExitEvent(collision).dispatchTo(collider.gameObject);
        }
      }

      // --- triggers ---
      final prevT = _prevTriggers[handle] ?? const {};
      final currT = currentTriggers[handle] ?? const {};

      for (final otherEntry in currT.entries) {
        if (prevT.containsKey(otherEntry.key)) {
          await TriggerStayEvent(otherEntry.value).dispatchTo(collider.gameObject);
        } else {
          await TriggerEnterEvent(otherEntry.value).dispatchTo(collider.gameObject);
        }
      }

      for (final otherEntry in prevT.entries) {
        if (!currT.containsKey(otherEntry.key)) {
          await TriggerExitEvent(otherEntry.value).dispatchTo(collider.gameObject);
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
