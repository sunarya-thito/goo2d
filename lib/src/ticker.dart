import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:goo2d/goo2d.dart';

double _deltaTime = 0.0;

/// The delta time of the current frame in seconds.
double get deltaTime => _deltaTime;

int _frameCount = 0;

/// The current frame count of the engine.
int get frameCount => _frameCount;

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

class GameTicker extends SingleChildRenderObjectWidget {
  const GameTicker({super.key, required super.child});

  static final _frameController = StreamController<void>.broadcast();

  /// A future that completes when the next engine tick finishes.
  static Future<void> get nextFrame => _frameController.stream.first;

  @override
  RenderGameTicker createRenderObject(BuildContext context) {
    return RenderGameTicker();
  }
}

class RenderGameTicker extends RenderProxyBox {
  RenderGameTicker();

  Ticker? _ticker;
  Duration _lastTick = Duration.zero;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    InputSystem.init();
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
    _frameCount++;
    InputSystem.update();
    final delta = elapsed - _lastTick;
    _deltaTime = delta.inMicroseconds / 1000000.0;
    _lastTick = elapsed;

    // 1. Dispatch tick events to all game objects
    _propagateTick(this, _deltaTime);

    // 2. Run screen boundary pass
    if (hasSize) {
      Screen.update(size);
    }

    // 3. Run centralized collision detection
    Collider.runCollisionPass();

    markNeedsPaint();

    // Signal completion of frame
    GameTicker._frameController.add(null);
  }

  void _propagateTick(RenderObject root, double dt) {
    if (root is GameRenderObject) {
      root.object.broadcastEvent(TickEvent(dt));
      return;
    }
    root.visitChildren((child) => _propagateTick(child, dt));
  }
}
