import 'dart:ui';
import 'package:goo2d/src/event.dart';
import 'package:goo2d/src/game.dart';

mixin ScreenCollidable implements EventListener {
  void onEnterScreen() {}
  void onExitScreen() {}
}
mixin OuterScreenCollidable implements EventListener {
  void onOuterScreenEnter() {}
  void onOuterScreenExit() {}
}

class ScreenEnterEvent extends Event<ScreenCollidable> {
  const ScreenEnterEvent();

  @override
  void dispatch(ScreenCollidable listener) {
    listener.onEnterScreen();
  }
}

class ScreenExitEvent extends Event<ScreenCollidable> {
  const ScreenExitEvent();

  @override
  void dispatch(ScreenCollidable listener) {
    listener.onExitScreen();
  }
}

class OuterScreenEnterEvent extends Event<OuterScreenCollidable> {
  const OuterScreenEnterEvent();

  @override
  void dispatch(OuterScreenCollidable listener) {
    listener.onOuterScreenEnter();
  }
}

class OuterScreenExitEvent extends Event<OuterScreenCollidable> {
  const OuterScreenExitEvent();

  @override
  void dispatch(OuterScreenCollidable listener) {
    listener.onOuterScreenExit();
  }
}

class ScreenSystem implements GameSystem {
  GameEngine? _game;

  @override
  GameEngine get game {
    assert(
      _game != null,
      'ScreenSystem: game is not ready. Did you call initialize()?',
    );
    return _game!;
  }

  @override
  bool get gameAttached => _game != null;

  @override
  void attach(GameEngine game) {
    _game = game;
  }

  @override
  void dispose() {}
  Size screenSize = Size.zero;
}

class ScreenPhysicsSystem implements GameSystem {
  GameEngine? _game;

  @override
  GameEngine get game {
    assert(
      _game != null,
      'ScreenPhysicsSystem: game is not ready. Did you call initialize()?',
    );
    return _game!;
  }

  @override
  bool get gameAttached => _game != null;

  @override
  void attach(GameEngine game) {
    _game = game;
  }

  @override
  void dispose() {}

  void update() {
    final screenSize = game.screen.screenSize;
    if (screenSize == Size.zero) return;

    final Rect screenRect;

    final cameras = game.cameras;
    if (cameras.isReady) {
      final camera = cameras.main;
      final tl = camera.screenToWorldPoint(Offset.zero, screenSize);
      final br = camera.screenToWorldPoint(
        Offset(screenSize.width, screenSize.height),
        screenSize,
      );
      screenRect = Rect.fromPoints(tl, br);
    } else {
      screenRect = Rect.fromLTWH(0, 0, screenSize.width, screenSize.height);
    }

    final physics = game.physics;
    if (physics == null) return;

    for (final collider in physics.activeColliders) {
      final bounds = collider.worldBounds;
      final overlapping = screenRect.overlaps(bounds);

      // Check if fully inside
      final fullyInside =
          screenRect.left <= bounds.left &&
          screenRect.right >= bounds.right &&
          screenRect.top <= bounds.top &&
          screenRect.bottom >= bounds.bottom;

      final wasOverlapping = collider.wasOverlappingScreen;
      final wasFullyInside = collider.wasFullyInsideScreen;

      // ScreenCollidable: onEnterScreen (any part enters) / onExitScreen (all parts leave)
      if (overlapping && !wasOverlapping) {
        collider.gameObject.broadcastEvent(const ScreenEnterEvent());
      } else if (!overlapping && wasOverlapping) {
        collider.gameObject.broadcastEvent(const ScreenExitEvent());
      }

      // OuterScreenCollidable: onOuterScreenEnter (any part leaves) / onOuterScreenExit (all parts enter)
      if (!fullyInside && wasFullyInside) {
        collider.gameObject.broadcastEvent(const OuterScreenEnterEvent());
      } else if (fullyInside && !wasFullyInside) {
        collider.gameObject.broadcastEvent(const OuterScreenExitEvent());
      }

      collider.wasOverlappingScreen = overlapping;
      collider.wasFullyInsideScreen = fullyInside;
    }
  }
}
