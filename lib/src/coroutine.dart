import 'dart:async';
import 'package:goo2d/goo2d.dart';
import 'package:meta/meta.dart';

/// A function signature for coroutines that execute logic over multiple frames.
///
/// Coroutines use Dart's [Stream] as a sequence of yield instructions. Each
/// yielded value (e.g., [YieldInstruction], [Future], or null) determines
/// how long the engine should wait before resuming the coroutine logic.
typedef CoroutineFunction = Stream Function();

/// A function signature for coroutines that accept initial configuration data.
///
/// This allows for reusable coroutine logic that depends on external state
/// (e.g., a fade effect that needs a target duration and opacity).
///
/// * [T]: The type of the option object passed to the coroutine.
typedef CoroutineFunctionWithOptions<T> = Stream Function(T option);

const _currentCoroutineKey = Object();
/// Accesses the [Future] of the currently executing coroutine.
///
/// This is used within a coroutine to identify its own lifecycle or to
/// wait for its completion recursively. It utilizes [Zone] values to
/// track the execution context.
///
/// Throws an assertion error if called outside of a coroutine context.
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

/// The base class for all instructions that pause a coroutine's execution.
///
/// Yield instructions allow developers to express complex timing and
/// synchronization logic in a linear, readable way within a [Stream]-based
/// coroutine.
///
/// ```dart
/// class MyWait extends YieldInstruction {
///   @override
///   Future<void> wait(GameEngine game) async {
///     // Custom wait logic
///   }
/// }
/// ```
///
/// See also:
/// * [WaitForSeconds], for time-based pauses.
/// * [WaitForEndOfFrame], for frame-synchronization.
abstract class YieldInstruction {
  /// Internal method used by the engine to wait for the instruction's condition.
  ///
  /// * [game]: The engine instance providing timing and frame context.
  Future<void> wait(GameEngine game);
}

/// A yield instruction that pauses a coroutine for a specific duration.
///
/// Use this for non-precise delays like waiting for an animation to finish
/// or staggering enemy spawns.
///
/// ```dart
/// Stream example() async* {
///   print('Wait start');
///   yield WaitForSeconds(2.5);
///   print('2.5 seconds later');
/// }
/// ```
///
/// See also:
/// * [WaitForEndOfFrame], for frame-by-frame precision.
class WaitForSeconds extends YieldInstruction {
  /// The duration to wait, in seconds.
  ///
  /// This value is used to calculate the millisecond delay passed to the
  /// underlying async timer.
  final double seconds;

  /// Creates an instruction that waits for the specified [seconds].
  ///
  /// * [seconds]: The duration of the pause.
  WaitForSeconds(this.seconds);

  @override
  Future<void> wait(GameEngine game) async {
    await Future.delayed(Duration(milliseconds: (seconds * 1000).toInt()));
  }
}

/// A yield instruction that pauses a coroutine until the next frame is rendered.
///
/// This is used to synchronize logic with the engine's main render loop,
/// ensuring that calculations happen once per frame.
///
/// ```dart
/// Stream example() async* {
///   while(true) {
///     yield WaitForEndOfFrame();
///     print('Next frame reached');
///   }
/// }
/// ```
///
/// See also:
/// * [WaitForSeconds], for time-based pauses.
class WaitForEndOfFrame extends YieldInstruction {
  @override
  Future<void> wait(GameEngine game) async {
    await game.ticker.nextFrame;
  }
}

/// A yield instruction that pauses until a specific condition becomes true.
///
/// This is useful for waiting for external events or state changes without
/// manually checking every frame.
///
/// ```dart
/// bool playerIsDead = false;
/// Stream example() async* {
///   yield WaitUntil(() => playerIsDead);
///   print('Game Over');
/// }
/// ```
///
/// See also:
/// * [WaitWhile], the inverse of this instruction.
class WaitUntil extends YieldInstruction {
  /// The condition to check every frame.
  ///
  /// The coroutine will remain suspended as long as this function returns
  /// false, checking it once per frame update.
  final bool Function() predicate;

  /// Creates an instruction that waits until the [predicate] returns true.
  ///
  /// * [predicate]: The condition function.
  WaitUntil(this.predicate);

  @override
  Future<void> wait(GameEngine game) async {
    while (!predicate()) {
      await game.ticker.nextFrame;
    }
  }
}

/// A yield instruction that pauses as long as a specific condition remains true.
///
/// This is used to stall a coroutine while a certain state persists (e.g.,
/// waiting for a loading screen to close).
///
/// ```dart
/// bool isLoading = true;
/// Stream example() async* {
///   yield WaitWhile(() => isLoading);
///   print('Loading complete');
/// }
/// ```
///
/// See also:
/// * [WaitUntil], which waits for a condition to become true.
class WaitWhile extends YieldInstruction {
  /// The condition to check every frame.
  ///
  /// The coroutine will remain suspended as long as this function returns
  /// true, checking it once per frame update.
  final bool Function() predicate;

  /// Creates an instruction that waits while the [predicate] returns true.
  ///
  /// * [predicate]: The condition function.
  WaitWhile(this.predicate);

  @override
  Future<void> wait(GameEngine game) async {
    while (predicate()) {
      await game.ticker.nextFrame;
    }
  }
}

@internal
extension CoroutineInternal on GameObject {
  void setupCoroutine(
    CoroutineFuture result,
    Stream yields,
    List<CoroutineFuture> runningCoroutines,
  ) {
    final g = game;
    result.delegate = Future(() async {
      runningCoroutines.add(result);
      await runZoned(() async {
        Future<void> processYields(Stream stream) async {
          await for (final instruction in stream) {
            if (!runningCoroutines.contains(result)) break;

            switch (instruction) {
              case YieldInstruction():
                await instruction.wait(g);
                break;
              case Future():
                await instruction;
                break;
              case Stream():
                await processYields(instruction);
                break;
              case null:
                try {
                  await g.ticker.nextFrame;
                } catch (_) {
                  // Engine disposed
                  return;
                }
                break;
            }
            if (!runningCoroutines.contains(result)) break;
          }
        }

        await processYields(yields);
      }, zoneValues: {_currentCoroutineKey: result});
      runningCoroutines.remove(result);
    });
  }
}
