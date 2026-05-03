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

/// An interface for modular systems that extend the functionality of the [GameEngine].
///
/// Systems are used to encapsulate specific game engine features (like physics,
/// audio, or input) and provide a centralized place for their state and logic.
/// They are initialized once per game instance and can be retrieved from the
/// engine using [GameEngine.getSystem].
///
/// ```dart
/// class MySystem implements GameSystem {
///   @override
///   late final GameEngine game;
///   @override
///   bool get gameAttached => true;
///   @override
///   void attach(GameEngine game) => this.game = game;
///   @override
///   void dispose() {}
/// }
/// ```
///
/// See also:
/// * [GameEngine], which manages and provides access to these systems.
abstract interface class GameSystem {
  /// The [GameEngine] this system is currently attached to.
  ///
  /// This property is set during initialization and provides the system
  /// with access to other engine modules and game state.
  GameEngine get game;

  /// Whether the system is currently attached to a [GameEngine].
  ///
  /// This should return true after [attach] has been called and before
  /// [dispose] is completed.
  bool get gameAttached;

  /// Attaches the system to a [GameEngine].
  ///
  /// This is called during engine initialization. Use it to cache references
  /// to other systems or initialize resources that require engine access.
  ///
  /// * [game]: The engine instance to attach to.
  void attach(GameEngine game);

  /// Disposes of the system and its resources.
  ///
  /// This is called when the [GameEngine] is shut down. Use it to clean up
  /// listeners, stop timers, and free memory.
  void dispose();
}

typedef GameSystemFactory<T extends GameSystem> = T Function();

/// Extensions for [GameSystemFactory] to support declarative unregistration.
///
/// These operators enable a powerful syntax for removing default engine
/// systems during initialization by using the unary minus or tilde operators
/// on their factory functions.
///
/// ```dart
/// final engine = GameEngine(
///   systems: {
///     ...GameEngine.defaultSystems,
///     -InputSystem.new, // Declaratively unregister the default input system
///   },
/// );
/// ```
extension GameSystemFactoryExtension<T extends GameSystem>
    on GameSystemFactory<T> {
  /// Unregisters a system of type [T] from the engine's default systems.
  ///
  /// This operator allows for a concise syntax when customizing the
  /// engine's system list.
  GameSystemFactory<T> operator -() => _nullFactory<T>;

  /// Alias for the unary minus operator.
  ///
  /// Provides an alternative syntax for unregistering systems, which can be
  /// useful depending on personal preference or code style.
  GameSystemFactory<T> operator ~() => _nullFactory<T>;
}

T _nullFactory<T extends GameSystem>() => throw _Unregister<T>();

class _Unregister<T extends GameSystem> {
  bool isInstance(GameSystem s) => s is T;
}

/// The central coordinator for all Goo2D engine systems and state.
///
/// The [GameEngine] manages the lifecycle of various [GameSystem]s and
/// provides a centralized access point for core features like input,
/// physics, and time management. It uses a modular architecture where
/// features are registered as systems, allowing for a flexible and
/// extensible engine core.
///
/// ```dart
/// class MySystem implements GameSystem {
///   @override
///   late final GameEngine game;
///   @override
///   bool get gameAttached => true;
///   @override
///   void attach(GameEngine game) => this.game = game;
///   @override
///   void dispose() {}
/// }
///
/// void main() {
///   final engine = GameEngine({
///     ...GameEngine.defaultSystems,
///     -InputSystem.new, // Remove default input system
///     MySystem.new,     // Add custom system
///   });
/// }
/// ```
///
/// See also:
/// * [GameSystem], the base interface for engine modules.
/// * [GameProvider], for accessing the engine through the widget tree.
class GameEngine {
  /// The collection of systems included by default in a new engine instance.
  ///
  /// This set includes essential engine components like time management,
  /// input handling, physics, and rendering support.
  static const defaultSystems = {
    TickerState.new,
    InputSystem.new,
    PhysicsSystem.new,
    CameraSystem.new,
    ScreenSystem.new,
    ScreenPhysicsSystem.new,
    AudioSystem.new,
  };

  /// Retrieves the [GameEngine] instance from the nearest [GameProvider].
  ///
  /// * [context]: The build context used to locate the provider.
  static GameEngine of(BuildContext context) {
    return GameProvider.of(context);
  }

  final List<GameSystem> _systems = [];
  final Map<Type, GameSystem?> _cachedSystems = {};

  final Set<GameSystemFactory> _systemFactories;

  /// Creates a new engine instance with the specified [systems].
  ///
  /// * [systems]: The set of system factories to initialize. Defaults to [defaultSystems].
  GameEngine([
    Set<GameSystemFactory> systems = defaultSystems,
  ]) : _systemFactories = systems;

  /// Retrieves a registered system of type [T].
  ///
  /// This method returns null if the system is not registered. It caches
  /// the result of the lookup for subsequent calls.
  ///
  /// * [T]: The type of system to retrieve.
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

  /// Returns whether a system of type [T] is currently registered.
  ///
  /// * [T]: The type of system to check for.
  bool hasSystem<T extends GameSystem>() => getSystem<T>() != null;

  /// Disposes of all registered systems and clears caches.
  ///
  /// This is called when the engine is no longer needed, ensuring that all
  /// system resources (like timers or audio handles) are properly freed.
  void dispose() {
    for (var system in _systems) {
      system.dispose();
    }
    _systems.clear();
    _cachedSystems.clear();
  }

  /// Initializes all registered systems by invoking their factories.
  ///
  /// This method must be called before the engine is used. It handles
  /// system registration, attachment, and de-registration logic.
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

  /// The system responsible for managing time, frame counts, and the game loop.
  ///
  /// It provides high-precision delta times and coordinates the various
  /// update stages (Tick, FixedTick, LateTick) across the object hierarchy.
  TickerState get ticker {
    final tickerSystem = getSystem<TickerState>();
    assert(tickerSystem != null, 'TickerState not registered');
    return tickerSystem!;
  }

  /// The system responsible for processing and dispatching user input.
  ///
  /// It centralizes the state of keys, pointers, and gamepads, ensuring
  /// that input events are synchronized with the game's update loop.
  InputSystem get input {
    final inputSystem = getSystem<InputSystem>();
    assert(inputSystem != null, 'InputSystem not registered');
    return inputSystem!;
  }

  /// The system responsible for simulating physical interactions.
  ///
  /// If registered, it manages collision detection and rigid body
  /// simulations using the underlying physics engine.
  PhysicsSystem? get physics => getSystem<PhysicsSystem>();

  /// The system responsible for managing and sorting game cameras.
  ///
  /// It allows for multi-camera setups, recursive rendering passes, and
  /// depth-based sorting of viewport configurations.
  CameraSystem get cameras {
    final camerasSystem = getSystem<CameraSystem>();
    assert(camerasSystem != null, 'CameraSystem not registered');
    return camerasSystem!;
  }

  /// The system responsible for providing screen metrics and boundaries.
  ///
  /// Use this to respond to window resizing or to calculate coordinates
  /// relative to the game's display area.
  ScreenSystem get screen {
    final screenSystem = getSystem<ScreenSystem>();
    assert(screenSystem != null, 'ScreenSystem not registered');
    return screenSystem!;
  }

  /// The system responsible for high-performance screen boundary physics.
  ///
  /// It provides specialized collision logic for keeping objects within
  /// the visible game area without the overhead of full rigid body physics.
  ScreenPhysicsSystem? get screenPhysics => getSystem<ScreenPhysicsSystem>();

  /// The system responsible for playing and managing game audio.
  ///
  /// It provides a high-level API for sound effects, music, and spatial
  /// audio using the SoLoud backend.
  AudioSystem? get audio => getSystem<AudioSystem>();
}

/// The system responsible for managing time, frame counts, and the game loop.
///
/// [TickerState] tracks the delta time between frames, maintains a fixed
/// update frequency for physics, and provides a stream of frame completion
/// signals. It is the heartbeat of the Goo2D engine.
///
/// ```dart
/// final ticker = TickerState();
/// print('Time: ${ticker.time}');
/// await ticker.nextFrame;
/// ```
///
/// See also:
/// * [GameLoop], the widget that drives this ticker.
/// * [YieldInstruction], for time-based synchronization in coroutines.
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

  /// The collection of root game objects managed by this ticker.
  ///
  /// Root objects are those without a parent in the game object hierarchy.
  /// They serve as the entry points for broadcasting update events.
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

  /// The time elapsed since the last frame, in seconds.
  ///
  /// Use this to scale movement or other time-dependent logic to be
  /// independent of the frame rate.
  double deltaTime = 0.0;

  /// The constant time step used for fixed physics updates, in seconds.
  ///
  /// This ensures that physics simulations remain stable and deterministic
  /// regardless of fluctuations in the rendering frame rate.
  double fixedDeltaTime = 0.02;

  /// The total time elapsed since the engine started, in seconds.
  ///
  /// This value increments continuously on every frame and can be used for
  /// periodic effects or absolute time measurements.
  double time = 0.0;

  /// The total number of frames rendered since the engine started.
  ///
  /// This count increases by exactly one on every render pass.
  int frameCount = 0;

  final _frameController = StreamController<void>.broadcast();

  /// A future that completes when the next frame is finished processing.
  ///
  /// This is used for frame-based synchronization and custom yield
  /// instructions in coroutines.
  Future<void> get nextFrame {
    if (_frameController.isClosed) return Future.value();
    return _frameController.stream.first.catchError((e) {
      if (e is StateError) return null;
      throw e;
    });
  }

  /// Updates the internal time state.
  ///
  /// * [dt]: The delta time to add.
  void update(double dt) {
    deltaTime = dt;
    time += dt;
    frameCount++;
  }

  double _accumulator = 0.0;

  /// Executes a single engine tick, processing input, physics, and logic.
  ///
  /// This method is called by the [GameLoop] on every frame. It handles
  /// fixed-step accumulation, event broadcasting, and system updates.
  ///
  /// * [dt]: The time elapsed since the last tick.
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

  /// Signals that the current frame has finished processing.
  ///
  /// This notifies any listeners waiting on [nextFrame].
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

/// The system responsible for managing and sorting game cameras.
///
/// [CameraSystem] maintains a list of all active cameras, identifies the
/// main camera for the primary render pass, and handles depth-based sorting
/// to ensure correct rendering order.
///
/// ```dart
/// final camera = Camera();
/// // Use a registered engine instance
/// GameEngine().cameras.registerCamera(camera);
/// ```
///
/// See also:
/// * [Camera], the component used to define viewports.
/// * [GameRenderer], which uses this system for the paint phase.
class CameraSystem implements GameSystem {
  @override
  late final GameEngine game;

  @override
  bool get gameAttached => _attached;
  bool _attached = false;

  /// Whether the current render pass is a secondary (recursive) pass.
  ///
  /// This is used to distinguish between the main viewport rendering and
  /// specialized passes (like shadows or reflections).
  bool isSecondaryPass = false;

  /// The camera currently being used for rendering.
  ///
  /// This property is set dynamically by the [GameRenderer] during the
  /// paint phase.
  Camera? currentRenderCamera;

  Camera? _main;
  final List<Camera> _allCameras = [];

  @override
  void attach(GameEngine game) {
    this.game = game;
    _attached = true;
  }

  /// The primary camera used for rendering the main scene.
  ///
  /// This is typically the camera with the highest depth. It is required
  /// for calculating the initial view matrix.
  Camera get main {
    if (_main == null) {
      throw StateError(
        'Main camera is not ready for this game instance. Make sure you have a GameWidget with GameTag(\'MainCamera\')',
      );
    }
    return _main!;
  }

  /// Whether at least one camera is registered and ready for rendering.
  ///
  /// Check this property before attempting to perform operations that
  /// require a valid camera configuration.
  bool get isReady => _main != null;

  /// The collection of all cameras currently registered with the system.
  ///
  /// This list is automatically sorted by depth whenever a camera's depth
  /// property is changed or a new camera is registered.
  List<Camera> get allCameras => List.unmodifiable(_allCameras);

  /// Registers a [camera] with the system.
  ///
  /// This adds the camera to the internal tracking list and triggers a
  /// resort of the camera hierarchy.
  ///
  /// * [camera]: The camera to register.
  void registerCamera(Camera camera) {
    if (!_allCameras.contains(camera)) {
      _allCameras.add(camera);
      _updateMainCamera();
    }
  }

  /// Unregisters a [camera] from the system.
  ///
  /// This removes the camera from the tracking list and updates the main
  /// camera reference if necessary.
  ///
  /// * [camera]: The camera to unregister.
  void unregisterCamera(Camera camera) {
    _allCameras.remove(camera);
    if (_main == camera) {
      _main = null;
      _updateMainCamera();
    }
  }

  /// Notifies the system that a camera's depth has changed, requiring a resort.
  ///
  /// This ensures that the rendering order remains consistent with the
  /// specified depth values.
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

/// The system responsible for playing and managing game audio.
///
/// [AudioSystem] wraps the SoLoud engine, providing a unified interface
/// for sound playback, volume management, and resource cleanup. It tracks
/// active sound handles to ensure they are stopped when the system is
/// disposed.
///
/// ```dart
/// await AudioSystem.initialize();
/// // Access via engine instance
/// GameEngine().audio?.globalVolume = 0.5;
/// ```
///
/// See also:
/// * [AudioSource], for loading and playing sounds.
/// * [SoundHandle], for managing active playback instances.
class AudioSystem implements GameSystem {
  static bool _isInitialized = false;

  /// Initializes the underlying audio engine.
  ///
  /// This must be called once before any audio playback can occur. It
  /// configures the sample rate, buffer size, and output device.
  ///
  /// * [device]: The output device to use.
  /// * [automaticCleanup]: Whether to automatically stop sounds when finished.
  /// * [sampleRate]: The playback sample rate.
  /// * [bufferSize]: The audio buffer size.
  /// * [channels]: The number of audio channels.
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

  /// Registers an active sound [handle] for tracking.
  ///
  /// This ensures that the sound is properly managed and can be stopped
  /// when the system is disposed.
  ///
  /// * [handle]: The handle to track.
  void registerHandle(SoundHandle handle) {
    _handles.add(handle);
  }

  /// Unregisters a sound [handle] from tracking.
  ///
  /// This is typically called when a sound has finished playing and no
  /// longer needs to be managed by the system.
  ///
  /// * [handle]: The handle to stop tracking.
  void unregisterHandle(SoundHandle handle) {
    _handles.remove(handle);
  }

  double _globalVolume = 1.0;

  /// The master volume level for all audio playback.
  ///
  /// This value is clamped between 0.0 (silent) and 1.0 (full volume) and
  /// affects all voices managed by the underlying SoLoud engine.
  double get globalVolume => _globalVolume;

  /// Sets the global volume level.
  ///
  /// * [value]: The new volume level (0.0 to 1.0).
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

/// An [InheritedWidget] that provides a [GameEngine] to the widget tree.
///
/// This is used internally by the [Game] widget and can be used by developers
/// to access the engine instance from any descendant widget using
/// `GameEngine.of(context)`.
///
/// ```dart
/// class MyWidget extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     final engine = GameEngine.of(context);
///     return Text('Frame: ${engine.ticker.frameCount}');
///   }
/// }
/// ```
///
/// See also:
/// * [Game], the root widget that initializes the engine.
/// * [GameEngine], the central coordinator provided by this widget.
class GameProvider extends InheritedWidget {
  /// The [GameEngine] instance being provided.
  ///
  /// All child widgets can access this instance to interact with systems
  /// like input, audio, or physics.
  final GameEngine game;

  /// Creates a provider for the specified [game] engine.
  ///
  /// * [key]: The widget key.
  /// * [game]: The engine instance to provide.
  /// * [child]: The descendant widget tree.
  const GameProvider({super.key, required this.game, required super.child});

  /// Retrieves the [GameEngine] from the nearest [GameProvider] ancestor.
  ///
  /// * [context]: The build context used to locate the provider.
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

/// The root widget of a Goo2D application.
///
/// The [Game] widget initializes the [GameEngine], sets up the core systems,
/// and establishes the rendering and update loops. It should typically be
/// placed at the root of the game's widget tree.
///
/// ```dart
/// void main() {
///   runApp(const Game(
///     child: Placeholder(),
///   ));
/// }
/// ```
///
/// See also:
/// * [GameProvider], for accessing the engine instance.
/// * [GameEngine], for manual engine configuration.
class Game extends StatefulWidget {
  /// The root child widget of the game.
  ///
  /// This widget tree will be wrapped in the engine's rendering and
  /// update pipelines.
  final Widget child;

  /// An optional [GameEngine] instance to use.
  ///
  /// If not provided, a new engine instance with default systems will be
  /// created automatically. This allows for custom engine configurations.
  final GameEngine? game;

  /// Creates a root game widget.
  ///
  /// * [key]: The widget key.
  /// * [game]: An optional custom engine instance.
  /// * [child]: The root game world widget.
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
