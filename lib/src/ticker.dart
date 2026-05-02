import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:goo2d/src/game.dart';
import 'package:goo2d/src/event.dart';
import 'package:goo2d/src/camera.dart';

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

class GameLoop extends SingleChildRenderObjectWidget {
  final GameEngine game;
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

class RenderGameLoop extends RenderProxyBox {
  GameEngine game;
  Ticker? _ticker;
  Duration _lastTick = Duration.zero;
  bool _skipNextDelta = false;
  RenderGameLoop({required this.game});

  @override
  void performLayout() {
    super.performLayout();
    game.screen.screenSize = size;
  }

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

    if (hasSize) {
      game.screen.screenSize = size;
    }

    game.getSystem<TickerState>()?.tick(dt);

    // After updating the game state, we need to ensure the renderer repaints.
    markNeedsPaint();
  }
}

class GameRenderer extends SingleChildRenderObjectWidget {
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

class RenderGameRenderer extends RenderProxyBox {
  GameEngine game;
  RenderGameRenderer({required this.game});

  @override
  void performLayout() {
    super.performLayout();
    game.screen.screenSize = size;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (hasSize) {
      game.screen.screenSize = size;
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
