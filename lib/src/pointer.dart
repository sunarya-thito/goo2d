import 'package:flutter/gestures.dart';
import 'package:goo2d/goo2d.dart';

/// A mixin that allows a [Component] to receive pointer-related events.
/// 
/// [PointerReceiver] provides standard hooks for mouse and touch interactions.
/// To use it, a component must mixin this interface and implement the 
/// desired handlers. These handlers are invoked by the [GameObject] 
/// during the hit-testing phase of the game loop.
/// 
/// ```dart
/// class MyInputHandler extends Component with PointerReceiver {
///   @override
///   void onPointerDown(PointerDownEvent event) {
///     print('Touched at ${event.position}');
///   }
/// }
/// ```
mixin PointerReceiver implements EventListener {
  /// Called when a pointer makes contact with the screen.
  /// 
  /// Triggers on the initial touch or click within the hit area.
  /// 
  /// * [event]: The raw Flutter pointer down data.
  void onPointerDown(PointerDownEvent event) {}

  /// Called when a pointer stops contacting the screen.
  /// 
  /// Triggers when the user lifts their finger or releases the mouse.
  /// 
  /// * [event]: The raw Flutter pointer up data.
  void onPointerUp(PointerUpEvent event) {}

  /// Called when a pointer moves while contacting the screen.
  /// 
  /// Triggers continuously as the pointer is dragged across the object.
  /// 
  /// * [event]: The raw Flutter pointer move data.
  void onPointerMove(PointerMoveEvent event) {}

  /// Called when the pointer interaction is interrupted.
  /// 
  /// Occurs during system events like low battery alerts or incoming calls.
  /// 
  /// * [event]: The raw Flutter pointer cancel data.
  void onPointerCancel(PointerCancelEvent event) {}

  /// Called when a pointer enters this object's hit area.
  /// 
  /// Triggers when a mouse cursor or touch point enters the collision boundary.
  /// 
  /// * [event]: The raw Flutter pointer enter data.
  void onPointerEnter(PointerEnterEvent event) {}

  /// Called when a pointer exits this object's hit area.
  /// 
  /// Triggers when the pointer leaves the collision boundary.
  /// 
  /// * [event]: The raw Flutter pointer exit data.
  void onPointerExit(PointerExitEvent event) {}

  /// Called when a pointer moves within this object's area without being pressed.
  /// 
  /// Triggers for mouse hover events that do not involve a button press.
  /// 
  /// * [event]: The raw Flutter pointer hover data.
  void onPointerHover(PointerHoverEvent event) {}
}

/// An event dispatched when a pointer is pressed down.
/// 
/// Used by [PointerReceiver] to handle touch and mouse click interactions.
/// 
/// ```dart
/// final event = GamePointerDownEvent(rawEvent);
/// ```
class GamePointerDownEvent extends Event<PointerReceiver> {
  /// The raw Flutter [PointerDownEvent].
  /// 
  /// Contains position, pressure, and device information.
  final PointerDownEvent event;

  /// Creates a [GamePointerDownEvent] with the given [event].
  /// 
  /// Encapsulates the Flutter event for the Goo2D event system.
  /// 
  /// * [event]: The source pointer down event.
  const GamePointerDownEvent(this.event);

  @override
  void dispatch(PointerReceiver listener) {
    listener.onPointerDown(event);
  }
}

/// An event dispatched when a pointer is released.
/// 
/// Used by [PointerReceiver] to handle the completion of touch or click actions.
/// 
/// ```dart
/// final event = GamePointerUpEvent(rawEvent);
/// ```
class GamePointerUpEvent extends Event<PointerReceiver> {
  /// The raw Flutter [PointerUpEvent].
  /// 
  /// Contains final position and pressure information.
  final PointerUpEvent event;

  /// Creates a [GamePointerUpEvent] with the given [event].
  /// 
  /// Encapsulates the Flutter event for the Goo2D event system.
  /// 
  /// * [event]: The source pointer up event.
  const GamePointerUpEvent(this.event);

  @override
  void dispatch(PointerReceiver listener) {
    listener.onPointerUp(event);
  }
}

/// An event dispatched when a pointer moves while pressed.
/// 
/// Used by [PointerReceiver] to handle dragging and movement tracking.
/// 
/// ```dart
/// final event = GamePointerMoveEvent(rawEvent);
/// ```
class GamePointerMoveEvent extends Event<PointerReceiver> {
  /// The raw Flutter [PointerMoveEvent].
  /// 
  /// Contains delta and updated position information.
  final PointerMoveEvent event;

  /// Creates a [GamePointerMoveEvent] with the given [event].
  /// 
  /// Encapsulates the Flutter event for the Goo2D event system.
  /// 
  /// * [event]: The source pointer move event.
  const GamePointerMoveEvent(this.event);

  @override
  void dispatch(PointerReceiver listener) {
    listener.onPointerMove(event);
  }
}

/// An event dispatched when a pointer interaction is canceled.
/// 
/// Used by [PointerReceiver] to handle system-level interruptions.
/// 
/// ```dart
/// final event = GamePointerCancelEvent(rawEvent);
/// ```
class GamePointerCancelEvent extends Event<PointerReceiver> {
  /// The raw Flutter [PointerCancelEvent].
  /// 
  /// Contains information about why the interaction was interrupted.
  final PointerCancelEvent event;

  /// Creates a [GamePointerCancelEvent] with the given [event].
  /// 
  /// Encapsulates the Flutter event for the Goo2D event system.
  /// 
  /// * [event]: The source pointer cancel event.
  const GamePointerCancelEvent(this.event);

  @override
  void dispatch(PointerReceiver listener) {
    listener.onPointerCancel(event);
  }
}

/// An event dispatched when a pointer enters an object's area.
/// 
/// Used by [PointerReceiver] to handle hover entry and focus detection.
/// 
/// ```dart
/// final event = GamePointerEnterEvent(rawEvent);
/// ```
class GamePointerEnterEvent extends Event<PointerReceiver> {
  /// The raw Flutter [PointerEnterEvent].
  /// 
  /// Contains the entry position and device type.
  final PointerEnterEvent event;

  /// Creates a [GamePointerEnterEvent] with the given [event].
  /// 
  /// Encapsulates the Flutter event for the Goo2D event system.
  /// 
  /// * [event]: The source pointer enter event.
  const GamePointerEnterEvent(this.event);

  @override
  void dispatch(PointerReceiver listener) {
    listener.onPointerEnter(event);
  }
}

/// An event dispatched when a pointer exits an object's area.
/// 
/// Used by [PointerReceiver] to handle hover exit and loss of focus.
/// 
/// ```dart
/// final event = GamePointerExitEvent(rawEvent);
/// ```
class GamePointerExitEvent extends Event<PointerReceiver> {
  /// The raw Flutter [PointerExitEvent].
  /// 
  /// Contains the exit position and device type.
  final PointerExitEvent event;

  /// Creates a [GamePointerExitEvent] with the given [event].
  /// 
  /// Encapsulates the Flutter event for the Goo2D event system.
  /// 
  /// * [event]: The source pointer exit event.
  const GamePointerExitEvent(this.event);

  @override
  void dispatch(PointerReceiver listener) {
    listener.onPointerExit(event);
  }
}

/// An event dispatched when a pointer hovers over an object.
/// 
/// Used by [PointerReceiver] to handle mouse movement without button presses.
/// 
/// ```dart
/// final event = GamePointerHoverEvent(rawEvent);
/// ```
class GamePointerHoverEvent extends Event<PointerReceiver> {
  /// The raw Flutter [PointerHoverEvent].
  /// 
  /// Contains the current hover position.
  final PointerHoverEvent event;

  /// Creates a [GamePointerHoverEvent] with the given [event].
  /// 
  /// Encapsulates the Flutter event for the Goo2D event system.
  /// 
  /// * [event]: The source pointer hover event.
  const GamePointerHoverEvent(this.event);

  @override
  void dispatch(PointerReceiver listener) {
    listener.onPointerHover(event);
  }
}
