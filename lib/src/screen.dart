import 'dart:ui';
import 'package:goo2d/src/event.dart';
import 'package:goo2d/src/game.dart';

/// A mixin that provides callbacks for when an object enters or exits the screen.
/// 
/// [ScreenCollidable] is used by the [ScreenSystem] to notify components 
/// about visibility changes relative to the main camera's viewport. 
/// It is triggered as soon as any part of the object's collider 
/// crosses the boundary.
/// 
/// ```dart
/// class Bullet extends Behavior with ScreenCollidable {
///   @override
///   void onExitScreen() {
///     // Destroy the bullet once it leaves the view
///     gameObject.dispose();
///   }
/// }
/// ```
mixin ScreenCollidable implements EventListener {
  /// Called when object collider touches screen edge/enters the screen bounds.
  /// 
  /// Triggers as soon as any part of the bounding box enters the 
  /// main camera's viewport.
  void onEnterScreen() {}

  /// Called when object collider completely outside the screen bounds.
  /// 
  /// Triggers when the entire bounding box has left the viewport area.
  void onExitScreen() {}
}

/// A mixin for detecting when an object starts to leave or fully enters the screen.
/// 
/// [OuterScreenCollidable] provides the inverse logic of [ScreenCollidable]. 
/// It triggers [onOuterScreenEnter] as soon as the object starts moving 
/// outside, and [onOuterScreenExit] when it is entirely contained 
/// within the viewport.
mixin OuterScreenCollidable implements EventListener {
  /// Called when object collider touches screen edge/exits the screen bounds.
  /// 
  /// Triggers as soon as any part of the bounding box leaves the viewport.
  void onOuterScreenEnter() {}

  /// Called when object collider completely inside the screen bounds.
  /// 
  /// Triggers when the object is fully contained within the camera view.
  void onOuterScreenExit() {}
}

/// Event dispatched when a [ScreenCollidable] object enters the screen.
/// 
/// This event is used by the [ScreenSystem] to notify components that 
/// they have become visible within the main camera's viewport.
/// 
/// ```dart
/// const event = ScreenEnterEvent();
/// ```
class ScreenEnterEvent extends Event<ScreenCollidable> {
  /// Creates a [ScreenEnterEvent].
  /// 
  /// This constant constructor initializes the identification event.
  const ScreenEnterEvent();

  @override
  void dispatch(ScreenCollidable listener) {
    listener.onEnterScreen();
  }
}

/// Event dispatched when a [ScreenCollidable] object fully exits the screen.
/// 
/// This event is used by the [ScreenSystem] to notify components that 
/// they are no longer visible within the viewport boundaries.
/// 
/// ```dart
/// const event = ScreenExitEvent();
/// ```
class ScreenExitEvent extends Event<ScreenCollidable> {
  /// Creates a [ScreenExitEvent].
  /// 
  /// This constant constructor initializes the identification event.
  const ScreenExitEvent();

  @override
  void dispatch(ScreenCollidable listener) {
    listener.onExitScreen();
  }
}

/// Event dispatched when an [OuterScreenCollidable] object starts leaving the screen.
/// 
/// This event is used by the [ScreenSystem] to notify components that 
/// they are no longer fully contained within the viewport.
/// 
/// ```dart
/// const event = OuterScreenEnterEvent();
/// ```
class OuterScreenEnterEvent extends Event<OuterScreenCollidable> {
  /// Creates an [OuterScreenEnterEvent].
  /// 
  /// This constant constructor initializes the event used when an object 
  /// starts crossing the screen edge from the inside.
  const OuterScreenEnterEvent();

  @override
  void dispatch(OuterScreenCollidable listener) {
    listener.onOuterScreenEnter();
  }
}

/// Event dispatched when an [OuterScreenCollidable] object fully enters the screen.
/// 
/// This event is used by the [ScreenSystem] to notify components that 
/// they have moved entirely inside the viewport bounds.
/// 
/// ```dart
/// const event = OuterScreenExitEvent();
/// ```
class OuterScreenExitEvent extends Event<OuterScreenCollidable> {
  /// Creates an [OuterScreenExitEvent].
  /// 
  /// This constant constructor initializes the event used when an object 
  /// fully enters the viewport from the outside.
  const OuterScreenExitEvent();

  @override
  void dispatch(OuterScreenCollidable listener) {
    listener.onOuterScreenExit();
  }
}

/// The system responsible for monitoring viewport visibility and screen-edge collisions.
/// 
/// [ScreenSystem] iterates through all active colliders in the [PhysicsSystem] 
/// every frame and compares their world-space bounds against the 
/// main camera's viewport. It then dispatches the appropriate 
/// [ScreenCollidable] or [OuterScreenCollidable] events.
/// 
/// ```dart
/// final system = ScreenSystem();
/// system.update(myScreenSize);
/// ```
/// 
/// This system ensures that game logic (like object culling or 
/// bullet destruction) can react to screen boundaries without 
/// manual coordinate checks in every behavior.
class ScreenSystem implements GameSystem {
  GameEngine? _game;
  
  @override
  GameEngine get game {
    assert(_game != null, 'ScreenSystem: game is not ready. Did you call initialize()?');
    return _game!;
  }
  
  @override
  bool get gameAttached => _game != null;

  /// Creates a [ScreenSystem].
  /// 
  /// This constructor initializes the system that monitors object 
  /// visibility relative to the camera viewport.
  ScreenSystem();

  @override
  void attach(GameEngine game) {
    _game = game;
  }
 
  @override
  void dispose() {}

  /// Analyzes the position of all colliders relative to the [screenSize].
  /// 
  /// This method is called by the [TickerState] every frame. It identifies 
  /// the [CameraSystem.main] camera to determine the current world-space 
  /// viewport rectangle.
  /// 
  /// * [screenSize]: The current logical size of the game window.
  void update(Size screenSize) {
    final Rect screenRect;

    if (game.cameras.isReady) {
      final camera = game.cameras.main;
      final tl = camera.screenToWorldPoint(Offset.zero, screenSize);
      final br = camera.screenToWorldPoint(
        Offset(screenSize.width, screenSize.height),
        screenSize,
      );
      screenRect = Rect.fromPoints(tl, br);
    } else {
      screenRect = Rect.fromLTWH(0, 0, screenSize.width, screenSize.height);
    }

    for (final collider in game.physics.activeColliders) {
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
