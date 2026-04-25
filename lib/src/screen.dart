import 'dart:ui';

import 'package:goo2d/goo2d.dart';
import 'package:goo2d/src/collision.dart';

mixin ScreenCollidable implements EventListener {
  /// Called when object collider touches screen edge/enters the screen bounds.
  void onEnterScreen() {}

  /// Called when object collider completely outside the screen bounds.
  void onExitScreen() {}
}

mixin OuterScreenCollidable implements EventListener {
  /// Called when object collider touches screen edge/exits the screen bounds.
  void onOuterScreenEnter() {}

  /// Called when object collider completely inside the screen bounds.
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

class Screen {
  /// Checks all active colliders against the screen bounds and dispatches events.
  /// This should be called once per frame, usually after movement logic.
  static void update(Size screenSize) {
    final camera = Camera.main;
    final Rect screenRect;

    if (camera != null && camera.gameObject.active) {
      final tl = camera.screenToWorldPoint(Offset.zero, screenSize);
      final br = camera.screenToWorldPoint(
        Offset(screenSize.width, screenSize.height),
        screenSize,
      );
      screenRect = Rect.fromPoints(tl, br);
    } else {
      screenRect = Rect.fromLTWH(0, 0, screenSize.width, screenSize.height);
    }

    for (final collider in CollisionTrigger.active) {
      final bounds = collider.worldBounds;
      final overlapping = screenRect.overlaps(bounds);

      // Check if fully inside
      final fullyInside =
          screenRect.left <= bounds.left &&
          screenRect.right >= bounds.right &&
          screenRect.top <= bounds.top &&
          screenRect.bottom >= bounds.bottom;

      final wasOverlapping = internalGetWasOverlapping(collider);
      final wasFullyInside = internalGetWasFullyInside(collider);

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

      internalUpdateScreenState(
        collider,
        overlapping: overlapping,
        fullyInside: fullyInside,
      );
    }
  }
}
