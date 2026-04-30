import 'package:goo2d/goo2d.dart';

/// A mixin that identifies a [Component] as a target for specific [Event]s.
/// 
/// To receive events, a component must mix in [EventListener] or a subclass 
/// of it. The [Event] system uses this type information to efficiently 
/// dispatch messages only to components that can handle them.
/// 
/// See also:
/// * [Event] for the base class used to define and dispatch messages.
mixin EventListener on Component {}

/// Base class for all messages dispatched through the game object hierarchy.
///
/// Events in Goo2D are strongly typed and use a double-dispatch mechanism. 
/// Each [Event] subclass targets a specific [EventListener] type [T] and defines 
/// a [dispatch] method that calls the appropriate handler on that listener.
///
/// This architecture ensures type safety without the need for manual type 
/// checking or casting at the call site, while allowing components to opt-in 
/// to only the events they care about.
///
/// ```dart
/// // 1. Define a listener interface
/// mixin OnJumpListener on EventListener {
///   void onJump(double height);
/// }
///
/// // 2. Define the event
/// class JumpEvent extends Event< OnJumpListener > {
///   final double height;
///   JumpEvent(this.height);
///
///   @override
///   void dispatch(OnJumpListener listener) => listener.onJump(height);
/// }
/// ```
///
/// See also:
/// * [EventListener], the interface for objects that can receive events.
abstract class Event<T extends EventListener> {
  /// Constant constructor for subclasses.
  ///
  /// Using constant constructors for events without data (like triggers)
  /// is highly recommended to reduce memory allocation during the game loop.
  const Event();

  /// Dispatches this event to a specific [listener].
  ///
  /// This method implements the "visitor" part of the double-dispatch pattern.
  /// Subclasses must override this to call the appropriate method on the 
  /// typed [listener].
  ///
  /// * [listener]: The target object that will receive the callback.
  void dispatch(T listener);

  /// Dispatches this event specifically to the components of a single [object].
  ///
  /// This method iterates through all components attached to the [object] and 
  /// checks if they are enabled and implement the listener interface [T].
  /// If so, it calls the event's [dispatch] method.
  ///
  /// * [object]: The specific object whose components should receive the event.
  void dispatchTo(GameObject object) {
    for (final listener in object.components.whereType<T>()) {
      if (listener is Behavior && !(listener as Behavior).enabled) {
        continue;
      }
      dispatch(listener);
    }
  }
}
