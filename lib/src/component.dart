import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:goo2d/src/object.dart';
import 'package:goo2d/src/event.dart';
import 'package:goo2d/src/input.dart';
import 'package:goo2d/src/game.dart';
import 'package:goo2d/src/coroutine.dart';
import 'package:goo2d/src/element.dart';
import 'package:meta/meta.dart';

typedef GameComponent<T extends Component> = FutureOr<ComponentFactory<T>>;

class ComponentFactoryWithParams<T extends Component>
    implements Future<ComponentFactory<T>> {
  // we implement Future so that we can use FutureOr type-union
  final ComponentFactory<T> factory;
  final ComponentParameterHandler<T>? params;

  ComponentFactoryWithParams(this.factory, {this.params});

  T create() {
    final component = factory();
    params?.call(component);
    return component;
  }

  @override
  Stream<ComponentFactory<T>> asStream() {
    return Stream.value(create);
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
    return Future.value(onValue(create));
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
    action();
    return this;
  }
}

extension ComponentFactoryExtension<T extends Component>
    on ComponentFactory<T> {
  ComponentFactoryWithParams<T> withInitialValues(
    ComponentParameterHandler<T> params,
  ) {
    return ComponentFactoryWithParams<T>(this, params: params);
  }
}

/// A function signature that creates a [Component] instance of type [T].
///
/// Used as a blueprint for component instantiation.
typedef ComponentFactory<T extends Component> = T Function();

/// A function signature for configuring a [Component] instance after creation.
///
/// Provides a hook for dependency injection and property setting.
typedef ComponentParameterHandler<T extends Component> =
    void Function(T component);

/// Private implementation of [ComponentFuture].
///
/// [ComponentWidget] stores the base factory and any configuration
/// parameters to be applied during the creation process. It is used
/// by the [ComponentFactoryExtension] to build configuration chains.
///
/// ```dart
/// final cf = _ComponentFactoryOf(myFactory, myParams);
/// ```
class ComponentWidget<T extends Component> extends Widget {
  /// The function that creates the component instance.
  ///
  /// This factory is invoked by the engine when the component needs to
  /// be instantiated during a [GameObject] addition pass.
  final GameComponent<T> factory;

  /// The optional callback for configuring the component.
  ///
  /// If provided, this handler is executed immediately after the
  /// [factory] creates the instance, allowing for parameter injection.
  final ComponentParameterHandler<T>? update;

  const ComponentWidget(this.factory, {super.key, this.update});

  T apply(T component) {
    update?.call(component);
    return component;
  }

  @override
  Element createElement() {
    return _ComponentElement(this);
  }
}

class _ComponentRegistration<T extends Component> {
  final T component;
  GameObject? gameObject;
  _ComponentRegistration({required this.component, required this.gameObject}) {
    gameObject?.addComponent(component);
  }

  void reparent(GameObject newGameObject) {
    if (newGameObject == gameObject) return;
    gameObject?.removeComponent(component);
    newGameObject.addComponent(component);
    gameObject = newGameObject;
  }

  void remove() {
    gameObject?.removeComponent(component);
    gameObject = null;
  }
}

class _ComponentElement<T extends Component> extends Element {
  _ComponentElement(ComponentWidget super.widget);

  @override
  ComponentWidget<T> get widget => super.widget as ComponentWidget<T>;

  FutureOr<_ComponentRegistration<T>>? _registration;

  GameObject? _findParentGameObject(Element? parent) {
    if (parent is GameObject) return parent as GameObject;
    if (parent == null) return null;
    GameObject? found;
    parent.visitAncestorElements((element) {
      if (element is GameObject) {
        found = element as GameObject;
        return false;
      }
      return true;
    });
    return found;
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    final gameObject = _findParentGameObject(parent);
    assert(
      gameObject != null,
      'Component $widget must be added to a GameObject.',
    );
    switch (widget.factory) {
      case ComponentFactoryWithParams<T> withParams:
        _registration = _ComponentRegistration(
          component: widget.apply(withParams.create()),
          gameObject: gameObject!,
        );
        break;
      case Future<ComponentFactory<T>> future:
        _registration = future.then(
          (factory) => _registration = _ComponentRegistration(
            component: widget.apply(factory()),
            gameObject: gameObject!,
          ),
        );
        break;
      case ComponentFactory<T> factory:
        _registration = _ComponentRegistration(
          component: widget.apply(factory()),
          gameObject: gameObject!,
        );
        break;
    }
  }

  @override
  void activate() {
    super.activate();
    assert(
      _registration != null,
      'Component has not been registered previously',
    );
    final gameObject = _findParentGameObject(this);
    assert(
      gameObject != null,
      'Component $widget must be added to a GameObject.',
    );
    switch (_registration) {
      case _ComponentRegistration<T> registration:
        registration.reparent(gameObject!);
        break;
      case Future<_ComponentRegistration<T>> future:
        _registration = future.then((registration) {
          _registration = registration;
          registration.reparent(gameObject!);
          return registration;
        });
        break;
    }
  }

  @override
  void update(covariant ComponentWidget<T> newWidget) {
    super.update(newWidget);
    assert(
      _registration != null,
      'Component has not been registered previously',
    );
    switch (_registration) {
      case _ComponentRegistration<T> registration:
        newWidget.apply(registration.component);
        break;
      case Future<_ComponentRegistration<T>> future:
        _registration = future.then((registration) {
          _registration = registration;
          newWidget.apply(registration.component);
          return registration;
        });
        break;
    }
  }

  @override
  void deactivate() {
    assert(
      _registration != null,
      'Component has not been registered previously',
    );
    switch (_registration) {
      case _ComponentRegistration<T> registration:
        registration.remove();
        break;
      case Future<_ComponentRegistration<T>> future:
        _registration = future.then((registration) {
          _registration = registration;
          registration.remove();
          return registration;
        });
        break;
    }
    super.deactivate();
  }

  @override
  void unmount() {
    assert(
      _registration != null,
      'Component has not been registered previously',
    );
    switch (_registration) {
      case _ComponentRegistration<T> registration:
        registration.remove();
        break;
      case Future<_ComponentRegistration<T>> future:
        _registration = future.then((registration) {
          _registration = registration;
          registration.remove();
          return registration;
        });
        break;
    }
    super.unmount();
  }

  @override
  bool get debugDoingBuild => false;
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
/// A mixin that marks a [Component] as allowing multiple instances on the same [GameObject].
///
/// By default, [GameObject] prevents adding multiple components of the same
/// runtime type to avoid unintended behavior and optimize lookups.
/// Components that need to support multiple instances (like colliders)
/// should implement this mixin.
mixin MultiComponent on Component {}

abstract class Component {
  GameObject? _gameObject;

  /// The [GameObject] this component is currently attached to.
  GameObject get gameObject {
    assert(_gameObject != null, 'Component is not added to a GameObject');
    return _gameObject!;
  }

  /// Attempts to get the [GameObject] this component is attached to, or null if detached.
  GameObject? get tryGameObject => _gameObject;

  /// Internal method to attach this component to a [GameObject].
  @internal
  void internalAttach(GameObject gameObject) {
    _gameObject = gameObject;
  }

  /// Internal method to detach this component from its [GameObject].
  @internal
  void internalDetach() {
    _gameObject = null;
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

  /// Adds one or more components to this object.
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
  ]) => gameObject.addComponent(component, a, b, c, d, e, f, g, h, i, j);

  /// Removes one or more component instances from this object.
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
  ]) => gameObject.removeComponent(component, a, b, c, d, e, f, g, h, i, j);

  /// Removes one or more components of the exact specified runtime types.
  void removeComponentOfExactType(
    Type type, [
    Type? a,
    Type? b,
    Type? c,
    Type? d,
    Type? e,
    Type? f,
    Type? g,
    Type? h,
    Type? i,
    Type? j,
  ]) =>
      gameObject.removeComponentOfExactType(type, a, b, c, d, e, f, g, h, i, j);

  /// Removes all components of type [T] (including subclasses).
  void removeComponentOfType<T extends Component>() =>
      gameObject.removeComponentOfType<T>();

  /// Adds multiple components to this object.
  void addComponents(Iterable<Component> components) =>
      gameObject.addComponents(components);

  /// Removes all components of the specified exact runtime types.
  void removeComponents(Iterable<Type> types) =>
      gameObject.removeComponents(types);

  /// Broadcasts an event to the entire hierarchy starting from the parent object.
  ///
  /// This uses a recursive double-dispatch mechanism to notify every
  /// component in the tree that implements the event's target listener type.
  ///
  /// * [event]: The event to broadcast.
  void broadcastEvent(Event event) {
    gameObject.broadcastEvent(event);
  }

  /// Sends an event only to components attached to the parent [GameObject].
  ///
  /// Unlike [broadcastEvent], this does not traverse children or parents.
  /// It is used for localized communication between components on the
  /// same object.
  ///
  /// * [event]: The event to send.
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
  /// * [name]: The name of the child to search for.
  GameObject? findChild(String name) {
    return gameObject.findChild(name);
  }

  /// Starts a coroutine on the parent [GameObject].
  ///
  /// Coroutines are tied to the lifecycle of the object. If the object
  /// is disposed, the coroutine is automatically stopped.
  ///
  /// * [coroutine]: The async* generator function to run.
  Future<void> startCoroutine(CoroutineFunction coroutine) {
    return gameObject.startCoroutine(coroutine);
  }

  /// Starts a coroutine with options on the parent [GameObject].
  ///
  /// This allows passing data to the coroutine generator while
  /// maintaining lifecycle management.
  ///
  /// * [coroutine]: The async* generator function.
  /// * [option]: The data to pass to the coroutine.
  Future<void> startCoroutineWithOption<T>(
    CoroutineFunctionWithOptions<T> coroutine, {
    required T option,
  }) {
    return gameObject.startCoroutineWithOption<T>(coroutine, option: option);
  }

  /// Stops a specific running coroutine.
  ///
  /// Terminates the execution of the provided [coroutine] handle.
  ///
  /// * [coroutine]: The [Future] returned by [startCoroutine].
  void stopCoroutine(Future<void> coroutine) {
    gameObject.stopCoroutine(coroutine);
  }

  /// Stops all coroutines or those of a specific type.
  ///
  /// Cleans up active coroutine handles from the parent [GameObject].
  ///
  /// * [coroutine]: Optional function to filter which coroutines to stop.
  void stopAllCoroutines([Function? coroutine]) {
    gameObject.stopAllCoroutines(coroutine);
  }
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
