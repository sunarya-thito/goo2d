import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:goo2d/goo2d.dart';

@internal
void internalAttach(Component component, GameObject gameObject) {
  component._gameObject = gameObject;
}

mixin ComponentFuture<T extends Component>
    implements Future<ComponentFactory<T>> {
  @internal
  Type get internalType;
  @internal
  T internalCreate();

  @override
  Stream<ComponentFactory<T>> asStream() {
    return Stream.value(internalCreate);
  }

  @override
  Future<ComponentFactory<T>> catchError(
    Function onError, {
    bool Function(Object error)? test,
  }) {
    return this;
  }

  @override
  Future<R> then<R>(
    FutureOr<R> Function(ComponentFactory<T> value) onValue, {
    Function? onError,
  }) {
    return Future.value(onValue(internalCreate));
  }

  @override
  Future<ComponentFactory<T>> timeout(
    Duration timeLimit, {
    FutureOr<dynamic> Function()? onTimeout,
  }) {
    return this;
  }

  @override
  Future<ComponentFactory<T>> whenComplete(
    FutureOr<dynamic> Function() action,
  ) {
    action.call();
    return this;
  }
}

typedef ComponentFactory<T extends Component> = T Function();
typedef ComponentParameterHandler<T extends Component> =
    void Function(T component);

extension ComponentFactoryExtension<T extends Component>
    on ComponentFactory<T> {
  ComponentFuture<T> withParams(ComponentParameterHandler<T> params) {
    return _ComponentFactoryOf<T>(this, params);
  }

  ComponentFuture<T> get withNoParams => _ComponentFactoryOf<T>(this, null);
}

class _ComponentFactoryOf<T extends Component> with ComponentFuture<T> {
  final ComponentFactory<T> factory;
  final ComponentParameterHandler<T>? params;

  _ComponentFactoryOf(this.factory, this.params);

  @override
  T internalCreate() {
    final component = factory();
    params?.call(component);
    return component;
  }

  @override
  Type get internalType => T;
}

/// The base class for all functional logic attached to a [GameObject].
///
/// Components are modular building blocks that define the behavior,
/// state, or rendering of an object in the game world. They are
/// managed by their parent [GameObject] and receive lifecycle events
/// through the engine.
///
/// Once a component is added to an object via [addComponent], it gains
/// access to the scene hierarchy and engine systems. It uses a proxy
/// pattern to expose [GameObject] properties (like [transform], [parentObject],
/// etc.) directly for a more ergonomic API.
///
/// ```dart
/// class MyComponent extends Component {
///   @override
///   void onHotReload() {
///     super.onHotReload();
///     print('System reassembled: ${gameObject.name}');
///   }
/// }
/// ```
abstract class Component with ComponentFuture {
  GameObject? _gameObject;

  @override
  Component internalCreate() {
    return this;
  }

  @override
  Type get internalType => runtimeType;

  /// The [GameObject] this component is currently attached to.
  ///
  /// This property provides the primary context for the component. It is
  /// used to traverse the hierarchy, find other components, or dispatch
  /// events.
  ///
  /// Throws an [AssertionError] if the component is accessed before
  /// being added to an object via [GameObject.addComponent].
  GameObject get gameObject {
    assert(_gameObject != null, 'Component is not added to a GameObject');
    return _gameObject!;
  }

  /// Whether this component is currently attached to a [GameObject].
  ///
  /// This is used to guard against accessing [gameObject] or other
  /// dependent properties during the transitional period before
  /// attachment is finalized.
  bool get isAttached => _gameObject != null;

  /// The [GameEngine] instance this component belongs to.
  ///
  /// This is retrieved via the parent [gameObject]. It provides access
  /// to the core systems like [physics], [audio], and [input].
  GameEngine get game => gameObject.game;

  /// Access to the global [KeyboardState] for input handling.
  ///
  /// This is a convenience shortcut for `game.input.keyboard`. Use it
  /// to check for key presses during update loops.
  KeyboardState get keyboard => game.input.keyboard;

  /// The time elapsed since the last frame, in seconds.
  ///
  /// This value is vital for frame-rate independent movement. It is
  /// updated every frame by the [TickerState].
  double get deltaTime => game.ticker.deltaTime;

  /// The total number of frames processed by the engine.
  ///
  /// This monotonic counter can be used for staggered animations or
  /// simple frame-based timers.
  int get frameCount => game.ticker.frameCount;

  /// The name of the parent [GameObject].
  ///
  /// This is primarily used for debugging and identification within
  /// the scene hierarchy.
  String get name => gameObject.name;

  /// Retrieves a [GameState] component of type [T] from the parent object.
  ///
  /// This is an optimized proxy for `gameObject.getComponent<T>()` used
  /// to fetch shared state containers from the hierarchy.
  T stateObject<T extends GameState>() {
    return gameObject.getComponent<T>();
  }

  /// The metadata tag of the parent [GameObject].
  ///
  /// Tags are used for broad categorization of objects (e.g., 'Player', 'Enemy')
  /// during collision filtering or searching.
  Object? get tag => gameObject.tag;

  /// Whether the parent [GameObject] is currently active in the scene.
  ///
  /// Inactive objects do not broadcast events and are generally
  /// ignored by engine systems.
  bool get active => gameObject.active;

  /// The top-most [GameObject] in the current hierarchy.
  ///
  /// Traverses up the [parentObject] chain until a root is reached.
  GameObject get rootObject => gameObject.rootObject;

  /// The parent [GameObject] in the hierarchy, if any.
  ///
  /// Returns null if this component is attached to a root object.
  GameObject? get parentObject => gameObject.parentObject;

  /// An iterable of all child [GameObject]s.
  ///
  /// This provides direct access to the immediate children of the
  /// parent [gameObject].
  Iterable<GameObject> get childrenObjects => gameObject.childrenObjects;

  /// An iterable of all [Component]s attached to the parent [GameObject].
  ///
  /// This includes the current component instance itself.
  Iterable<Component> get components => gameObject.components;

  /// Adds new components to the parent [GameObject].
  ///
  /// This method supports adding up to 11 components in a single call
  /// for efficiency. Each component will be attached to the [gameObject]
  /// and initialized in the order they are provided.
  ///
  /// * [component] The primary component to add.
  /// * [a] through [j] Optional additional components to add.
  void addComponent(
    Component component, [
    Component? a,
    Component? b,
    Component? c,
    Component? d,
    Component? e,
    Component? f,
    Component? g,
    Component? h,
    Component? i,
    Component? j,
  ]) {
    gameObject.addComponent(component, a, b, c, d, e, f, g, h, i, j);
  }

  /// Removes components from the parent [GameObject].
  ///
  /// If a component is not found on the object, it is silently ignored.
  /// Removed components are detached and will no longer receive events.
  ///
  /// * [component] The primary component to remove.
  /// * [a] through [j] Optional additional components to remove.
  void removeComponent(
    Component component, [
    Component? a,
    Component? b,
    Component? c,
    Component? d,
    Component? e,
    Component? f,
    Component? g,
    Component? h,
    Component? i,
    Component? j,
  ]) {
    gameObject.removeComponent(component, a, b, c, d, e, f, g, h, i, j);
  }

  /// Broadcasts an event to the entire hierarchy starting from the parent object.
  ///
  /// This uses a recursive double-dispatch mechanism to notify every
  /// component in the tree that implements the event's target listener type.
  ///
  /// * [event] The event to broadcast.
  void broadcastEvent(Event event) {
    gameObject.broadcastEvent(event);
  }

  /// Sends an event only to components attached to the parent [GameObject].
  ///
  /// Unlike [broadcastEvent], this does not traverse children or parents.
  /// It is used for localized communication between components on the
  /// same object.
  ///
  /// * [event] The event to send.
  void sendEvent(Event event) {
    gameObject.sendEvent(event);
  }

  /// Finds the first component of type [T] on the parent [GameObject].
  ///
  /// Throws a [StateError] if no component of type [T] exists. Use
  /// [tryGetComponent] if the presence of the component is uncertain.
  T getComponent<T extends Component>() {
    return gameObject.getComponent<T>();
  }

  /// Attempts to find a component of type [T], returning null if not found.
  ///
  /// This is the safe version of [getComponent] and should be used
  /// when a component is optional.
  T? tryGetComponent<T extends Component>() {
    return gameObject.tryGetComponent<T>();
  }

  /// Finds all components of type [T] on the parent [GameObject].
  ///
  /// Useful for multi-purpose components like colliders or visual effects.
  Iterable<T> getComponents<T extends Component>() {
    return gameObject.getComponents<T>();
  }

  /// Recursively finds all components of type [T] in the children hierarchy.
  ///
  /// This performs a depth-first traversal of the children tree. It can
  /// be performance-heavy for very deep hierarchies.
  Iterable<T> getComponentsInChildren<T extends Component>() {
    return gameObject.getComponentsInChildren<T>();
  }

  /// Finds the first component of type [T] in the parent hierarchy.
  ///
  /// Traverses up the tree toward the root. Throws a [StateError] if
  /// not found.
  T getComponentInParent<T extends Component>() {
    return gameObject.getComponentInParent<T>();
  }

  /// Attempts to find a component of type [T] in the parent hierarchy.
  ///
  /// Traverses up the tree and returns null if no component is found
  /// before reaching the root.
  T? tryGetComponentInParent<T extends Component>() {
    return gameObject.tryGetComponentInParent<T>();
  }

  /// Finds the first component of type [T] in the children hierarchy.
  ///
  /// Performs a depth-first search. Throws a [StateError] if not found.
  T getComponentInChildren<T extends Component>() {
    return gameObject.getComponentInChildren<T>();
  }

  /// Attempts to find the first component of type [T] in the children hierarchy.
  ///
  /// Performs a depth-first search and returns null if nothing is found.
  T? tryGetComponentInChildren<T extends Component>() {
    return gameObject.tryGetComponentInChildren<T>();
  }

  /// Finds all components of type [T] in the parent hierarchy.
  ///
  /// Traverses up to the root, collecting all matching instances.
  Iterable<T> getComponentsInParent<T extends Component>() {
    return gameObject.getComponentsInParent<T>();
  }

  /// Finds a child [GameObject] by name.
  ///
  /// Only searches immediate children. Returns null if no child
  /// matches the name.
  ///
  /// * [name] The name of the child to search for.
  GameObject? findChild(String name) {
    return gameObject.findChild(name);
  }

  /// Starts a coroutine on the parent [GameObject].
  ///
  /// Coroutines are tied to the lifecycle of the object. If the object
  /// is disposed, the coroutine is automatically stopped.
  ///
  /// * [coroutine] The async* generator function to run.
  Future<void> startCoroutine(CoroutineFunction coroutine) {
    return gameObject.startCoroutine(coroutine);
  }

  /// Starts a coroutine with options on the parent [GameObject].
  ///
  /// This allows passing data to the coroutine generator while
  /// maintaining lifecycle management.
  ///
  /// * [coroutine] The async* generator function.
  /// * [option] The data to pass to the coroutine.
  Future<void> startCoroutineWithOption<T>(
    CoroutineFunctionWithOptions<T> coroutine, {
    required T option,
  }) {
    return gameObject.startCoroutineWithOption<T>(coroutine, option: option);
  }

  /// Stops a specific running coroutine.
  ///
  /// * [coroutine] The [Future] returned by [startCoroutine].
  void stopCoroutine(Future<void> coroutine) {
    gameObject.stopCoroutine(coroutine);
  }

  /// Stops all coroutines or those of a specific type.
  ///
  /// * [coroutine] Optional function to filter which coroutines to stop.
  void stopAllCoroutines([Function? coroutine]) {
    gameObject.stopAllCoroutines(coroutine);
  }

  /// Lifecycle hook called during Flutter's reassemble (hot reload).
  ///
  /// This is triggered when the code is updated during development.
  /// Components should override this to re-fetch assets, clear caches,
  /// or reset state that might have been corrupted by code changes.
  @mustCallSuper
  void onHotReload() {}
}

/// A specialized [Component] that can be toggled on or off.
///
/// [Behavior] components are the primary way to implement game logic
/// that needs to react to engine events. When [enabled] is false,
/// the behavior will stop receiving broadcasted events (like Tick or Paint)
/// because the event system specifically checks this flag.
///
/// Unlike a raw [Component], which is always "listening" if it matches
/// a listener type, a [Behavior] provides a standard way to pause logic
/// without removing the component from the object.
///
/// ```dart
/// class Rotator extends Behavior {
///   @override
///   void onTick(double dt) {
///     // Only rotates if enabled is true
///     gameObject.transform.rotation += 1.0 * dt;
///   }
/// }
/// ```
abstract class Behavior extends Component {
  /// Whether the behavior is active and receiving events.
  ///
  /// Default is true. When set to false, the [Event] dispatching
  /// system will skip this component during [Event.dispatchTo].
  bool enabled = true;
}
