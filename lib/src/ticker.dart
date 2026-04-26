import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'game.dart';
import 'event.dart';
import 'object.dart';
import 'camera.dart';

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
    return _InternalGameTicker(game: GameProvider.of(context), child: child);
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

    while (_accumulator >= game.ticker.fixedDeltaTime) {
      _propagateFixedTick(this, game.ticker.fixedDeltaTime);
      _accumulator -= game.ticker.fixedDeltaTime;
    }

    _propagateTick(this, dt);

    if (hasSize) {
      game.screen.update(size);
    }

    game.collision.runCollisionPass();

    _propagateLateTick(this, dt);

    markNeedsPaint();

    game.ticker.signalFrameComplete();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!game.cameras.isReady) {
      super.paint(context, offset);
      return;
    }

    final camera = game.cameras.main;
    if (!camera.gameObject.active || !camera.enabled) {
      super.paint(context, offset);
      return;
    }

    final screenSize = size;
    game.ticker.screenSize = screenSize;

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
