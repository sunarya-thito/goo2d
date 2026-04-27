---
sidebar_position: 6
---

# Cookbook: Coroutines & Sequences

Coroutines allow you to write multi-step logic in a single, linear function without blocking the main game loop. This tutorial explains how to script an animation sequence from scratch by yielding results over time.

## Assets Used

This tutorial uses assets from the [Kenney Pixel Shmup](https://kenney-assets.itch.io/pixel-shmup) pack.

| Preview | Asset | Action |
| :--- | :--- | :--- |
| ![](/img/cookbook/ship.png) | `ship.png` | [Download](/img/cookbook/ship.png) |

---

## Tutorial

### 1. Asset & Scaffolding
Set up the imports and texture definitions. We use `GameAsset.loadAll` within a `FutureBuilder` to ensure our ship sprite is ready before the game engine initializes.

```dart
import 'package:flutter/material.dart';
import 'package:goo2d/goo2d.dart';

void main() => runApp(const CoroutineExample());

enum GameTextures with AssetEnum, TextureAssetEnum {
  ship;
  @override
  AssetSource get source => AssetSource.local("assets/sprites/$name.png");
}

class CoroutineExample extends StatelessWidget {
  const CoroutineExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FutureBuilder(
        future: GameAsset.loadAll(GameTextures.values).drain(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return const Game(child: MyGameWidget());
        },
      ),
    );
  }
}
```

### 2. Defining the Behavior
Create a custom behavior class to hold the coroutine logic. We mix in `LifecycleListener` to access the `onMounted` event, which is the standard place to start a script.

```dart
class SequenceBehavior extends Behavior with LifecycleListener {
  @override
  void onMounted() {
    // startCoroutine registers the script with the engine's runner
    startCoroutine(mySequence);
  }

  // Coroutines in Goo2D are async* functions that return a Stream
  Stream mySequence() async* {
    // Logic will be added here
  }
}
```

### 3. Implementing a Smooth Fade
Inside the coroutine, use a `while` loop to modify the renderer's opacity every frame. By using `yield null`, we tell the engine to pause the script and resume it on the very next frame.

```dart
Stream mySequence() async* {
  // Grab the renderer from the entity this behavior is attached to
  final renderer = getComponent<SpriteRenderer>();

  double opacity = 0;
  while (opacity < 1.0) {
    // Increment opacity using the engine's delta time
    opacity += game.ticker.deltaTime;
    renderer.color = Colors.white.withOpacity(opacity.clamp(0, 1));
    
    // Pause execution until the next frame
    yield null;
  }
}
```

### 4. Adding Delays and Movement
Use `yield WaitForSeconds(n)` to pause the script for a specific real-world duration. After the wait, we can perform instant actions or start a new animation phase, like moving to a target coordinate.

```dart
Stream mySequence() async* {
  // ... previous fade logic ...

  // Pause the script for exactly 2 seconds
  yield WaitForSeconds(2.0);

  // Instant movement after the wait completes
  getComponent<ObjectTransform>().position = const Offset(3.0, 0);
}
```

### 5. Constructing the Scene
Update your `GameState` to yield a `GameWidget` in its `build` method. This entity will be initialized with a transparent color so our coroutine can handle the fade-in.

```dart
class MyGameWidget extends StatefulGameWidget {
  const MyGameWidget({super.key});
  @override
  GameState<MyGameWidget> createState() => MyGameState();
}

class MyGameState extends GameState<MyGameWidget> {
  @override
  Iterable<Widget> build(BuildContext context) sync* {
    // Yield the ship entity with visuals and the script attached
    yield GameWidget(
      components: () => [
        ObjectTransform(),
        SpriteRenderer()
          ..sprite = GameSprite(texture: GameTextures.ship)
          ..color = Colors.white.withOpacity(0), // Start fully transparent
        SequenceBehavior(),
      ],
    );
  }
}
```

---

## Full Implementation

```dart
import 'package:flutter/material.dart';
import 'package:goo2d/goo2d.dart';

void main() => runApp(const CoroutineExample());

enum GameTextures with AssetEnum, TextureAssetEnum {
  ship;
  @override
  AssetSource get source => AssetSource.local("assets/sprites/$name.png");
}

class CoroutineExample extends StatelessWidget {
  const CoroutineExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FutureBuilder(
        future: GameAsset.loadAll(GameTextures.values).drain(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return const Game(child: MyGameWidget());
        },
      ),
    );
  }
}

class MyGameWidget extends StatefulGameWidget {
  const MyGameWidget({super.key});
  @override
  GameState<MyGameWidget> createState() => MyGameState();
}

class MyGameState extends GameState<MyGameWidget> {
  @override
  Iterable<Widget> build(BuildContext context) sync* {
    yield GameWidget(
      components: () => [
        ObjectTransform(),
        SpriteRenderer()
          ..sprite = GameSprite(texture: GameTextures.ship)
          ..color = Colors.white.withOpacity(0),
        SequenceBehavior(),
      ],
    );
  }
}

class SequenceBehavior extends Behavior with LifecycleListener {
  @override
  void onMounted() {
    startCoroutine(mySequence);
  }

  Stream mySequence() async* {
    final renderer = getComponent<SpriteRenderer>();
    final transform = getComponent<ObjectTransform>();

    // 1. Fade in smoothly
    double opacity = 0;
    while (opacity < 1.0) {
      opacity += game.ticker.deltaTime;
      renderer.color = Colors.white.withOpacity(opacity.clamp(0, 1));
      yield null;
    }

    // 2. Wait for 2 seconds
    yield WaitForSeconds(2.0);

    // 3. Move to target position
    final target = const Offset(3.0, 0);
    while ((transform.position - target).distance > 0.1) {
      transform.position = Offset.lerp(transform.position, target, 0.1)!;
      yield null;
    }
  }
}
```
