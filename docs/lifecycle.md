# Lifecycle and Coroutines

Understanding how objects and components are created, updated, and destroyed is critical to mastering Goo2D.

## Component Lifecycle

When a `Component` is added to a `GameObject` that is currently active (mounted in the Flutter tree), or when the `GameObject` itself is mounted, the component goes through its lifecycle.

You can hook into this by mixing in `LifecycleListener`:

```dart
class MyComponent extends Component with LifecycleListener {
  @override
  void onMounted() {
    print('Added to the game!');
  }

  @override
  void onUnmounted() {
    print('Removed from the game!');
  }
}
```

### GameState Lifecycle

Since `GameState` is also a `Component`, it supports `LifecycleListener`. However, it also provides specific hooks that mirror Flutter's `State` lifecycle:

- `initState()`: Called once when the state is created and mounted. Always call `super.initState()`.
- `didUpdateWidget(T oldWidget)`: Called when the parent widget is rebuilt with new configuration.
- `didChangeDependencies()`: Called when an `InheritedWidget` this state depends on changes.
- `dispose()`: Called when the state is removed permanently. Always call `super.dispose()`.
- `build(BuildContext context)`: Optional. Override this to yield child `GameObject` widgets.

```dart
class MyState extends GameState<MyWidget> {
  @override
  void initState() {
    super.initState();
    // Add components here
    addComponent(MyComponent());
  }
  
  @override
  void dispose() {
    // Cleanup logic
    super.dispose();
  }
}
```

## Ticking (The Game Loop)

Goo2D drives logic using a continuous game loop provided by `GameTicker`. Once per frame, `GameTicker` calculates the delta time (`dt`) in seconds and broadcasts various events in a specific order:

1. **Fixed Update (`FixedTickable`)**: Runs based on an accumulator. It may run zero, one, or multiple times per frame to catch up to the `fixedDeltaTime` (default 50Hz / 0.02s). Ideal for deterministic logic.
2. **Update (`Tickable`)**: Runs exactly once per frame. Ideal for general game logic and reading input.
3. **Collisions & Screen Bounds**: Centralized collision passes run here.
4. **Late Update (`LateTickable`)**: Runs exactly once per frame, after all other updates and collisions. Ideal for camera follow logic to ensure it tracks the finalized position of the player.

To hook into these phases, mix the appropriate listener into your `Component` or `GameState`:

```dart
class MovementComponent extends Component with FixedTickable, Tickable, LateTickable {
  double speed = 100.0;

  @override
  void onFixedUpdate(double dt) {
    // Deterministic fixed step
  }

  @override
  void onUpdate(double dt) {
    // Normal frame-rate dependent step
    final transform = getComponent<ObjectTransform>();
    transform.position += Offset(speed * dt, 0);
  }

  @override
  void onLateUpdate(double dt) {
    // Clean up / follow target after everything else has moved
  }
}
```

You can adjust the global fixed time step at any point:
```dart
import 'package:goo2d/goo2d.dart';

void main() {
  fixedDeltaTime = 0.016; // Change to 60Hz
}
```

## Coroutines (`Behavior`)

Writing asynchronous game logic (like waiting for a timer, or waiting for a specific event to happen) can be messy with standard async/await, because Flutter's `Future`s don't respect the game's clock or lifecycle natively.

Goo2D solves this with `Behavior` components and Coroutines.

A `Behavior` is a special `Component` that provides the `startCoroutine` method. A coroutine is a Dart `Stream` generator (using `sync*` or `async*`) that yields `YieldInstruction`s. 

### Starting a Coroutine

```dart
class EnemySpawner extends Behavior with LifecycleListener {
  @override
  void onMounted() {
    startCoroutine(spawnEnemies);
  }

  Stream spawnEnemies() async* {
    while (true) {
      // Wait for 2 seconds (using game time)
      yield WaitForSeconds(2.0);
      
      print("Spawned an enemy!");
      
      // Yielding null waits exactly 1 frame
      yield null; 
    }
  }
}
```

### Stopping Coroutines

If the `Behavior` is unmounted, its coroutines are automatically orphaned, but it's good practice to manage them if you need to cancel them early.

```dart
final routine = startCoroutine(myRoutine);
stopCoroutine(routine);
// or
stopAllCoroutines();
```

### Yield Instructions

Goo2D provides several built-in yield instructions:

- `WaitForSeconds(double seconds)`: Suspends the coroutine for the given duration.
- `WaitForEndOfFrame()`: Suspends until the end of the current `GameTicker` pass.
- `WaitUntil(bool Function() predicate)`: Suspends until the predicate returns `true`. Evaluated every frame.
- `WaitWhile(bool Function() predicate)`: Suspends while the predicate returns `true`. Evaluated every frame.
- `yield null`: Suspends for exactly one frame.
- You can also yield standard Dart `Future`s and `Stream`s.
