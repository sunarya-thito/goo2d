import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:meta/meta.dart';
import 'package:goo2d/src/input.dart';
import 'package:goo2d/src/physics/components/physics_system.dart';
import 'package:goo2d/src/camera.dart';
import 'package:goo2d/src/screen.dart';
import 'package:goo2d/src/ticker.dart';

import 'package:goo2d/src/world.dart';
import 'package:goo2d/src/object.dart';

abstract interface class GameSystem {
  GameEngine get game;
  bool get gameAttached;
  void attach(GameEngine game);
  void dispose();
}

typedef GameSystemFactory<T extends GameSystem> = T Function();

extension GameSystemFactoryExtension<T extends GameSystem>
    on GameSystemFactory<T> {
  // as a way to exclude GameSystem,
  // ```dart
  // {
  //   ...GameEngine.defaultSystems,
  //   -InputSystem.new,
  //   -PhysicsSystem.new,
  // }
  GameSystemFactory<T> operator -() => _nullFactory<T>;
  GameSystemFactory<T> operator ~() => _nullFactory<T>;
}

T _nullFactory<T extends GameSystem>() => throw _Unregister<T>();

class _Unregister<T extends GameSystem> {
  bool isInstance(GameSystem s) => s is T;
}

class GameEngine {
  static const defaultSystems = {
    TickerState.new,
    InputSystem.new,
    PhysicsSystem.new,
    CameraSystem.new,
    ScreenSystem.new,
    ScreenPhysicsSystem.new,
    AudioSystem.new,
  };
  static GameEngine of(BuildContext context) {
    return GameProvider.of(context);
  }

  // final TickerState _ticker;
  // final InputSystem _input;
  // final PhysicsSystem _physics;
  // final CameraSystem _cameras;
  // final ScreenSystem _screen;
  // final AudioSystem _audio;

  final List<GameSystem> _systems = [];
  final Map<Type, GameSystem?> _cachedSystems = {};

  final Set<GameSystemFactory> _systemFactories;

  GameEngine([
    Set<GameSystemFactory> systems = defaultSystems,
  ]) : _systemFactories = systems;
  T? getSystem<T extends GameSystem>() {
    if (_cachedSystems.containsKey(T)) return _cachedSystems[T] as T?;
    for (var system in _systems) {
      if (system is T) {
        _cachedSystems[T] = system;
        return system;
      }
    }
    _cachedSystems[T] = null;
    return null;
  }

  bool hasSystem<T extends GameSystem>() => getSystem<T>() != null;
  void dispose() {
    for (var system in _systems) {
      system.dispose();
    }
    _systems.clear();
    _cachedSystems.clear();
  }

  void initialize() {
    for (var factory in _systemFactories) {
      try {
        final result = factory();
        _systems.add(result);
        result.attach(this);
      } catch (e) {
        if (e is _Unregister) {
          _systems.removeWhere((s) {
            if (e.isInstance(s)) {
              s.dispose();
              return true;
            }
            return false;
          });
          _cachedSystems.clear();
        } else {
          rethrow;
        }
      }
    }
  }

  TickerState get ticker {
    final tickerSystem = getSystem<TickerState>();
    assert(tickerSystem != null, 'TickerState not registered');
    return tickerSystem!;
  }

  InputSystem get input {
    final inputSystem = getSystem<InputSystem>();
    assert(inputSystem != null, 'InputSystem not registered');
    return inputSystem!;
  }

  PhysicsSystem? get physics => getSystem<PhysicsSystem>();
  CameraSystem get cameras {
    final camerasSystem = getSystem<CameraSystem>();
    assert(camerasSystem != null, 'CameraSystem not registered');
    return camerasSystem!;
  }

  ScreenSystem get screen {
    final screenSystem = getSystem<ScreenSystem>();
    assert(screenSystem != null, 'ScreenSystem not registered');
    return screenSystem!;
  }

  ScreenPhysicsSystem? get screenPhysics => getSystem<ScreenPhysicsSystem>();
  AudioSystem? get audio => getSystem<AudioSystem>();
}

class TickerState implements GameSystem {
  @override
  late final GameEngine game;

  @override
  bool get gameAttached => _attached;
  bool _attached = false;

  @override
  void attach(GameEngine game) {
    this.game = game;
    _attached = true;
  }

  final List<GameObject> _rootObjects = [];
  List<GameObject> get rootObjects => List.unmodifiable(_rootObjects);
  @internal
  void registerRootObject(GameObject object) {
    if (!_rootObjects.contains(object)) {
      _rootObjects.add(object);
    }
  }

  @internal
  void unregisterRootObject(GameObject object) {
    _rootObjects.remove(object);
  }

  double deltaTime = 0.0;
  double fixedDeltaTime = 0.02;
  double time = 0.0;
  int frameCount = 0;

  final _frameController = StreamController<void>.broadcast();
  Future<void> get nextFrame {
    if (_frameController.isClosed) return Future.value();
    return _frameController.stream.first.catchError((e) {
      if (e is StateError) return null;
      throw e;
    });
  }

  void update(double dt) {
    deltaTime = dt;
    time += dt;
    frameCount++;
  }

  double _accumulator = 0.0;
  void tick(double dt) {
    update(dt);
    game.getSystem<InputSystem>()?.update();

    _accumulator += dt;
    while (_accumulator >= fixedDeltaTime) {
      for (final obj in _rootObjects) {
        obj.broadcastEvent(FixedTickEvent(fixedDeltaTime));
      }
      _accumulator -= fixedDeltaTime;
    }

    for (final obj in _rootObjects) {
      obj.broadcastEvent(TickEvent(dt));
    }

    game.screenPhysics?.update();
    game.getSystem<PhysicsSystem>()?.step(dt);

    for (final obj in _rootObjects) {
      obj.broadcastEvent(LateTickEvent(dt));
    }

    signalFrameComplete();
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
  @override
  late final GameEngine game;

  @override
  bool get gameAttached => _attached;
  bool _attached = false;
  bool isSecondaryPass = false;
  Camera? currentRenderCamera;

  Camera? _main;
  final List<Camera> _allCameras = [];

  @override
  void attach(GameEngine game) {
    this.game = game;
    _attached = true;
  }

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
  }

  @override
  void dispose() {
    _allCameras.clear();
    _main = null;
  }
}

class AudioSystem implements GameSystem {
  static bool _isInitialized = false;
  static Future<void> initialize({
    PlaybackDevice? device,
    bool automaticCleanup = false,
    int sampleRate = 44100,
    int bufferSize = 2048,
    Channels channels = Channels.stereo,
  }) async {
    if (_isInitialized) return;
    await SoLoud.instance.init(
      device: device,
      automaticCleanup: automaticCleanup,
      sampleRate: sampleRate,
      bufferSize: bufferSize,
      channels: channels,
    );
    _isInitialized = true;
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

  void registerHandle(SoundHandle handle) {
    _handles.add(handle);
  }

  void unregisterHandle(SoundHandle handle) {
    _handles.remove(handle);
  }

  double _globalVolume = 1.0;
  double get globalVolume => _globalVolume;
  set globalVolume(double value) {
    _globalVolume = value.clamp(0.0, 1.0);
    if (_isInitialized) {
      SoLoud.instance.setGlobalVolume(_globalVolume);
    }
  }

  @override
  void dispose() {
    if (_isInitialized) {
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
  void reassemble() {
    super.reassemble();
    _game.ticker.signalFrameComplete(); // Wake up any listeners
  }

  @override
  Widget build(BuildContext context) {
    return GameProvider(
      game: _game,
      child: GameLoop(
        game: _game,
        child: GameRenderer(child: World(child: widget.child)),
      ),
    );
  }
}
