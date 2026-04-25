# Tutorial 4: Coroutines and Logic

In traditional Flutter development, if you want something to happen after 2 seconds, you use `Future.delayed`. But in a game, if the game is paused, or the object is destroyed, that `Future` will still execute and likely crash your app.

Goo2D solves this with **Coroutines**.

## 1. Creating a Behavior

To use coroutines, we need a component that extends `Behavior`.

Let's create a behavior that makes our `Enemy` blink every second.

```dart
class Blinker extends Behavior with LifecycleListener {
  @override
  void onMounted() {
    // Start the coroutine as soon as this component is added to the scene
    startCoroutine(blinkRoutine);
  }

  Stream blinkRoutine() async* {
    final renderer = getComponent<RectangleRenderer>();

    while (true) {
      // Wait for 1 second of game time
      yield WaitForSeconds(1.0);
      
      renderer.color = Colors.transparent;
      
      // Wait another half second
      yield WaitForSeconds(0.5);
      
      renderer.color = Colors.green;
    }
  }
}
```

## 2. Attaching the Behavior

Now, add the `Blinker` component to the `Enemy` we created in the previous tutorial:

```dart
class Enemy extends GameWidget {
  Enemy({super.key}) : super(components: () => [
    ObjectTransform()..position = const Offset(300, 300),
    BoxCollisionTrigger()..rect = const Rect.fromLTWH(0, 0, 50, 50),
    RectangleRenderer()..color = Colors.green,
    Blinker(), // ADDED
  ]);
}
```

## 3. Run the Game

Run the game, and you will see the green square blinking exactly in sync with the game loop!

Because `startCoroutine` is tied to the `Behavior` component, if you remove the `Enemy` from the scene, the `blinkRoutine` will automatically stop executing, preventing any memory leaks or state errors.

## Wrapping Up

You now know how to:
- Render objects to the screen.
- Move them with the Input System.
- Detect Collisions.
- Write safe, asynchronous game logic using Coroutines.

You have all the primitives needed to start building complex 2D games natively in Flutter with Goo2D. Happy coding!
