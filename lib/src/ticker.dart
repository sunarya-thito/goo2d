import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:goo2d/goo2d.dart';

double _deltaTime = 0.0;

/// The delta time of the current frame in seconds.
double get deltaTime => _deltaTime;

double _fixedDeltaTime = 0.02;

/// The fixed delta time for the physics/fixed update loop in seconds. Defaults to 0.02 (50Hz).
double get fixedDeltaTime => _fixedDeltaTime;
set fixedDeltaTime(double value) => _fixedDeltaTime = value;

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
  double _accumulator = 0.0;

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

    _accumulator += _deltaTime;

    // 1. Fixed Update Loop
    while (_accumulator >= _fixedDeltaTime) {
      _propagateFixedTick(this, _fixedDeltaTime);
      _accumulator -= _fixedDeltaTime;
    }

    // 2. Dispatch tick events to all game objects
    _propagateTick(this, _deltaTime);

    // 3. Run screen boundary pass
    if (hasSize) {
      Screen.update(size);
    }

    // 4. Run centralized collision detection
    CollisionTrigger.runCollisionPass();

    // 5. Dispatch late tick events
    _propagateLateTick(this, _deltaTime);

    markNeedsPaint();

    // Signal completion of frame
    GameTicker._frameController.add(null);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final cameras = Camera.allCameras.where((c) => c.gameObject.active).toList();

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
        ..translateByDouble(screenSize.width / 2, screenSize.height / 2, 0.0, 1.0)
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
    final camera = Camera.main;
    if (camera != null && camera.gameObject.active) {
      final screenSize = size;
      final viewMatrix = camera.worldToCameraMatrix;
      final projMatrix = camera.projectionMatrix(screenSize);

      final viewportMatrix = Matrix4.identity()
        ..translateByDouble(screenSize.width / 2, screenSize.height / 2, 0.0, 1.0)
        ..scaleByDouble(screenSize.width / 2, -screenSize.height / 2, 1.0, 1.0);

      final fullCameraMatrix = viewportMatrix * projMatrix * viewMatrix;

      return result.addWithPaintTransform(
        transform: fullCameraMatrix,
        position: position,
        hitTest: (result, transformedPosition) {
          return super.hitTestChildren(result, position: transformedPosition);
        },
      );
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
