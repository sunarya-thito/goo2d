import 'package:goo2d/src/event.dart';

/// A listener interface for fundamental object lifecycle events.
///
/// This mixin allows a class to respond to the critical moments of an object's
/// existence within the game world, specifically when it is added to or
/// removed from the active scene graph.
///
/// ```dart
/// class MyComponent extends Component with LifecycleListener {
///   @override
///   void onMounted() => print('Object is now active!');
/// }
/// ```
///
/// See also:
/// * [MountedEvent], which triggers the [onMounted] callback.
/// * [UnmountedEvent], which triggers the [onUnmounted] callback.
mixin LifecycleListener implements EventListener {
  /// Called when the object is added to the active scene graph.
  ///
  /// This method is the ideal place for initialization logic that requires
  /// access to the engine or other systems, as the object is guaranteed to be
  /// fully linked to the game instance at this point.
  void onMounted() {}

  /// Called when the object is removed from the active scene graph.
  ///
  /// Use this method to perform cleanup, such as cancelling timers,
  /// unregistering listeners, or releasing resources that are only valid
  /// while the object is active.
  void onUnmounted() {}
}

/// An event dispatched when an object becomes mounted.
///
/// This event triggers the [LifecycleListener.onMounted] callback for all
/// registered listeners, signaling that the object is now part of the active
/// simulation.
///
/// ```dart
/// class MyListener extends Component with LifecycleListener {}
/// void test() {
///   const event = MountedEvent();
///   event.dispatch(MyListener());
/// }
/// ```
///
/// See also:
/// * [LifecycleListener], the interface that responds to this event.
class MountedEvent extends Event<LifecycleListener> {
  /// Creates a new [MountedEvent].
  ///
  /// This constructor is primarily used by the [GameObject] hierarchy when
  /// transitioning an object to the mounted state, ensuring all components
  /// receive the appropriate lifecycle notification.
  const MountedEvent();

  @override
  void dispatch(LifecycleListener listener) {
    listener.onMounted();
  }
}

/// An event dispatched when an object becomes unmounted.
///
/// This event triggers the [LifecycleListener.onUnmounted] callback for all
/// registered listeners, signaling that the object is no longer part of the
/// active simulation.
///
/// ```dart
/// class MyListener extends Component with LifecycleListener {}
/// void test() {
///   const event = UnmountedEvent();
///   event.dispatch(MyListener());
/// }
/// ```
///
/// See also:
/// * [LifecycleListener], the interface that responds to this event.
class UnmountedEvent extends Event<LifecycleListener> {
  /// Creates a new [UnmountedEvent].
  ///
  /// This constructor is instantiated by the engine during the destruction or
  /// removal process of a [GameObject], notifying listeners that the object's
  /// active lifecycle has ended.
  const UnmountedEvent();

  @override
  void dispatch(LifecycleListener listener) {
    listener.onUnmounted();
  }
}

/// A mixin for objects that need to perform logic during a Hot Reload.
///
/// This interface is used by the engine to notify components that the code
/// has changed, allowing them to re-initialize state or refresh caches that
/// might have become stale due to the reload.
///
/// ```dart
/// class AssetRefresher extends Component with HotReloadable {
///   @override
///   void onHotReload() => print('Reloaded!');
/// }
/// ```
///
/// See also:
/// * [HotReloadEvent], which triggers the [onHotReload] callback.
mixin HotReloadable implements EventListener {
  /// Called when a Flutter Hot Reload occurs.
  ///
  /// This provides an opportunity to reset state that was compiled into the
  /// application or to re-fetch assets that may have been modified on disk.
  void onHotReload() {}
}

/// An event dispatched when a Flutter Hot Reload is detected.
///
/// This event triggers the [HotReloadable.onHotReload] callback, helping
/// maintain synchronization between the development environment and the
/// running game state.
///
/// ```dart
/// class MyReloadable extends Component with HotReloadable {}
/// void test() {
///   const event = HotReloadEvent();
///   event.dispatch(MyReloadable());
/// }
/// ```
///
/// See also:
/// * [HotReloadable], the interface that responds to this event.
class HotReloadEvent extends Event<HotReloadable> {
  /// Creates a new [HotReloadEvent].
  ///
  /// This event is automatically instantiated by the [GameEngine]'s hot reload
  /// handler, ensuring that all subscribers can react to code changes
  /// immediately during development.
  const HotReloadEvent();

  @override
  void dispatch(HotReloadable listener) {
    listener.onHotReload();
  }
}
