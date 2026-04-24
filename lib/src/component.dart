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
    return gameObject as T;
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
}

typedef CoroutineFunction = Stream Function();
typedef CoroutineFunctionWithOptions<T> = Stream Function(T option);

const _currentCoroutineKey = Object();

Future<void> get currentCoroutine {
  final coroutine = Zone.current[_currentCoroutineKey];
  assert(
    coroutine is _CoroutineFuture,
    'Not in a coroutine. Start a coroutine with startCoroutine()',
  );
  return coroutine as _CoroutineFuture;
}

class _CoroutineFuture implements Future<void> {
  late Future<void> delegate;
  final Object coroutine;

  _CoroutineFuture(this.coroutine);

  @override
  Stream<void> asStream() {
    return delegate.asStream();
  }

  @override
  Future<void> catchError(
    Function onError, {
    bool Function(Object error)? test,
  }) {
    return delegate.catchError(onError, test: test);
  }

  @override
  Future<R> then<R>(
    FutureOr<R> Function(void value) onValue, {
    Function? onError,
  }) {
    return delegate.then(onValue, onError: onError);
  }

  @override
  Future<void> timeout(
    Duration timeLimit, {
    FutureOr<dynamic> Function()? onTimeout,
  }) {
    return delegate.timeout(timeLimit, onTimeout: onTimeout);
  }

  @override
  Future<void> whenComplete(FutureOr<dynamic> Function() action) {
    return delegate.whenComplete(action);
  }
}

abstract class Behavior extends Component {
  bool enabled = true;

  final List<_CoroutineFuture> _runningCoroutines = [];

  Future<void> startCoroutine(CoroutineFunction coroutine) {
    _CoroutineFuture result = _CoroutineFuture(coroutine);
    result.delegate = Future(() async {
      _runningCoroutines.add(result);
      await runZoned(() async {
        final yields = coroutine();
        await for (final instruction in yields) {
          if (!_runningCoroutines.contains(result)) break;

          switch (instruction) {
            case YieldInstruction():
              await instruction.wait();
              break;
            case Future():
              await instruction;
              break;
            case Stream():
              await for (final _ in instruction) {}
              break;
            case null:
              await GameTicker.nextFrame;
              break;
          }
        }
      }, zoneValues: {_currentCoroutineKey: result});
      _runningCoroutines.remove(result);
    });
    return result;
  }

  Future<void> startCoroutineWithOption<T>(
    CoroutineFunctionWithOptions<T> coroutine, {
    required T option,
  }) {
    _CoroutineFuture result = _CoroutineFuture(coroutine);
    result.delegate = Future(() async {
      _runningCoroutines.add(result);
      await runZoned(() async {
        final yields = coroutine(option);
        await for (final instruction in yields) {
          if (!_runningCoroutines.contains(result)) break;

          if (instruction is YieldInstruction) {
            await instruction.wait();
          } else if (instruction == null) {
            await GameTicker.nextFrame;
          }
        }
      }, zoneValues: {_currentCoroutineKey: result});
      _runningCoroutines.remove(result);
    });
    return result;
  }

  void stopCoroutine(Future<void> coroutine) {
    _runningCoroutines.remove(coroutine);
  }

  void stopAllCoroutines([Function? coroutine]) {
    if (coroutine != null) {
      _runningCoroutines.removeWhere((e) => e.coroutine == coroutine);
    } else {
      _runningCoroutines.clear();
    }
  }
}

abstract class YieldInstruction {
  Future<void> wait();
}

class WaitForSeconds extends YieldInstruction {
  final double seconds;

  WaitForSeconds(this.seconds);

  @override
  Future<void> wait() async {
    await Future.delayed(Duration(milliseconds: (seconds * 1000).toInt()));
  }
}

class WaitForEndOfFrame extends YieldInstruction {
  @override
  Future<void> wait() async {
    await GameTicker.nextFrame;
  }
}

class WaitUntil extends YieldInstruction {
  final bool Function() predicate;

  WaitUntil(this.predicate);

  @override
  Future<void> wait() async {
    while (!predicate()) {
      await GameTicker.nextFrame;
    }
  }
}

class WaitWhile extends YieldInstruction {
  final bool Function() predicate;

  WaitWhile(this.predicate);

  @override
  Future<void> wait() async {
    while (predicate()) {
      await GameTicker.nextFrame;
    }
  }
}
