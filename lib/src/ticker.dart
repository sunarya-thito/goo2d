
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:goo2d/goo2d.dart';

// Delta time and frame count are now managed by the Game instance.

mixin Tickable implements EventListener {
  void onUpdate(double dt);
}

class TickEvent extends Event<Tickable> {
  final double dt;

  const TickEvent(this.dt);

  @override
  void dispatch(Tickable listener) {
    listener.onUpdate(dt);
  }
}

mixin FixedTickable implements EventListener {
  void onFixedUpdate(double dt);
}

class FixedTickEvent extends Event<FixedTickable> {
  final double dt;

  const FixedTickEvent(this.dt);

  @override
  void dispatch(FixedTickable listener) {
    listener.onFixedUpdate(dt);
  }
}

mixin LateTickable implements EventListener {
  void onLateUpdate(double dt);
}

class LateTickEvent extends Event<LateTickable> {
  final double dt;

  const LateTickEvent(this.dt);

  @override
  void dispatch(LateTickable listener) {
    listener.onLateUpdate(dt);
  }
}

class GameTicker extends StatelessWidget {
  final Widget child;
  const GameTicker({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return _InternalGameTicker(
      game: GameProvider.of(context),
      child: child,
    );
  }
}

class _InternalGameTicker extends SingleChildRenderObjectWidget {
  final GameEngine game;
  const _InternalGameTicker({required this.game, required super.child});

  @override
  RenderGameTicker createRenderObject(BuildContext context) {
    return RenderGameTicker(game);
  }

  @override
  void updateRenderObject(BuildContext context, RenderGameTicker renderObject) {
    renderObject.game = game;
  }
}

class RenderGameTicker extends RenderProxyBox {
  GameEngine game;
  RenderGameTicker(this.game);

  Ticker? _ticker;
  Duration _lastTick = Duration.zero;
  double _accumulator = 0.0;

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
    final delta = elapsed - _lastTick;
    final dt = delta.inMicroseconds / 1000000.0;
    _lastTick = elapsed;

    game.ticker.update(dt);
    game.input.update();

    _accumulator += dt;

    // 1. Fixed Update Loop
    while (_accumulator >= game.ticker.fixedDeltaTime) {
      _propagateFixedTick(this, game.ticker.fixedDeltaTime);
      _accumulator -= game.ticker.fixedDeltaTime;
    }

    // 2. Dispatch tick events to all game objects
    _propagateTick(this, dt);

    // 3. Run screen boundary pass
    if (hasSize) {
      game.screen.update(size);
    }

    // 4. Run centralized collision detection
    game.collision.runCollisionPass();

    // 5. Dispatch late tick events
    _propagateLateTick(this, dt);

    markNeedsPaint();

    // Signal completion of frame
    game.ticker.signalFrameComplete();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final cameras = game.cameras.allCameras
        .where((c) => c.gameObject.active)
        .toList();

    if (cameras.isEmpty) {
      super.paint(context, offset);
      return;
    }

    for (final camera in cameras) {
      Camera.current = camera;
      final screenSize = size;

      // 1. Clear background if needed
      if (camera.clearFlags == CameraClearFlags.solidColor) {
        final paint = Paint()..color = camera.backgroundColor;
        context.canvas.drawRect(offset & screenSize, paint);
      }

      // 2. Calculate Camera Transform
      final viewMatrix = camera.worldToCameraMatrix;
      final projMatrix = camera.projectionMatrix(screenSize);

      // We need a matrix that maps [-1, 1] to [0, width] and [0, height]
      final viewportMatrix = Matrix4.identity()
        ..translateByDouble(
          screenSize.width / 2,
          screenSize.height / 2,
          0.0,
          1.0,
        )
        ..scaleByDouble(screenSize.width / 2, -screenSize.height / 2, 1.0, 1.0);

      final fullCameraMatrix = viewportMatrix * projMatrix * viewMatrix;

      // 3. Render the scene with the camera transform
      context.pushTransform(true, offset, fullCameraMatrix, (context, offset) {
        // We need to handle cullingMask here if we want Unity parity.
        // For now, we just render everything.
        super.paint(context, offset);
      });
    }
    Camera.current = null;
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (game.cameras.isReady) {
      final camera = game.cameras.main;
      if (camera.gameObject.active) {
        final screenSize = size;
        final viewMatrix = camera.worldToCameraMatrix;
        final projMatrix = camera.projectionMatrix(screenSize);

        final viewportMatrix = Matrix4.identity()
          ..translateByDouble(
            screenSize.width / 2,
            screenSize.height / 2,
            0.0,
            1.0,
          )
          ..scaleByDouble(
            screenSize.width / 2,
            -screenSize.height / 2,
            1.0,
            1.0,
          );

        final fullCameraMatrix = viewportMatrix * projMatrix * viewMatrix;

        return result.addWithPaintTransform(
          transform: fullCameraMatrix,
          position: position,
          hitTest: (result, transformedPosition) {
            return super.hitTestChildren(result, position: transformedPosition);
          },
        );
      }
    }

    return super.hitTest(result, position: position);
  }

  void _propagateTick(RenderObject root, double dt) {
    if (root is GameRenderObject) {
      root.object.broadcastEvent(TickEvent(dt));
      return;
    }
    root.visitChildren((child) => _propagateTick(child, dt));
  }

  void _propagateFixedTick(RenderObject root, double dt) {
    if (root is GameRenderObject) {
      root.object.broadcastEvent(FixedTickEvent(dt));
      return;
    }
    root.visitChildren((child) => _propagateFixedTick(child, dt));
  }

  void _propagateLateTick(RenderObject root, double dt) {
    if (root is GameRenderObject) {
      root.object.broadcastEvent(LateTickEvent(dt));
      return;
    }
    root.visitChildren((child) => _propagateLateTick(child, dt));
  }
}
