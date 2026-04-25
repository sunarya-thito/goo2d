import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:goo2d/goo2d.dart';

abstract interface class GameSystem {
  GameEngine get game;
  bool get gameAttached;
  void attach(GameEngine game);
  void dispose();
}

class GameEngine {
  final TickerState _ticker;
  final InputSystem _input;
  final CollisionSystem _collision;
  final CameraSystem _cameras;
  final ScreenSystem _screen;

  GameEngine._create({
    required TickerState ticker,
    required InputSystem input,
    required CollisionSystem collision,
    required CameraSystem cameras,
    required ScreenSystem screen,
  }) : _ticker = ticker,
       _input = input,
       _collision = collision,
       _cameras = cameras,
       _screen = screen;

  factory GameEngine() => GameEngine._create(
    ticker: TickerState(),
    input: InputSystem(),
    collision: CollisionSystem(),
    cameras: CameraSystem(),
    screen: ScreenSystem(),
  );

  TickerState get ticker => _ticker;
  InputSystem get input => _input;
  CollisionSystem get collision => _collision;
  CameraSystem get cameras => _cameras;
  ScreenSystem get screen => _screen;

  void dispose() {
    _input.dispose();
    _ticker.dispose();
    _collision.dispose();
    _cameras.dispose();
    _screen.dispose();
  }

  void initialize() {
    _ticker.attach(this);
    _input.attach(this);
    _collision.attach(this);
    _cameras.attach(this);
    _screen.attach(this);
  }
}

class TickerState implements GameSystem {
  double deltaTime = 0.0;
  double fixedDeltaTime = 0.02;
  int frameCount = 0;

  final _frameController = StreamController<void>.broadcast();
  Future<void> get nextFrame {
    if (_frameController.isClosed) return Future.value();
    return _frameController.stream.first.catchError((e) {
      if (e is StateError) return null;
      throw e;
    });
  }

  GameEngine? _game;
  @override
  GameEngine get game {
    assert(_game != null, 'TickerState is not attached to a GameEngine');
    return _game!;
  }

  @override
  bool get gameAttached => _game != null;

  @override
  void attach(GameEngine game) => _game = game;

  void update(double dt) {
    deltaTime = dt;
    frameCount++;
  }

  void signalFrameComplete() {
    if (!_frameController.isClosed) {
      _frameController.add(null);
    }
  }

  @override
  void dispose() {
    _frameController.close();
  }
}

class CameraSystem implements GameSystem {
  Camera? _main;
  final List<Camera> _allCameras = [];

  GameEngine? _game;
  @override
  GameEngine get game {
    assert(_game != null, 'CameraSystem is not attached to a GameEngine');
    return _game!;
  }

  @override
  bool get gameAttached => _game != null;

  @override
  void attach(GameEngine game) => _game = game;

  Camera get main {
    assert(_main != null, 'Main camera is not ready for this game instance');
    return _main!;
  }

  bool get isReady => _main != null;

  List<Camera> get allCameras => List.unmodifiable(_allCameras);

  void registerCamera(Camera camera) {
    _allCameras.add(camera);
    _allCameras.sort((a, b) => a.depth.compareTo(b.depth));
    _updateMainCamera();
  }

  void unregisterCamera(Camera camera) {
    _allCameras.remove(camera);
    if (_main == camera) {
      _main = null;
      _updateMainCamera();
    }
  }

  void _updateMainCamera() {
    for (final cam in _allCameras) {
      if (cam.gameObject.tag == 'MainCamera') {
        _main = cam;
        break;
      }
    }
  }

  @override
  void dispose() {
    _allCameras.clear();
    _main = null;
  }
}

class CollisionSystem implements GameSystem {
  final List<CollisionTrigger> _active = [];
  Iterable<CollisionTrigger> get activeColliders => _active;

  GameEngine? _game;
  @override
  GameEngine get game {
    assert(_game != null, 'CollisionSystem is not attached to a GameEngine');
    return _game!;
  }

  @override
  bool get gameAttached => _game != null;

  @override
  void attach(GameEngine game) => _game = game;

  void register(CollisionTrigger collider) {
    _active.add(collider);
  }

  void unregister(CollisionTrigger collider) {
    _active.remove(collider);
  }

  void runCollisionPass() {
    final n = _active.length;
    if (n < 2) return;

    // Insertion sort by worldBounds.left
    for (int i = 1; i < n; i++) {
      final key = _active[i];
      final keyLeft = key.worldBounds.left;
      int j = i - 1;
      while (j >= 0 && _active[j].worldBounds.left > keyLeft) {
        _active[j + 1] = _active[j];
        j--;
      }
      _active[j + 1] = key;
    }

    // Sweep-and-prune on X axis
    for (int i = 0; i < n; i++) {
      final a = _active[i];
      final aBounds = a.worldBounds;

      for (int j = i + 1; j < n; j++) {
        final b = _active[j];
        final bBounds = b.worldBounds;

        if (bBounds.left > aBounds.right) break;
        if ((a.layerMask & b.layerMask) == 0) continue;
        if (aBounds.bottom <= bBounds.top || bBounds.bottom <= aBounds.top) {
          continue;
        }
        if (!a.collidesWith(b)) continue;

        final intersection = aBounds.intersect(bBounds);
        if (!intersection.isEmpty) {
          a.gameObject.broadcastEvent(CollisionEvent(a, b, intersection));
          b.gameObject.broadcastEvent(CollisionEvent(b, a, intersection));
        }
      }
    }
  }

  @override
  void dispose() {
    _active.clear();
  }
}

class GameProvider extends InheritedWidget {
  final GameEngine game;

  const GameProvider({super.key, required this.game, required super.child});

  static GameEngine of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<GameProvider>();
    if (provider == null) {
      throw StateError('GameProvider not found in context');
    }
    return provider.game;
  }

  @override
  bool updateShouldNotify(GameProvider oldWidget) => game != oldWidget.game;
}

class Game extends StatefulWidget {
  final Widget child;
  final GameEngine? game;

  const Game({super.key, this.game, required this.child});

  @override
  State<Game> createState() => _GameState();
}

class _GameState extends State<Game> {
  late GameEngine _game;

  @override
  void initState() {
    super.initState();
    _game = widget.game ?? GameEngine();
    _game.initialize();
  }

  @override
  void didUpdateWidget(covariant Game oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.game != oldWidget.game) {
      _game.dispose();
      _game = widget.game ?? GameEngine();
      _game.initialize();
    }
  }

  @override
  void dispose() {
    _game.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GameProvider(
      game: _game,
      child: RepaintBoundary(child: GameTicker(child: widget.child)),
    );
  }
}
