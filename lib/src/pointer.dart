import 'package:flutter/gestures.dart';
import 'package:goo2d/goo2d.dart';

/// A mixin that provides pointer event handling capabilities.
///
/// This mixin allows components to respond to various pointer interactions (like mouse clicks or touch events)
/// without having to manually implement the [EventListener] interface from scratch. Apply this mixin to any 
/// class that implements [EventListener], then override the desired pointer event methods to handle specific events.
///
/// ```dart
/// class MyComponent extends Component with PointerReceiver {
///   @override
///   void onPointerDown(PointerDownEvent event) {
///     // Handle the pointer down interaction
///   }
/// }
/// ```
///
/// See also:
/// * [EventListener] for the base event listener interface.
mixin PointerReceiver implements EventListener {
  /// Called when a pointer down event occurs.
  ///
  /// This method is used to respond to the initial contact of a pointer (e.g., mouse press or touch start). 
  /// Override it to perform actions like selecting an object or starting a drag operation.
  ///
  /// * [event]: The raw pointer down event data.
  void onPointerDown(PointerDownEvent event) {}

  /// Called when a pointer up event occurs.
  ///
  /// This method is used to respond to the release of a pointer (e.g., mouse release or touch end). 
  /// Override it to finalize actions started in [onPointerDown] or to trigger a click action.
  ///
  /// * [event]: The raw pointer up event data.
  void onPointerUp(PointerUpEvent event) {}

  /// Called when a pointer move event occurs.
  ///
  /// This method tracks the movement of a pointer across the screen. Override it to implement 
  /// dragging, drawing, or other motion-based logic.
  ///
  /// * [event]: The raw pointer movement data.
  void onPointerMove(PointerMoveEvent event) {}

  /// Called when a pointer cancel event occurs.
  ///
  /// This method handles situations where a pointer interaction is interrupted by the system 
  /// (e.g., a phone call). Override it to reset any temporary state or cancel ongoing drag operations.
  ///
  /// * [event]: The raw pointer cancellation data.
  void onPointerCancel(PointerCancelEvent event) {}

  /// Called when a pointer enters the component's boundaries.
  ///
  /// This method provides visual feedback or triggers logic when a pointer starts hovering over 
  /// a component. Override it to show tooltips, highlight the component, or change the cursor style.
  ///
  /// * [event]: The raw pointer entry data.
  void onPointerEnter(PointerEnterEvent event) {}

  /// Called when a pointer exits the component's boundaries.
  ///
  /// This method cleans up visual feedback or stops logic when a pointer stops hovering over 
  /// a component. Override it to hide tooltips, remove highlights, or restore the default cursor.
  ///
  /// * [event]: The raw pointer exit data.
  void onPointerExit(PointerExitEvent event) {}

  /// Called when a pointer hovers over the component.
  ///
  /// This method responds to pointer movement while it is within the component's boundaries but 
  /// not pressed. Override it to implement hover-based interactions like updating a custom cursor position.
  ///
  /// * [event]: The raw pointer hover movement data.
  void onPointerHover(PointerHoverEvent event) {}
}

/// An event representing a pointer down interaction.
///
/// This class encapsulates a [PointerDownEvent] for dispatching to [PointerReceiver] listeners. 
/// Instantiate it with a [PointerDownEvent] and dispatch it through the event system.
///
/// ```dart
/// void example(PointerDownEvent rawEvent, GameObject gameObject) {
///   final event = GamePointerDownEvent(rawEvent);
///   gameObject.sendEvent(event);
/// }
/// ```
///
/// See also:
/// * [PointerReceiver] for the listener interface that handles this event.
/// * [Event] for the base event class.
class GamePointerDownEvent extends Event<PointerReceiver> {
  /// The underlying Flutter pointer event.
  ///
  /// This field provides access to the raw event data such as position and pressure. 
  /// It should be accessed within the [PointerReceiver.onPointerDown] callback.
  final PointerDownEvent event;

  /// Creates a new [GamePointerDownEvent].
  ///
  /// This constructor wraps a raw [event] for use in the game engine's event system. 
  /// The [event] is typically obtained from Flutter's gesture system.
  ///
  /// * [event]: The raw Flutter down event to wrap.
  const GamePointerDownEvent(this.event);

  @override
  void dispatch(PointerReceiver listener) {
    listener.onPointerDown(event);
  }
}

/// An event representing a pointer up interaction.
///
/// This class encapsulates a [PointerUpEvent] for dispatching to [PointerReceiver] listeners. 
/// Instantiate it with a [PointerUpEvent] and dispatch it through the event system.
///
/// ```dart
/// void example(PointerUpEvent rawEvent, GameObject gameObject) {
///   final event = GamePointerUpEvent(rawEvent);
///   gameObject.sendEvent(event);
/// }
/// ```
///
/// See also:
/// * [PointerReceiver] for the listener interface that handles this event.
/// * [Event] for the base event class.
class GamePointerUpEvent extends Event<PointerReceiver> {
  /// The underlying Flutter pointer event.
  ///
  /// This field provides access to the raw event data such as position and release details. 
  /// It should be accessed within the [PointerReceiver.onPointerUp] callback.
  final PointerUpEvent event;

  /// Creates a new [GamePointerUpEvent].
  ///
  /// This constructor wraps a raw [event] for use in the game engine's event system. 
  /// The [event] is typically obtained from Flutter's gesture system.
  ///
  /// * [event]: The raw Flutter up event to wrap.
  const GamePointerUpEvent(this.event);

  @override
  void dispatch(PointerReceiver listener) {
    listener.onPointerUp(event);
  }
}

/// An event representing a pointer move interaction.
///
/// This class encapsulates a [PointerMoveEvent] for dispatching to [PointerReceiver] listeners. 
/// Instantiate it with a [PointerMoveEvent] and dispatch it through the event system.
///
/// ```dart
/// void example(PointerMoveEvent rawEvent, GameObject gameObject) {
///   final event = GamePointerMoveEvent(rawEvent);
///   gameObject.sendEvent(event);
/// }
/// ```
///
/// See also:
/// * [PointerReceiver] for the listener interface that handles this event.
/// * [Event] for the base event class.
class GamePointerMoveEvent extends Event<PointerReceiver> {
  /// The underlying Flutter pointer event.
  ///
  /// This field provides access to the raw event data such as current position and delta. 
  /// It should be accessed within the [PointerReceiver.onPointerMove] callback.
  final PointerMoveEvent event;

  /// Creates a new [GamePointerMoveEvent].
  ///
  /// This constructor wraps a raw [event] for use in the game engine's event system. 
  /// The [event] is typically obtained from Flutter's gesture system.
  ///
  /// * [event]: The raw Flutter move event to wrap.
  const GamePointerMoveEvent(this.event);

  @override
  void dispatch(PointerReceiver listener) {
    listener.onPointerMove(event);
  }
}

/// An event representing a pointer cancel interaction.
///
/// This class encapsulates a [PointerCancelEvent] for dispatching to [PointerReceiver] listeners. 
/// Instantiate it with a [PointerCancelEvent] and dispatch it through the event system.
///
/// ```dart
/// void example(PointerCancelEvent rawEvent, GameObject gameObject) {
///   final event = GamePointerCancelEvent(rawEvent);
///   gameObject.sendEvent(event);
/// }
/// ```
///
/// See also:
/// * [PointerReceiver] for the listener interface that handles this event.
/// * [Event] for the base event class.
class GamePointerCancelEvent extends Event<PointerReceiver> {
  /// The underlying Flutter pointer event.
  ///
  /// This field provides access to the raw event data for the cancellation. 
  /// It should be accessed within the [PointerReceiver.onPointerCancel] callback.
  final PointerCancelEvent event;

  /// Creates a new [GamePointerCancelEvent].
  ///
  /// This constructor wraps a raw [event] for use in the game engine's event system. 
  /// The [event] is typically obtained from Flutter's gesture system.
  ///
  /// * [event]: The raw Flutter cancel event to wrap.
  const GamePointerCancelEvent(this.event);

  @override
  void dispatch(PointerReceiver listener) {
    listener.onPointerCancel(event);
  }
}

/// An event representing a pointer enter interaction.
///
/// This class encapsulates a [PointerEnterEvent] for dispatching to [PointerReceiver] listeners. 
/// Instantiate it with a [PointerEnterEvent] and dispatch it through the event system.
///
/// ```dart
/// void example(PointerEnterEvent rawEvent, GameObject gameObject) {
///   final event = GamePointerEnterEvent(rawEvent);
///   gameObject.sendEvent(event);
/// }
/// ```
///
/// See also:
/// * [PointerReceiver] for the listener interface that handles this event.
/// * [Event] for the base event class.
class GamePointerEnterEvent extends Event<PointerReceiver> {
  /// The underlying Flutter pointer event.
  ///
  /// This field provides access to the raw event data when a pointer enters the component. 
  /// It should be accessed within the [PointerReceiver.onPointerEnter] callback.
  final PointerEnterEvent event;

  /// Creates a new [GamePointerEnterEvent].
  ///
  /// This constructor wraps a raw [event] for use in the game engine's event system. 
  /// The [event] is typically obtained from Flutter's gesture system.
  ///
  /// * [event]: The raw Flutter enter event to wrap.
  const GamePointerEnterEvent(this.event);

  @override
  void dispatch(PointerReceiver listener) {
    listener.onPointerEnter(event);
  }
}

/// An event representing a pointer exit interaction.
///
/// This class encapsulates a [PointerExitEvent] for dispatching to [PointerReceiver] listeners. 
/// Instantiate it with a [PointerExitEvent] and dispatch it through the event system.
///
/// ```dart
/// void example(PointerExitEvent rawEvent, GameObject gameObject) {
///   final event = GamePointerExitEvent(rawEvent);
///   gameObject.sendEvent(event);
/// }
/// ```
///
/// See also:
/// * [PointerReceiver] for the listener interface that handles this event.
/// * [Event] for the base event class.
class GamePointerExitEvent extends Event<PointerReceiver> {
  /// The underlying Flutter pointer event.
  ///
  /// This field provides access to the raw event data when a pointer exits the component. 
  /// It should be accessed within the [PointerReceiver.onPointerExit] callback.
  final PointerExitEvent event;

  /// Creates a new [GamePointerExitEvent].
  ///
  /// This constructor wraps a raw [event] for use in the game engine's event system. 
  /// The [event] is typically obtained from Flutter's gesture system.
  ///
  /// * [event]: The raw Flutter exit event to wrap.
  const GamePointerExitEvent(this.event);

  @override
  void dispatch(PointerReceiver listener) {
    listener.onPointerExit(event);
  }
}

/// An event representing a pointer hover interaction.
///
/// This class encapsulates a [PointerHoverEvent] for dispatching to [PointerReceiver] listeners. 
/// Instantiate it with a [PointerHoverEvent] and dispatch it through the event system.
///
/// ```dart
/// void example(PointerHoverEvent rawEvent, GameObject gameObject) {
///   final event = GamePointerHoverEvent(rawEvent);
///   gameObject.sendEvent(event);
/// }
/// ```
///
/// See also:
/// * [PointerReceiver] for the listener interface that handles this event.
/// * [Event] for the base event class.
class GamePointerHoverEvent extends Event<PointerReceiver> {
  /// The underlying Flutter pointer event.
  ///
  /// This field provides access to the raw event data during hover movement. 
  /// It should be accessed within the [PointerReceiver.onPointerHover] callback.
  final PointerHoverEvent event;

  /// Creates a new [GamePointerHoverEvent].
  ///
  /// This constructor wraps a raw [event] for use in the game engine's event system. 
  /// The [event] is typically obtained from Flutter's gesture system.
  ///
  /// * [event]: The raw Flutter hover event to wrap.
  const GamePointerHoverEvent(this.event);

  @override
  void dispatch(PointerReceiver listener) {
    listener.onPointerHover(event);
  }
}
