import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:meta/meta.dart';
import 'package:goo2d/src/input.dart';
import 'package:goo2d/src/physics/physics_system.dart';
import 'package:goo2d/src/camera.dart';
import 'package:goo2d/src/screen.dart';
import 'package:goo2d/src/ticker.dart';

import 'package:goo2d/src/world.dart';
import 'package:goo2d/src/object.dart';

/// Defines the contract for modular systems attached to the [GameEngine].
/// 
/// A [GameSystem] is a lifecycle-managed object that handles a specific 
/// domain of game logic (e.g., Physics, Audio, Input). Systems are 
/// initialized once when the engine starts and are disposed of when 
/// the engine is destroyed.
/// 
/// Custom systems can be implemented by following this interface, allowing 
/// for modular extension of the engine's capabilities.
/// 
/// ```dart
/// class MyCustomSystem implements GameSystem {
///   @override
///   late final GameEngine game;
/// 
///   @override
///   bool get gameAttached => _attached;
///   bool _attached = false;
/// 
///   @override
///   void attach(GameEngine game) {
///     this.game = game;
///     _attached = true;
///   }
/// 
///   @override
///   void dispose() => _attached = false;
/// }
/// ```
abstract interface class GameSystem {
  /// The [GameEngine] instance this system is currently serving.
  /// 
  /// This property provides access to other systems and the scene 
  /// hierarchy. It is guaranteed to be available after [attach] is called.
  GameEngine get game;

  /// Whether the system has been successfully linked to a [GameEngine].
  /// 
  /// Systems should use this flag to guard against logic execution 
  /// if they require engine context that isn't yet available.
  bool get gameAttached;

  /// Internal method used by the engine to initialize the system.
  /// 
  /// This is called during the engine's initialization phase. Subclasses 
  /// should use this to set up listeners or cache references to other systems.
  /// 
  /// * [game]: The engine instance being initialized.
  void attach(GameEngine game);

  /// Performs cleanup when the system or engine is being destroyed.
  /// 
  /// Use this to close streams, stop timers, or release hardware 
  /// resources (like SoLoud audio handles) to prevent memory leaks.
  void dispose();
}

/// The central orchestrator that manages all game systems and objects.
/// 
/// [GameEngine] acts as the single point of truth for a running game 
/// instance. It holds references to all core [GameSystem]s and 
/// maintains the root of the [GameObject] hierarchy.
/// 
/// The engine is responsible for the overall lifecycle, including 
/// initialization and disposal, ensuring that all sub-systems are 
/// synchronized and updated in the correct order.
/// 
/// ```dart
/// final engine = GameEngine();
/// engine.initialize();
/// // Perform game logic
/// engine.dispose();
/// ```
class GameEngine {
  /// Locates the [GameEngine] provided by the nearest [GameProvider].
  /// 
  /// This is the standard way to access the engine from within a 
  /// Flutter widget's build method or lifecycle hooks.
  /// 
  /// * [context]: The build context to search from.
  static GameEngine of(BuildContext context) {
    return GameProvider.of(context);
  }

  final TickerState _ticker;
  final InputSystem _input;
  final PhysicsSystem _physics;
  final CameraSystem _cameras;
  final ScreenSystem _screen;
  final AudioSystem _audio;

  final List<GameObject> _rootObjects = [];

  /// The [Camera] currently being used to render the scene.
  /// 
  /// This is only non-null during the [GameRenderer]'s paint pass. 
  /// Components that need to perform manual projection or 
  /// culling should reference this camera.
  @internal
  Camera? currentRenderCamera;

  /// Internal constructor for fine-grained engine control.
  /// 
  /// Used for testing or for manual engine assembly when the default 
  /// factory is insufficient.
  /// 
  /// * [ticker]: The time management system.
  /// * [input]: The user input system.
  /// * [physics]: The collision and physics system.
  /// * [cameras]: The camera registry.
  /// * [screen]: The viewport and resolution system.
  /// * [audio]: The sound engine.
  @internal
  GameEngine.internal({
    required TickerState ticker,
    required InputSystem input,
    required PhysicsSystem physics,
    required CameraSystem cameras,
    required ScreenSystem screen,
    required AudioSystem audio,
  }) : _ticker = ticker,
       _input = input,
       _physics = physics,
       _cameras = cameras,
       _screen = screen,
       _audio = audio;

  /// Creates a new [GameEngine] with a standard set of systems.
  /// 
  /// This initializes the default physics, input, audio, and camera 
  /// systems required for a typical Goo2D game.
  /// 
  /// Returns a fully configured but uninitialized [GameEngine].
  factory GameEngine() => GameEngine.internal(
    ticker: TickerState(),
    input: InputSystem(),
    physics: PhysicsSystem(),
    cameras: CameraSystem(),
    screen: ScreenSystem(),
    audio: AudioSystem(),
  );

  /// The time management and game loop system.
  /// 
  /// Use this to access frame counts, delta time, or to schedule 
  /// logic for the next frame.
  TickerState get ticker => _ticker;

  /// The system responsible for processing user input events.
  /// 
  /// [input] manages physical key states, mouse position, and touch 
  /// gestures, translating them into high-level [InputAction] events.
  InputSystem get input => _input;

  /// The system responsible for managing 2D physics and collisions.
  /// 
  /// [physics] handles the simulation of physical bodies and detects 
  /// overlaps between [Collider] components across the scene.
  PhysicsSystem get physics => _physics;

  /// The registry and management system for all cameras in the scene.
  /// 
  /// [cameras] handles camera sorting, priority, and identifying the 
  /// main viewport for the rendering pipeline.
  CameraSystem get cameras => _cameras;

  /// The system for managing screen resolution and safe areas.
  /// 
  /// [screen] is used for UI scaling, aspect ratio management, and 
  /// identifying safe areas on mobile devices.
  ScreenSystem get screen => _screen;

  /// The audio engine interface for playback and sound management.
  /// 
  /// [audio] provides a high-level API for playing sounds and music, 
  /// built on top of the SoLoud engine.
  AudioSystem get audio => _audio;

  /// Returns a read-only list of all root-level [GameObject]s.
  /// 
  /// Root objects are those that do not have a parent and are 
  /// directly updated by the engine loop.
  List<GameObject> get rootObjects => List.unmodifiable(_rootObjects);

  /// Registers a [GameObject] to receive top-level engine events.
  /// 
  /// This is called internally by root containers. Objects added here 
  /// become entry points for the [broadcastEvent] tree traversal.
  /// 
  /// * [object]: The object to register.
  @internal
  void registerRootObject(GameObject object) {
    if (!_rootObjects.contains(object)) {
      _rootObjects.add(object);
    }
  }

  /// Removes a [GameObject] from the root event list.
  /// 
  /// * [object]: The object to unregister.
  @internal
  void unregisterRootObject(GameObject object) {
    _rootObjects.remove(object);
  }

  /// Whether the engine is currently performing a non-standard rendering pass.
  /// 
  /// This is used internally to skip certain logic (like physics updates) 
  /// if a frame is being re-rendered for a specialized effect.
  bool isSecondaryPass = false;

  /// Shuts down all systems and releases resources.
  /// 
  /// This is called when the [Game] widget is disposed. It ensures 
  /// that hardware resources like audio handles and physics isolates 
  /// are properly closed.
  void dispose() {
    _input.dispose();
    _ticker.dispose();
    _physics.dispose();
    _cameras.dispose();
    _screen.dispose();
    _audio.dispose();
  }

  /// Bootstraps all registered systems and links them to this engine.
  /// 
  /// This must be called before the first frame of the game loop.
  void initialize() {
    _ticker.attach(this);
    _input.attach(this);
    _physics.attach(this);
    _cameras.attach(this);
    _screen.attach(this);
    _audio.attach(this);
  }
}

/// The heartbeat of the engine, managing time and update cycles.
/// 
/// [TickerState] implements a robust game loop that separates 
/// fixed-step physics from variable-step logic. This prevents 
/// non-deterministic physics behavior caused by frame rate 
/// fluctuations.
/// 
/// The loop utilizes an internal accumulator to ensure that 
/// [FixedTickEvent]s occur at precisely [fixedDeltaTime] intervals.
/// 
/// ```dart
/// final ticker = game.ticker;
/// print(ticker.deltaTime);
/// ```
class TickerState implements GameSystem {
  /// The time elapsed during the current frame, in seconds.
  /// 
  /// Use this for smooth variable-rate logic like animations or 
  /// camera smoothing.
  double deltaTime = 0.0;

  /// The target interval for physics and fixed-rate logic (default 0.02s).
  /// 
  /// This value determines the frequency of [FixedTickEvent]s, providing 
  /// a stable time step for deterministic physics simulations.
  double fixedDeltaTime = 0.02;

  /// The total time the game has been running, in seconds.
  /// 
  /// This value is monotonic and continues to increment as long as 
  /// the ticker is active, regardless of frame rate fluctuations.
  double time = 0.0;

  /// The total number of frames rendered by the ticker.
  /// 
  /// This counter is incremented at the start of every [tick] call, 
  /// providing a unique frame identifier within the game's execution.
  int frameCount = 0;

  /// The current size of the viewport in logical pixels.
  /// 
  /// Updated every frame before the [TickEvent] broadcast.
  Size screenSize = Size.zero;

  final _frameController = StreamController<void>.broadcast();
  
  /// A future that completes once the engine finishes the current frame.
  /// 
  /// This is the primary mechanism for coroutine yielding (e.g., 
  /// `yield null`). It ensures code resumes at the start of the 
  /// next engine tick.
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

  /// Updates the internal time state using the provided delta [dt].
  /// 
  /// Accumulates the total running time and increments the frame counter.
  /// 
  /// * [dt]: The time since the last frame.
  void update(double dt) {
    deltaTime = dt;
    time += dt;
    frameCount++;
  }

  double _accumulator = 0.0;

  /// Executes a single engine tick, broadcasting events to the hierarchy.
  /// 
  /// This method orchestrates the phased update loop:
  /// 1. Input system update.
  /// 2. [FixedTickEvent] broadcast (potentially multiple times).
  /// 3. [TickEvent] broadcast (variable rate).
  /// 4. Physics and Screen system steps.
  /// 5. [LateTickEvent] broadcast.
  /// 
  /// * [dt]: The delta time provided by the Flutter ticker.
  void tick(double dt) {
    update(dt);
    game.input.update();

    _accumulator += dt;
    while (_accumulator >= fixedDeltaTime) {
      for (final obj in game._rootObjects) {
        obj.broadcastEvent(FixedTickEvent(fixedDeltaTime));
      }
      _accumulator -= fixedDeltaTime;
    }

    for (final obj in game._rootObjects) {
      obj.broadcastEvent(TickEvent(dt));
    }

    game.screen.update(screenSize);
    game.physics.step(dt);

    for (final obj in game._rootObjects) {
      obj.broadcastEvent(LateTickEvent(dt));
    }

    signalFrameComplete();
  }

  /// Resolves the [nextFrame] future for all waiting coroutines.
  /// 
  /// Wakes up any logic suspended on [nextFrame].
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

/// The system responsible for managing and sorting active [Camera]s.
/// 
/// [CameraSystem] allows multiple cameras to exist in a scene, and 
/// it automatically identifies the [main] camera based on the 
/// [Camera.depth] property. Cameras with higher depth values take 
/// precedence.
/// 
/// ```dart
/// final mainCam = game.cameras.main;
/// ```
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

  /// The camera with the highest depth, used for primary rendering.
  /// 
  /// This camera is automatically determined by sorting all active 
  /// cameras. If no cameras are found, accessing this property 
  /// will throw a [StateError].
  Camera get main {
    if (_main == null) {
      throw StateError(
        'Main camera is not ready for this game instance. Make sure you have a GameWidget with GameTag(\'MainCamera\')',
      );
    }
    return _main!;
  }

  /// Whether a main camera has been successfully identified.
  /// 
  /// Returns true if at least one camera is registered in the system.
  bool get isReady => _main != null;

  /// An unmodifiable list of all cameras currently registered in the scene.
  /// 
  /// Access this to iterate over all viewpoints or perform custom sorting.
  List<Camera> get allCameras => List.unmodifiable(_allCameras);

  /// Registers a camera and re-sorts the system by depth.
  /// 
  /// Ensures the camera is tracked by the engine's sorting logic.
  /// 
  /// * [camera]: The camera to add to the system.
  void registerCamera(Camera camera) {
    if (!_allCameras.contains(camera)) {
      _allCameras.add(camera);
      _updateMainCamera();
    }
  }

  /// Removes a camera and re-evaluates the main camera selection.
  /// 
  /// Detaches the camera from the sorting logic and re-checks for the main viewport.
  /// 
  /// * [camera]: The camera to remove.
  void unregisterCamera(Camera camera) {
    _allCameras.remove(camera);
    if (_main == camera) {
      _main = null;
      _updateMainCamera();
    }
  }

  /// Informs the system that a camera's depth has changed.
  /// 
  /// This triggers a re-sort of the camera list to ensure that the 
  /// camera with the highest depth is correctly identified as [main].
  void notifyDepthChanged() {
    _updateMainCamera();
  }

  /// Internal logic to perform the depth-based camera sort.
  /// 
  /// This method organizes the [allCameras] list and updates the [main] 
  /// reference to point to the camera with the highest depth.
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

/// A system that manages audio playback using the SoLoud engine.
/// 
/// [AudioSystem] handles the global lifecycle of the audio hardware 
/// and tracks sound handles associated with the current game 
/// instance. It ensures that sounds are stopped when the game 
/// is disposed, preventing orphaned background audio.
/// 
/// ```dart
/// final audio = game.audio;
/// ```
class AudioSystem implements GameSystem {
  static bool _isInitialized = false;
  
  /// Initializes the SoLoud audio engine hardware.
  /// 
  /// This is a static operation that should be performed once per 
  /// application lifecycle. Subsequent calls to [initialize] will 
  /// be ignored if the system is already ready.
  /// 
  /// * [device]: The hardware playback device.
  /// * [automaticCleanup]: Whether to dispose of sound sources when they finish.
  /// * [sampleRate]: The output frequency (default 44100).
  /// * [bufferSize]: The audio buffer length.
  /// * [channels]: Stereo vs Mono output configuration.
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

  /// Adds a sound handle to the management list.
  /// 
  /// Handles registered here will be stopped automatically during [dispose].
  /// 
  /// * [handle]: The SoLoud handle to track.
  void registerHandle(SoundHandle handle) {
    _handles.add(handle);
  }

  /// Removes a sound handle from management.
  /// 
  /// * [handle]: The handle to stop tracking.
  void unregisterHandle(SoundHandle handle) {
    _handles.remove(handle);
  }

  double _globalVolume = 1.0;

  /// The master volume for this specific game engine instance.
  /// 
  /// Clamped between 0.0 and 1.0. Updating this value immediately 
  /// adjusts the SoLoud global volume.
  double get globalVolume => _globalVolume;

  /// Sets the master volume for this specific game engine instance.
  /// 
  /// Clamped between 0.0 and 1.0. Updating this value immediately 
  /// adjusts the SoLoud global volume.
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

/// Provides the [GameEngine] to all descendant widgets.
/// 
/// This widget uses Flutter's [InheritedWidget] mechanism to 
/// make the engine accessible anywhere in the tree via 
/// `GameEngine.of(context)`.
/// 
/// ```dart
/// final engine = GameProvider.of(context);
/// ```
class GameProvider extends InheritedWidget {
  /// The engine instance provided to the underlying widget tree.
  /// 
  /// Descendant widgets use this reference to interact with game 
  /// systems via [GameEngine.of].
  final GameEngine game;

  /// Creates a [GameProvider].
  /// 
  /// * [key]: Standard Flutter widget key.
  /// * [game]: The engine instance to provide to descendants.
  /// * [child]: The widget tree that can access the game engine.
  const GameProvider({super.key, required this.game, required super.child});

  /// Locates the [GameEngine] from the nearest provider.
  /// 
  /// Returns the engine instance associated with the nearest [GameProvider] 
  /// ancestor. Throws a [StateError] if no provider is found.
  /// 
  /// * [context]: The build context to search from.
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

/// The top-level widget that encapsulates a Goo2D game.
/// 
/// [Game] manages the entire Flutter-to-Goo2D bridge. It handles 
/// the initialization of systems, the game loop ticker, and 
/// the root world rendering. 
/// 
/// By wrapping your scene in a [Game] widget, you ensure that 
/// all components have access to the engine and are properly 
/// disposed of when the widget is removed from the tree.
/// 
/// ```dart
/// Game(
///   child: MyScene(),
/// )
/// ```
class Game extends StatefulWidget {
  /// The content to render inside the game world.
  /// 
  /// This widget tree will be projected into the 2D world space.
  final Widget child;
  
  /// Optional engine instance. If omitted, a default [GameEngine] is created.
  /// 
  /// Provide a custom engine if you need to pre-configure systems.
  final GameEngine? game;

  /// Creates a [Game] widget.
  /// 
  /// * [key]: Standard Flutter widget key.
  /// * [child]: The content to render.
  /// * [game]: Optional pre-configured engine.
  const Game({super.key, this.game, required this.child});

  @override
  State<Game> createState() => _GameState();
}

/// Internal state for the [Game] widget.
/// 
/// This class manages the lifecycle of the [GameEngine] and ensures 
/// that systems are correctly initialized and disposed of when the 
/// widget tree changes.
/// 
/// ```dart
/// // Internal state management for the Game widget.
/// ```
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
