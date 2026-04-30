import 'package:goo2d/src/event.dart';

/// A mixin for objects that need to react to mounting and unmounting events.
///
/// This mixin allows a class to be registered as an [EventListener] specifically
/// for lifecycle transitions. It is commonly used by components that need to
/// initialize resources when added to the scene graph and release them when removed.
///
/// ```dart
/// class MyComponent extends Component with LifecycleListener {
///   @override
///   void onMounted() {
///     print('Component is now active in the world.');
///   }
/// }
/// ```
///
/// See also:
/// * [MountedEvent] for the event triggered during mounting.
/// * [UnmountedEvent] for the event triggered during unmounting.
mixin LifecycleListener implements EventListener {
  /// Invoked when the object is added to the active scene graph.
  ///
  /// Use this method to perform one-time setup, such as subscribing to events,
  /// starting animations, or initializing hardware-dependent resources. This 
  /// is called exactly once per mount cycle.
  void onMounted() {}

  /// Invoked when the object is removed from the active scene graph.
  ///
  /// Use this method to clean up resources allocated in [onMounted]. This
  /// ensures that there are no memory leaks or dangling event subscriptions
  /// when the object is no longer part of the simulation.
  void onUnmounted() {}
}

/// An event dispatched when an object is mounted.
///
/// This event is sent through the event system when a object enters the 
/// active hierarchy. It triggers the [LifecycleListener] callback on
/// all registered listeners.
///
/// ```dart
/// world.dispatch(const MountedEvent());
/// ```
///
/// See also:
/// * [LifecycleListener] for the interface that reacts to this event.
class MountedEvent extends Event<LifecycleListener> {
  /// Creates a [MountedEvent] instance.
  /// 
  /// This constructor initializes the event used to notify listeners 
  /// that an object has been added to the scene graph.
  const MountedEvent();

  @override
  void dispatch(LifecycleListener listener) {
    listener.onMounted();
  }
}

/// An event dispatched when an object is unmounted.
///
/// This event signifies that the object is being removed from the hierarchy
/// and should stop its processing. It triggers the [LifecycleListener]
/// callback on all registered listeners.
///
/// ```dart
/// world.dispatch(const UnmountedEvent());
/// ```
///
/// See also:
/// * [LifecycleListener] for the interface that reacts to this event.
class UnmountedEvent extends Event<LifecycleListener> {
  /// Creates an [UnmountedEvent] instance.
  /// 
  /// This constructor initializes the event used to notify listeners 
  /// that an object has been removed from the scene graph.
  const UnmountedEvent();

  @override
  void dispatch(LifecycleListener listener) {
    listener.onUnmounted();
  }
}
