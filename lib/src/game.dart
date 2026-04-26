import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'input.dart';
import 'collision.dart';
import 'camera.dart';
import 'screen.dart';
import 'ticker.dart';

import 'world.dart';

abstract interface class GameSystem {
  GameEngine get game;
  bool get gameAttached;
  void attach(GameEngine game);
  void dispose();
}

class GameEngine {
  static GameEngine of(BuildContext context) {
    return GameProvider.of(context);
  }

  final TickerState _ticker;
  final InputSystem _input;
  final CollisionSystem _collision;
  final CameraSystem _cameras;
  final ScreenSystem _screen;
  final AudioSystem _audio;

  GameEngine._create({
    required TickerState ticker,
    required InputSystem input,
    required CollisionSystem collision,
    required CameraSystem cameras,
    required ScreenSystem screen,
    required AudioSystem audio,
  }) : _ticker = ticker,
       _input = input,
       _collision = collision,
       _cameras = cameras,
       _screen = screen,
       _audio = audio;

  factory GameEngine() => GameEngine._create(
    ticker: TickerState(),
    input: InputSystem(),
    collision: CollisionSystem(),
    cameras: CameraSystem(),
    screen: ScreenSystem(),
    audio: AudioSystem(),
  );

  TickerState get ticker => _ticker;
  InputSystem get input => _input;
  CollisionSystem get collision => _collision;
  CameraSystem get cameras => _cameras;
  ScreenSystem get screen => _screen;
  AudioSystem get audio => _audio;

  bool isSecondaryPass = false;

  void dispose() {
    _input.dispose();
    _ticker.dispose();
    _collision.dispose();
    _cameras.dispose();
    _screen.dispose();
    _audio.dispose();
  }

  void initialize() {
    _ticker.attach(this);
    _input.attach(this);
    _collision.attach(this);
    _cameras.attach(this);
    _screen.attach(this);
    _audio.attach(this);
  }
}

class TickerState implements GameSystem {
  double deltaTime = 0.0;
  double fixedDeltaTime = 0.02;
  double time = 0.0;
  int frameCount = 0;
  Size screenSize = Size.zero;

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
    time += dt;
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
    if (_main == null) {
      throw StateError(
        'Main camera is not ready for this game instance. Make sure you have a GameWidget with GameTag(\'MainCamera\')',
      );
    }
    return _main!;
  }

  bool get isReady => _main != null;

  List<Camera> get allCameras => List.unmodifiable(_allCameras);

  void registerCamera(Camera camera) {
    if (!_allCameras.contains(camera)) {
      _allCameras.add(camera);
      _updateMainCamera();
    }
  }

  void unregisterCamera(Camera camera) {
    _allCameras.remove(camera);
    if (_main == camera) {
      _main = null;
      _updateMainCamera();
    }
  }

  void notifyDepthChanged() {
    _updateMainCamera();
  }

  void _updateMainCamera() {
    if (_allCameras.isEmpty) {
      _main = null;
      return;
    }
    // Sort by depth descending, so the highest depth is at index 0.
    _allCameras.sort((a, b) => b.depth.compareTo(a.depth));
    _main = _allCameras.first;
    // print('DEBUG: CameraSystem._updateMainCamera: _main set to $_main (depth: ${_main?.depth})');
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

class AudioSystem implements GameSystem {
  static Future<void> initialize({
    PlaybackDevice? device,
    bool automaticCleanup = false,
    int sampleRate = 44100,
    int bufferSize = 2048,
    Channels channels = Channels.stereo,
  }) async {
    await SoLoud.instance.init(
      device: device,
      automaticCleanup: automaticCleanup,
      sampleRate: sampleRate,
      bufferSize: bufferSize,
      channels: channels,
    );
  }

  final Set<SoundHandle> _handles = {};

  GameEngine? _game;
  @override
  GameEngine get game {
    assert(_game != null, 'AudioSystem is not attached to a GameEngine');
    return _game!;
  }

  @override
  bool get gameAttached => _game != null;

  @override
  void attach(GameEngine game) {
    _game = game;
  }

  /// Registers a sound handle to be managed by this game instance.
  void registerHandle(SoundHandle handle) {
    _handles.add(handle);
  }

  /// Unregisters a sound handle.
  void unregisterHandle(SoundHandle handle) {
    _handles.remove(handle);
  }

  @override
  void dispose() {
    if (SoLoud.instance.isInitialized) {
      for (final handle in _handles) {
        if (SoLoud.instance.getIsValidVoiceHandle(handle)) {
          SoLoud.instance.stop(handle);
        }
      }
    }
    _handles.clear();
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
      child: RepaintBoundary(
        child: GameTicker(child: World(child: widget.child)),
      ),
    );
  }
}
