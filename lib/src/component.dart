import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:goo2d/goo2d.dart';

@internal
void internalAttach(Component component, GameObject gameObject) {
  component._gameObject = gameObject;
}

T lerp<T>(T a, T b, double t) {
  // convert a and b to dynamic, assuming they overload the operator
  return ((a as dynamic) + ((b as dynamic) - (a as dynamic)) * t) as T;
}

abstract class Component {
  GameObject? _gameObject;

  GameObject get gameObject {
    assert(_gameObject != null, 'Component is not added to a GameObject');
    return _gameObject!;
  }

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
  ]) {
    gameObject.addComponent(component, a, b, c, d, e, f, g, h, i, j);
  }

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
