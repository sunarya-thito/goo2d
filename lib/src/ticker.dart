import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:goo2d/src/game.dart';
import 'package:goo2d/src/event.dart';
import 'package:goo2d/src/camera.dart';
import 'package:goo2d/src/screen.dart';

/// A mixin that allows a [Component] to receive per-frame update ticks.
/// 
/// [Tickable] is the most common interface for game logic. It is 
/// triggered once per frame by the [TickerState]. The [dt] parameter 
/// provides the time elapsed since the last frame, which should be 
/// used to ensure frame-rate independent movement.
mixin Tickable implements EventListener {
  /// Called every frame to update the component's state.
  /// 
  /// * [dt]: The time elapsed since the last frame in seconds.
  void onUpdate(double dt);
}

/// An event dispatched every frame to all [Tickable] components.
/// 
/// [TickEvent] carries the delta time for the current frame, allowing 
/// components to update their logic in a frame-rate independent manner.
/// 
/// ```dart
/// final event = TickEvent(0.016);
/// ```
class TickEvent extends Event<Tickable> {
  /// The delta time for the current frame.
  /// 
  /// This value represents the time elapsed since the previous update 
  /// signal, measured in seconds.
  final double dt;

  /// Creates a [TickEvent] with the given [dt].
  /// 
  /// This constructor initializes the event with the frame-specific 
  /// timing data.
  /// 
  /// * [dt]: The delta time for the current frame.
  const TickEvent(this.dt);

  @override
  void dispatch(Tickable listener) {
    listener.onUpdate(dt);
  }
}

/// A mixin for components that need updates at a fixed time interval.
/// 
/// [FixedTickable] is typically used for physics calculations or 
/// network synchronization where a stable, predictable time step 
/// is required regardless of the rendering frame rate.
mixin FixedTickable implements EventListener {
  /// Called at a fixed frequency (default 50Hz) by the [TickerState].
  /// 
  /// * [dt]: The fixed time step in seconds.
  void onFixedUpdate(double dt);
}

/// An event dispatched at a fixed interval to all [FixedTickable] components.
/// 
/// [FixedTickEvent] is used for physics and other calculations that 
/// require a stable time step.
/// 
/// ```dart
/// final event = FixedTickEvent(0.02);
/// ```
class FixedTickEvent extends Event<FixedTickable> {
  /// The fixed delta time.
  /// 
  /// This value is constant across all fixed update calls and represents 
  /// the simulation time step.
  final double dt;

  /// Creates a [FixedTickEvent] with the given [dt].
  /// 
  /// This constructor initializes the event with the fixed timing data.
  /// 
  /// * [dt]: The fixed delta time.
  const FixedTickEvent(this.dt);

  @override
  void dispatch(FixedTickable listener) {
    listener.onFixedUpdate(dt);
  }
}

/// A mixin for components that need to update after all other updates are finished.
/// 
/// [LateTickable] is useful for logic that depends on the final state 
/// of other objects in the frame, such as a camera following a player 
/// who has already moved in [Tickable.onUpdate].
mixin LateTickable implements EventListener {
  /// Called every frame after [Tickable.onUpdate] has completed.
  /// 
  /// * [dt]: The delta time in seconds.
  void onLateUpdate(double dt);
}

/// An event dispatched every frame after the main update pass.
/// 
/// [LateTickEvent] is used by the [LateTickable] mixin to provide a 
/// synchronization point after all standard [Tickable] updates have finished.
/// 
/// ```dart
/// final event = LateTickEvent(0.016);
/// ```
/// 
/// See also:
/// * [LateTickable] for the interface that receives this event.
class LateTickEvent extends Event<LateTickable> {
  /// The delta time for the current frame.
  /// 
  /// This value represents the time elapsed since the previous update 
  /// signal, measured in seconds.
  final double dt;

  /// Creates a [LateTickEvent] with the given [dt].
  /// 
  /// This constructor initializes the event data with the time elapsed 
  /// since the last frame.
  /// 
  /// * [dt]: The delta time for the current frame.
  const LateTickEvent(this.dt);

  @override
  void dispatch(LateTickable listener) {
    listener.onLateUpdate(dt);
  }
}

/// A widget that manages the game loop using a Flutter [Ticker].
/// 
/// [GameLoop] acts as the driver for the entire engine. It creates 
/// a [RenderGameLoop] that listens to Flutter's vsync signals and 
/// triggers the [TickerState.tick] method on the [GameEngine].
/// 
/// ```dart
/// GameLoop(
///   game: myEngine,
///   child: myContent,
/// )
/// ```
class GameLoop extends SingleChildRenderObjectWidget {
  /// The [GameEngine] instance that this loop drives.
  /// 
  /// [game] provides the central update logic and coordinates the 
  /// rendering pass.
  final GameEngine game;

  /// Creates a [GameLoop] for the given [game].
  /// 
  /// This constructor establishes the connection between the engine 
  /// logic and the Flutter scheduler.
  /// 
  /// * [key]: Standard Flutter widget key.
  /// * [game]: The engine instance to drive.
  /// * [child]: The child widget tree to render.
  const GameLoop({super.key, required this.game, required super.child});

  @override
  RenderGameLoop createRenderObject(BuildContext context) {
    return RenderGameLoop(game: game);
  }

  @override
  void updateRenderObject(BuildContext context, RenderGameLoop renderObject) {
    renderObject.game = game;
  }
}

/// A render object that manages the game loop timing and delta calculation.
/// 
/// [RenderGameLoop] uses a [Ticker] to receive callbacks from the 
/// Flutter scheduler. it calculates the precise time difference 
/// between frames and passes it to the [game] engine.
/// 
/// ```dart
/// final loop = RenderGameLoop(game: myEngine);
/// ```
class RenderGameLoop extends RenderProxyBox {
  /// The engine instance being driven by this loop.
  /// 
  /// [game] receives the per-frame update signals and coordinates 
  /// the lifecycle of all attached systems.
  GameEngine game;

  /// The internal ticker that drives the frame updates.
  /// 
  /// [_ticker] is created when the render object is attached to the 
  /// pipeline and disposed when detached.
  Ticker? _ticker;

  /// The elapsed time of the previous frame update.
  /// 
  /// [_lastTick] is used to calculate the delta time for the next 
  /// engine update cycle.
  Duration _lastTick = Duration.zero;
  bool _skipNextDelta = false;

  /// Creates a [RenderGameLoop] for the given [game].
  /// 
  /// This constructor initializes the timing bridge between Flutter 
  /// and the engine.
  /// 
  /// * [game]: The engine being driven.
  RenderGameLoop({required this.game});

  @override
  void reassemble() {
    super.reassemble();
    _skipNextDelta = true;
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _ticker = Ticker(_onTick);
    _ticker!.start();
  }

  @override
  void detach() {
    _ticker?.dispose();
    _ticker = null;
    super.detach();
  }

  void _onTick(Duration elapsed) {
    if (_skipNextDelta) {
      _lastTick = elapsed;
      _skipNextDelta = false;
      return;
    }

    final delta = elapsed - _lastTick;
    final dt = delta.inMicroseconds / 1000000.0;
    _lastTick = elapsed;

    game.getSystem<TickerState>()?.tick(dt);

    // After updating the game state, we need to ensure the renderer repaints.
    markNeedsPaint();
  }
}

/// A widget that provides the root rendering for the game.
/// 
/// [GameRenderer] manages the background clearing and screen size 
/// updates for the engine. it creates a [RenderGameRenderer] which 
/// performs the actual canvas operations.
/// 
/// ```dart
/// GameRenderer(
///   child: World(child: myGame),
/// )
/// ```
class GameRenderer extends SingleChildRenderObjectWidget {
  /// Creates a [GameRenderer] widget.
  /// 
  /// * [key]: Standard Flutter widget key.
  /// * [child]: The child widget tree to render.
  const GameRenderer({super.key, required super.child});

  @override
  RenderGameRenderer createRenderObject(BuildContext context) {
    return RenderGameRenderer(game: GameProvider.of(context));
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderGameRenderer renderObject,
  ) {
    renderObject.game = GameProvider.of(context);
  }
}

/// A render object that handles background clearing and engine screen metrics.
/// 
/// This is the top-most renderer in the Goo2D widget tree. It ensures 
/// that the [GameEngine] knows the current [size] of the viewport and 
/// handles the [Camera.backgroundColor] clearing pass before any 
/// game objects are drawn.
/// 
/// ```dart
/// final renderer = RenderGameRenderer(game: myEngine);
/// ```
class RenderGameRenderer extends RenderProxyBox {
  /// The [GameEngine] instance that drives the rendering process.
  /// 
  /// [game] provides access to the camera stack and the ticker state, 
  /// which are required to calculate the projection matrix and background color.
  GameEngine game;

  /// Creates a [RenderGameRenderer] for the given [game].
  /// 
  /// This constructor initializes the renderer that handles the root 
  /// canvas operations and background clearing.
  /// 
  /// * [game]: The engine instance.
  RenderGameRenderer({required this.game});

  @override
  void paint(PaintingContext context, Offset offset) {
    if (hasSize) {
      game.getSystem<ScreenSystem>()?.screenSize = size;
    }

    final screenSize = size;
    if (screenSize.width <= 0 || screenSize.height <= 0) {
      super.paint(context, offset);
      return;
    }

    final cameras = game.getSystem<CameraSystem>();
    if (cameras == null || !cameras.isReady) {
      super.paint(context, offset);
      return;
    }

    final camera = cameras.main;
    if (!camera.gameObject.active || !camera.enabled) {
      super.paint(context, offset);
      return;
    }
    if (!camera.gameObject.active || !camera.enabled) {
      super.paint(context, offset);
      return;
    }

    if (camera.clearFlags == CameraClearFlags.solidColor) {
      final paint = Paint()..color = camera.backgroundColor;
      context.canvas.drawRect(offset & screenSize, paint);
    }

    super.paint(context, offset);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // Default hit testing for children in screen space
    return super.hitTestChildren(result, position: position);
  }
}
