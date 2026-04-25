import 'dart:async';
import 'package:goo2d/goo2d.dart';
import 'package:meta/meta.dart';

typedef CoroutineFunction = Stream Function();
typedef CoroutineFunctionWithOptions<T> = Stream Function(T option);

const _currentCoroutineKey = Object();

Future<void> get currentCoroutine {
  final coroutine = Zone.current[_currentCoroutineKey];
  assert(
    coroutine is CoroutineFuture,
    'Not in a coroutine. Start a coroutine with startCoroutine()',
  );
  return coroutine as CoroutineFuture;
}

@internal
class CoroutineFuture implements Future<void> {
  late Future<void> delegate;
  final Object coroutine;

  CoroutineFuture(this.coroutine);

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

@internal
extension CoroutineInternal on GameObject {
  void setupCoroutine(CoroutineFuture result, Stream yields, List<CoroutineFuture> runningCoroutines) {
    result.delegate = Future(() async {
      runningCoroutines.add(result);
      await runZoned(() async {
        await for (final instruction in yields) {
          if (!runningCoroutines.contains(result)) break;

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
      runningCoroutines.remove(result);
    });
  }
}
