import 'dart:async';
import 'package:goo2d/goo2d.dart';
import 'package:meta/meta.dart';

/// A function that returns an `async*` [Stream] to be executed as a coroutine.
/// 
/// Coroutines allow for sequential-looking code that executes over multiple 
/// frames. They are driven by [YieldInstruction]s or [Future]s.
typedef CoroutineFunction = Stream Function();

/// A version of [CoroutineFunction] that accepts a parameter of type [T].
typedef CoroutineFunctionWithOptions<T> = Stream Function(T option);

const _currentCoroutineKey = Object();

/// Retrieves the [Future] representing the currently executing coroutine.
/// 
/// This allows a coroutine to await itself or check its own state. It 
/// uses the current [Zone] to identify the active coroutine handle.
/// 
/// Throws an [AssertionError] if called outside of a coroutine context.
/// 
/// ```dart
/// final me = currentCoroutine;
/// ```
Future<void> get currentCoroutine {
  final coroutine = Zone.current[_currentCoroutineKey];
  assert(
    coroutine is CoroutineFuture,
    'Not in a coroutine. Start a coroutine with startCoroutine()',
  );
  return coroutine as CoroutineFuture;
}

/// Internal wrapper for a running coroutine [Future].
/// 
/// [CoroutineFuture] implements the [Future] interface to allow awaiting 
/// the completion of a coroutine. It delegates all operations to an 
/// underlying [delegate] created by the [GameObject].
/// 
/// ```dart
/// final future = gameObject.startCoroutine(myFunc);
/// await future;
/// ```
/// 
/// See also:
/// * [GameObject.startCoroutine] for creating these futures.
@internal
class CoroutineFuture implements Future<void> {
  /// The underlying [Future] that handles the actual execution.
  /// 
  /// This delegate is created when the coroutine starts and is used 
  /// to track the asynchronous completion of the generator stream.
  late Future<void> delegate;

  /// The raw coroutine object (usually a [Stream] or [Function]).
  /// 
  /// Stores the original logic provided by the user, primarily for 
  /// identification during cancellation or debugging.
  final Object coroutine;

  /// Creates a [CoroutineFuture] for the given [coroutine].
  /// 
  /// * [coroutine]: The coroutine logic being executed.
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

/// Base class for instructions that pause coroutine execution.
/// 
/// When a coroutine yields a [YieldInstruction], the engine will wait for 
/// the instruction's [wait] future to complete before resuming the coroutine.
/// This allows for time-based, frame-based, or condition-based pauses.
/// 
/// ```dart
/// class MyWait extends YieldInstruction {
///   @override
///   Future wait(GameEngine game) async {
///     // Custom waiting logic
///   }
/// }
/// ```
abstract class YieldInstruction {
  /// Internal method called by the coroutine runner to wait for this instruction.
  /// 
  /// The coroutine remains suspended until the returned [Future] completes.
  /// 
  /// * [game]: The active game engine.
  Future<void> wait(GameEngine game);
}

/// Pauses the coroutine for a specific duration in seconds.
/// 
/// [WaitForSeconds] uses [Future.delayed] to suspend execution. Note that 
/// this is affected by the system clock and the standard Dart event loop, 
/// which may result in slight drift depending on system load.
/// 
/// ```dart
/// yield WaitForSeconds(2.0);
/// ```
/// 
/// See also:
/// * [WaitForEndOfFrame] for frame-accurate waiting.
class WaitForSeconds extends YieldInstruction {
  /// The amount of time to wait, in seconds.
  /// 
  /// This value is passed to [Future.delayed] to schedule the 
  /// resumption of the coroutine after the specified interval.
  final double seconds;

  /// Creates a [WaitForSeconds] instruction.
  /// 
  /// * [seconds]: The duration to wait.
  WaitForSeconds(this.seconds);

  @override
  Future<void> wait(GameEngine game) async {
    await Future.delayed(Duration(milliseconds: (seconds * 1000).toInt()));
  }
}

/// Pauses the coroutine until the end of the current frame.
/// 
/// This is the most efficient way to yield control to the engine 
/// while ensuring logic continues at the start of the next tick.
/// It works by awaiting the [TickerState.nextFrame] future in [TickerState].
/// 
/// ```dart
/// yield WaitForEndOfFrame();
/// ```
/// 
/// See also:
/// * [TickerState.nextFrame] which drives this instruction.
class WaitForEndOfFrame extends YieldInstruction {
  @override
  Future<void> wait(GameEngine game) async {
    await game.ticker.nextFrame;
  }
}

/// Pauses the coroutine until the [predicate] returns true.
/// 
/// [WaitUntil] polls the [predicate] function every engine frame. This 
/// is useful for waiting for specific game states or asynchronous flags.
/// 
/// ```dart
/// yield WaitUntil(() => player.isLoaded);
/// ```
/// 
/// See also:
/// * [WaitWhile] for the inverse condition.
class WaitUntil extends YieldInstruction {
  /// The condition to poll for.
  /// 
  /// Resumption occurs as soon as this function returns true during 
  /// the engine's fixed or variable update cycle.
  final bool Function() predicate;

  /// Creates a [WaitUntil] instruction.
  /// 
  /// * [predicate]: The function that determines when to resume.
  WaitUntil(this.predicate);

  @override
  Future<void> wait(GameEngine game) async {
    while (!predicate()) {
      await game.ticker.nextFrame;
    }
  }
}

/// Pauses the coroutine as long as the [predicate] returns true.
/// 
/// [WaitWhile] is the inverse of [WaitUntil]. It will suspend 
/// execution as long as the condition remains met.
/// 
/// ```dart
/// yield WaitWhile(() => enemy.isAttacking);
/// ```
/// 
/// See also:
/// * [WaitUntil] for the primary condition waiting instruction.
class WaitWhile extends YieldInstruction {
  /// The condition that keeps the coroutine paused.
  /// 
  /// Suspension continues as long as this function returns true, 
  /// polling every frame during the engine's update cycle.
  final bool Function() predicate;

  /// Creates a [WaitWhile] instruction.
  /// 
  /// * [predicate]: The function that determines the suspension state.
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
  /// Internal helper to initialize a coroutine's execution state.
  /// 
  /// This method sets up the [CoroutineFuture] delegate and starts 
  /// the asynchronous traversal of the [yields] stream within a 
  /// specialized [Zone] for identifying the active coroutine.
  /// 
  /// * [result]: The future handle that will represent this coroutine.
  /// * [yields]: The stream of instructions produced by the coroutine.
  /// * [runningCoroutines]: The list used to track active coroutines for cancellation.
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
