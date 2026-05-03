import 'dart:ui';
import 'package:goo2d/src/event.dart';
import 'package:goo2d/src/game.dart';

/// A mixin that allows a component to respond to its game object entering or exiting the screen boundaries.
///
/// This mixin is used for simple visibility-based logic, such as pausing
/// animations when an object is off-screen or triggering effects when it
/// becomes visible.
///
/// See also:
/// * [ScreenPhysicsSystem] for the system that detects these events.
mixin ScreenCollidable implements EventListener {
  /// Called when any part of the game object's collider enters the screen.
  ///
  /// Override this method to trigger effects that should occur as soon as 
  /// an object becomes visible, such as starting a particle emitter.
  void onEnterScreen() {}

  /// Called when the entire game object's collider exits the screen.
  ///
  /// Override this method to clean up or pause logic when an object is 
  /// completely off-screen, helping to save processing power.
  void onExitScreen() {}
}

/// A mixin that allows a component to respond to its game object crossing the "inner" boundary of the screen.
///
/// This mixin is useful for logic that triggers when an object is no longer
/// fully contained within the screen (enters the "outer" area) or when it
/// returns to being fully visible (exits the "outer" area).
///
/// See also:
/// * [ScreenPhysicsSystem] for the system that detects these events.
mixin OuterScreenCollidable implements EventListener {
  /// Called when any part of the game object's collider leaves the screen.
  ///
  /// Override this method to handle logic that occurs when an object is 
  /// no longer fully visible, such as warning the player.
  void onOuterScreenEnter() {}

  /// Called when the entire game object's collider returns to being inside the screen.
  ///
  /// Override this method to reset state when an object returns to being 
  /// fully contained within the viewport boundaries.
  void onOuterScreenExit() {}
}

/// An event triggered when a game object enters the screen.
///
/// This event is dispatched to all [ScreenCollidable] listeners on the
/// game object when its world bounds start overlapping with the screen rect.
///
/// ```dart
/// void example(GameObject object) {
///   const event = ScreenEnterEvent();
///   object.broadcastEvent(event);
/// }
/// ```
///
/// See also:
/// * [ScreenCollidable] for the listener interface.
class ScreenEnterEvent extends Event<ScreenCollidable> {
  /// Creates a new [ScreenEnterEvent].
  ///
  /// This constructor is typically called by the [ScreenPhysicsSystem]
  /// when a collision with the viewport is detected.
  const ScreenEnterEvent();

  @override
  void dispatch(ScreenCollidable listener) {
    listener.onEnterScreen();
  }
}

/// An event triggered when a game object exits the screen.
///
/// This event is dispatched to all [ScreenCollidable] listeners on the
/// game object when its world bounds no longer overlap with the screen rect.
///
/// ```dart
/// void example(GameObject object) {
///   const event = ScreenExitEvent();
///   object.broadcastEvent(event);
/// }
/// ```
///
/// See also:
/// * [ScreenCollidable] for the listener interface.
class ScreenExitEvent extends Event<ScreenCollidable> {
  /// Creates a new [ScreenExitEvent].
  ///
  /// This constructor is typically called by the [ScreenPhysicsSystem]
  /// when an object moves completely outside the viewport.
  const ScreenExitEvent();

  @override
  void dispatch(ScreenCollidable listener) {
    listener.onExitScreen();
  }
}

/// An event triggered when a game object starts leaving the screen.
///
/// This event is dispatched to all [OuterScreenCollidable] listeners on the
/// game object when it is no longer fully contained within the screen.
///
/// ```dart
/// void example(GameObject object) {
///   const event = OuterScreenEnterEvent();
///   object.broadcastEvent(event);
/// }
/// ```
///
/// See also:
/// * [OuterScreenCollidable] for the listener interface.
class OuterScreenEnterEvent extends Event<OuterScreenCollidable> {
  /// Creates a new [OuterScreenEnterEvent].
  ///
  /// This constructor is typically called by the [ScreenPhysicsSystem]
  /// when an object's boundary first crosses the inner screen edge.
  const OuterScreenEnterEvent();

  @override
  void dispatch(OuterScreenCollidable listener) {
    listener.onOuterScreenEnter();
  }
}

/// An event triggered when a game object returns fully to the screen.
///
/// This event is dispatched to all [OuterScreenCollidable] listeners on the
/// game object when its world bounds become fully contained within the screen.
///
/// ```dart
/// void example(GameObject object) {
///   const event = OuterScreenExitEvent();
///   object.broadcastEvent(event);
/// }
/// ```
///
/// See also:
/// * [OuterScreenCollidable] for the listener interface.
class OuterScreenExitEvent extends Event<OuterScreenCollidable> {
  /// Creates a new [OuterScreenExitEvent].
  ///
  /// This constructor is typically called by the [ScreenPhysicsSystem]
  /// when an object becomes entirely visible within the viewport.
  const OuterScreenExitEvent();

  @override
  void dispatch(OuterScreenCollidable listener) {
    listener.onOuterScreenExit();
  }
}

/// A system that manages the physical dimensions of the game's viewport.
///
/// [ScreenSystem] tracks the current size of the screen and provides it to
/// other systems and components. It is essential for layout calculations,
/// camera positioning, and UI scaling within the engine.
///
/// ```dart
/// void main() {
///   final engine = GameEngine({
///     ScreenSystem.new, // registers the system
///   });
/// }
/// ```
///
/// See also:
/// * [ScreenPhysicsSystem] for bounds-based event detection.
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

  /// The current dimensions of the game viewport in logical pixels.
  ///
  /// This value is updated by the engine whenever the underlying Flutter
  /// widget changes size. It should be used as the reference for all
  /// screen-space calculations.
  Size screenSize = Size.zero;
}

/// A system that detects when game objects enter or exit the screen.
///
/// [ScreenPhysicsSystem] monitors all active colliders and compares their
/// world-space bounds against the screen rectangle (calculated from the
/// main camera). It dispatches screen-related events to components
/// implementing [ScreenCollidable] or [OuterScreenCollidable].
///
/// ```dart
/// void main() {
///   final engine = GameEngine({
///     ScreenPhysicsSystem.new, // registers the system
///   });
/// }
/// ```
///
/// See also:
/// * [ScreenCollidable] for receiving visibility events.
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

  /// Evaluates all active colliders against the screen boundaries.
  ///
  /// This method is called by the engine during the update pass. It
  /// calculates the world-space viewport rectangle and checks for
  /// overlaps with every collider in the physics system, triggering
  /// [ScreenEnterEvent] and other related events when state changes occur.
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
