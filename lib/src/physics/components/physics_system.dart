import 'package:flutter/foundation.dart';
import 'package:goo2d/src/game.dart';
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
  }

  /// Steps the physics simulation by [dt] seconds.
  void step(double dt) => _worker?.step(dt);

  @override
  void dispose() {
    _worker?.dispose();
    _worker = null;
    _game = null;
  }
}
