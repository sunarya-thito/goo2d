import 'package:flutter/foundation.dart';
import 'package:goo2d/goo2d.dart';
import 'package:goo2d/src/physics/worker/physics_worker.dart';
import 'package:goo2d/src/physics/worker/direct/direct_physics_worker.dart';
import 'package:goo2d/src/physics/worker/isolate/isolate_physics_worker.dart';

/// The [GameSystem] that manages the physics worker lifecycle.
///
/// Automatically selects [IsolatePhysicsWorker] on native platforms
/// and [DirectPhysicsWorker] on web, unless [forceDirectWorker] is set.
class PhysicsSystem implements GameSystem {
  final bool forceDirectWorker;

  PhysicsWorker? _worker;
  GameEngine? _game;

  PhysicsSystem({this.forceDirectWorker = false});

  /// The active physics worker.
  PhysicsWorker get worker {
    assert(_worker != null, 'PhysicsSystem has not been initialized.');
    return _worker!;
  }

  /// Whether the current platform supports isolates.
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

  /// Steps the physics simulation by [fixedDeltaTime] seconds.
  Future<void> step() async {
    _worker?.step(_game!.getSystem<TickerState>()!.fixedDeltaTime);
  }

  @override
  void dispose() {
    _worker?.dispose();
    _worker = null;
    _game = null;
    _colliderRegistry.clear();
  }

  static final Map<int, Collider> _colliderRegistry = {};

  /// Registers a collider with its handle for reverse lookup.
  static void registerCollider(int handle, Collider collider) => _colliderRegistry[handle] = collider;

  /// Unregisters a collider.
  static void unregisterCollider(int handle) => _colliderRegistry.remove(handle);

  /// Gets a collider by its handle.
  static Collider? getCollider(int handle) => _colliderRegistry[handle];

  /// All currently registered colliders.
  Iterable<Collider> get activeColliders => _colliderRegistry.values;
}
