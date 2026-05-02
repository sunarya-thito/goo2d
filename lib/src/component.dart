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

mixin _FakeComponentFuture<T extends Component>
    implements Future<ComponentFactory<T>> {
  T _create();
  @override
  Stream<ComponentFactory<T>> asStream() {
    return Stream.value(_create);
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
    return Future.value(onValue(_create));
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

class ComponentFactoryWithParams<T extends Component>
    with _FakeComponentFuture<T> {
  // we implement Future so that we can use FutureOr type-union
  final ComponentFactory<T> factory;
  final ComponentParameterHandler<T>? params;

  ComponentFactoryWithParams(this.factory, {this.params});

  @override
  T _create() {
    final component = factory();
    params?.call(component);
    return component;
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

typedef ComponentFactory<T extends Component> = T Function();
typedef ComponentParameterHandler<T extends Component> =
    void Function(T component);

class ComponentWidget<T extends Component> extends Widget {
  final GameComponent<T> factory;
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
      case _FakeComponentFuture<T> withParams:
        _registration = _ComponentRegistration(
          component: widget.apply(withParams._create()),
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

mixin MultiComponent on Component {}

abstract class Component {
  GameObject? _gameObject;
  GameObject get gameObject {
    assert(_gameObject != null, 'Component is not added to a GameObject');
    return _gameObject!;
  }

  GameObject? get tryGameObject => _gameObject;
  @internal
  void internalAttach(GameObject gameObject) {
    _gameObject = gameObject;
  }

  @internal
  void internalDetach() {
    _gameObject = null;
  }

  bool get isAttached => _gameObject != null;
  GameEngine get game => gameObject.game;
  KeyboardState? get keyboard => game.getSystem<InputSystem>()?.keyboard;
  double get deltaTime => game.getSystem<TickerState>()?.deltaTime ?? 0.0;
  int get frameCount => game.getSystem<TickerState>()?.frameCount ?? 0;
  String get name => gameObject.name;
  T stateObject<T extends GameState>() {
    return gameObject.getComponent<T>();
  }

  Object? get tag => gameObject.tag;
  bool get active => gameObject.active;
  GameObject get rootObject => gameObject.rootObject;
  GameObject? get parentObject => gameObject.parentObject;
  Iterable<GameObject> get childrenObjects => gameObject.childrenObjects;
  Iterable<Component> get components => gameObject.components;
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
  void removeComponentOfType<T extends Component>() =>
      gameObject.removeComponentOfType<T>();
  void addComponents(Iterable<Component> components) =>
      gameObject.addComponents(components);
  void removeComponents(Iterable<Type> types) =>
      gameObject.removeComponents(types);
  void broadcastEvent(Event event) {
    gameObject.broadcastEvent(event);
  }

  void sendEvent(Event event) {
    gameObject.sendEvent(event);
  }

  T getComponent<T extends Component>() {
    return gameObject.getComponent<T>();
  }

  T? tryGetComponent<T extends Component>() {
    return gameObject.tryGetComponent<T>();
  }

  Iterable<T> getComponents<T extends Component>() {
    return gameObject.getComponents<T>();
  }

  Iterable<T> getComponentsInChildren<T extends Component>() {
    return gameObject.getComponentsInChildren<T>();
  }

  T getComponentInParent<T extends Component>() {
    return gameObject.getComponentInParent<T>();
  }

  T? tryGetComponentInParent<T extends Component>() {
    return gameObject.tryGetComponentInParent<T>();
  }

  T getComponentInChildren<T extends Component>() {
    return gameObject.getComponentInChildren<T>();
  }

  T? tryGetComponentInChildren<T extends Component>() {
    return gameObject.tryGetComponentInChildren<T>();
  }

  Iterable<T> getComponentsInParent<T extends Component>() {
    return gameObject.getComponentsInParent<T>();
  }

  GameObject? findChild(String name) {
    return gameObject.findChild(name);
  }

  Future<void> startCoroutine(CoroutineFunction coroutine) {
    return gameObject.startCoroutine(coroutine);
  }

  Future<void> startCoroutineWithOption<T>(
    CoroutineFunctionWithOptions<T> coroutine, {
    required T option,
  }) {
    return gameObject.startCoroutineWithOption<T>(coroutine, option: option);
  }

  void stopCoroutine(Future<void> coroutine) {
    gameObject.stopCoroutine(coroutine);
  }

  void stopAllCoroutines([Function? coroutine]) {
    gameObject.stopAllCoroutines(coroutine);
  }
}

abstract class Behavior extends Component {
  bool enabled = true;
}
