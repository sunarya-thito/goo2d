import 'package:goo2d/src/component.dart';
import 'package:goo2d/src/object.dart';

/// A mixin used to mark a [Component] as a subscriber to specific [Event]s.
///
/// Components that implement this mixin can be targeted by events of the
/// corresponding type.
mixin EventListener on Component {}

/// Base class for all events dispatched through the [GameObject] hierarchy.
///
/// Events provide a decoupled way to notify components of specific occurrences
/// without requiring direct references between the dispatcher and listeners.
///
/// ```dart
/// class MyListener extends Component with EventListener {
///   void onMyEvent() => print('Event received!');
/// }
///
/// class MyEvent extends Event<MyListener> {
///   @override
///   void dispatch(MyListener listener) => listener.onMyEvent();
/// }
/// ```
///
/// See also:
/// * [GameObject.sendEvent], to dispatch events to children.
/// * [GameObject.broadcastEvent], to dispatch events to self and children.
abstract class Event<T extends EventListener> {
  /// Constant constructor for subclasses.
  const Event();

  /// Dispatches the event to a specific [listener].
  ///
  /// * [listener]: The component that will receive the event.
  void dispatch(T listener);

  /// Dispatches the event to all compatible components on a [GameObject].
  ///
  /// This method iterates through the object's components, filtering for
  /// those that implement the required [EventListener] type and ensuring
  /// they are enabled before calling [dispatch].
  ///
  /// * [object]: The game object whose components will receive the event.
  void dispatchTo(GameObject object) {
    for (final listener in object.components.whereType<T>()) {
      if (listener is Behavior && !(listener as Behavior).enabled) {
        continue;
      }
      dispatch(listener);
    }
  }
}
