---
sidebar_position: 3
---

# Cookbook: Input & Movement

Goo2D uses an action-based input system. Instead of checking for specific keys, you define logical actions (like "move") and bind keys to them. This tutorial explains how to implement smooth 2D movement and a polished "banking" effect.

## Live Demo

Click "Play" below to see the result. Use **WASD** or **Arrow Keys** to move the ship. Notice how it tilts as it turns.

<iframe 
  src="/goo2d/play/#/input" 
  width="100%" 
  height="400px" 
  style={{ border: 'none', borderRadius: '8px', background: '#000' }}
/>

## Assets Used

This tutorial uses assets from the [Kenney Pixel Shmup](https://kenney-assets.itch.io/pixel-shmup) pack.

| Preview | Asset | Action |
| :--- | :--- | :--- |
| ![](/img/cookbook/ship.png) | `ship.png` | [Download](/img/cookbook/ship.png) |

---

## Tutorial

### 0. Asset Setup
Before writing any code, you must register your assets with Flutter.

1.  Create a directory named `assets/sprites/` in your project root.
2.  Place the `ship.png` file into that directory.
3.  Add the directory to your `pubspec.yaml` file:

```yaml
flutter:
  assets:
    - assets/sprites/
```

### 1. Basic Imports & main()
Start with the minimum imports and the entry point of your application.

```dart
// Add this: ------
import 'package:flutter/material.dart';
import 'package:goo2d/goo2d.dart';

void main() => runApp(const InputExample());
// ----------------
```

We import the Goo2D package and standard Flutter material library. The `main` function starts our root widget.

### 2. The Root Widget
Create a `StatelessWidget` that will act as the root of your application.

```dart
import 'package:flutter/material.dart';
import 'package:goo2d/goo2d.dart';

void main() => runApp(const InputExample());

// Add this: ------
class InputExample extends StatelessWidget {
  const InputExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(child: Text("Loading...")),
      ),
    );
  }
}
// ----------------
```

The `InputExample` widget sets up a standard `MaterialApp`. For now, it just shows a simple loading text while we prepare the game assets.

### 3. Defining Textures
Use an `enum` with `AssetEnum` and `TextureAssetEnum` to manage your sprite assets cleanly.

```dart
import 'package:flutter/material.dart';
import 'package:goo2d/goo2d.dart';

void main() => runApp(const InputExample());

// Add this: ------
enum GameTextures with AssetEnum, TextureAssetEnum {
  ship;
  @override
  AssetSource get source => AssetSource.local("assets/sprites/$name.png");
}
// ----------------

class InputExample extends StatelessWidget {
  const InputExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(child: Text("Loading...")),
      ),
    );
  }
}
```

This enum acts as a strongly-typed registry for our sprites. The `AssetSource.local` helper automatically maps the enum names to the file paths in your assets folder.

### 4. Loading Assets
Wrap your game in a `FutureBuilder` and use `GameAsset.loadAll` to ensure textures are ready before the engine starts.

```dart
class InputExample extends StatelessWidget {
  const InputExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Add this: ------
      home: FutureBuilder(
        future: GameAsset.loadAll(GameTextures.values).drain(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return const Game(child: MyGameWidget());
        },
      ),
      // ----------------
    );
  }
}
```

Game textures must be uploaded to the GPU before they can be rendered. `GameAsset.loadAll().drain()` waits for all registered assets to be fully loaded, preventing "flickering" or missing sprites when the game starts.

### 5. The Empty Game Widget
Define the `StatefulGameWidget` and its corresponding `GameState`.

```dart
// ... enum definitions ...

// Add this: ------
class MyGameWidget extends StatefulGameWidget {
  const MyGameWidget({super.key});
  @override
  GameState<MyGameWidget> createState() => MyGameState();
}

class MyGameState extends GameState<MyGameWidget> {
  @override
  Iterable<Widget> build(BuildContext context) sync* {
  }
}
// ----------------
```

The `MyGameWidget` widget is the container for our game simulation. It uses a `GameState` to manage the lifecycle and components of the game world.

### 6. Adding the Camera
Every game world needs a camera to define what part of the space is visible on screen.

```dart
class MyGameState extends GameState<MyGameWidget> {
  @override
  Iterable<Widget> build(BuildContext context) sync* {
    // Add this: ------
    yield GameWidget(components: () => [ObjectTransform(), Camera()..orthographicSize = 5.0]);
    // ----------------
  }
}
```

We yield a `GameWidget` containing a `Camera` component. The `orthographicSize = 5.0` determines the vertical view size; specifically, it means 5 world units from the center of the screen to the top and bottom edges.

### 7. Defining the Movement Behavior
Create the `PlayerMovement` behavior class. Behaviours are used to add custom logic to your game objects.

```dart
// Add this: ------
class PlayerMovement extends Behavior with Tickable {
  @override
  void onUpdate(double dt) {
  }
}
// ----------------
```

We create a class that extends `Behavior` and mixes in `Tickable`.

### 8. Adding the InputAction Property
Behaviours need to know which input action they should listen to.

```dart
class PlayerMovement extends Behavior with Tickable {
  // Add this: ------
  late InputAction moveAction;
  // ----------------

  @override
  void onUpdate(double dt) {
  }
}
```

We add a `late InputAction moveAction` property. This will be initialized when we spawn the player, allowing the behavior to read input values.

### 9. Implementing Smooth Movement
Read the input value and update the object's position every frame.

```dart
class PlayerMovement extends Behavior with Tickable {
  late InputAction moveAction;

  @override
  void onUpdate(double dt) {
    // Add this: ------
    final moveVector = moveAction.readValue<Offset>();
    final transform = getComponent<ObjectTransform>();
    
    // Move at 5.0 world units per second
    transform.position += moveVector * 5.0 * dt;
    // ----------------
  }
}
```

Inside `onUpdate`, we use `readValue<Offset>()` to get the current 2D movement vector (e.g., from a joystick or composite keys). We multiply this by a speed of `5.0` and `dt` (delta time) to ensure smooth, frame-independent movement.

### 10. Adding the "Tilt" Effect
Add a subtle rotation to the ship based on its horizontal movement.

```dart
class PlayerMovement extends Behavior with Tickable {
  late InputAction moveAction;

  @override
  void onUpdate(double dt) {
    final moveVector = moveAction.readValue<Offset>();
    final transform = getComponent<ObjectTransform>();
    
    transform.position += moveVector * 5.0 * dt;

    // Add this: ------
    // Target rotation is based on horizontal movement
    final targetRotation = -moveVector.dx * 0.5;
    
    // Smoothly interpolate (lerp) towards the target rotation
    transform.angle = lerpDouble(transform.angle, targetRotation, 10.0 * dt);
    // ----------------
  }

  // Add this: ------
  double lerpDouble(double a, double b, double t) {
    return a + (b - a) * t.clamp(0.0, 1.0);
  }
  // ----------------
}
```

To create a polished feel, we calculate a `targetRotation` based on the horizontal input. We then use a custom `lerpDouble` helper to smoothly transition the ship's `angle`. This gives the ship a satisfying "banking" look when turning.

### 11. Defining the Game State Action
We need a place to store our persistent input action.

```dart
class MyGameState extends GameState<MyGameWidget> {
  // Add this: ------
  late final InputAction moveAction;
  // ----------------

  @override
  Iterable<Widget> build(BuildContext context) sync* {
    yield GameWidget(components: () => [ObjectTransform(), Camera()..orthographicSize = 5.0]);
  }
}
```

The `GameState` is the perfect place to define input actions that should persist across different game objects.

### 12. Configuring Input Bindings
In `initState`, bind both WASD and Arrow Keys to the move action.

```dart
class MyGameState extends GameState<MyGameWidget> {
  late final InputAction moveAction;

  // Add this: ------
  @override
  void initState() {
    super.initState();
    moveAction = createInputAction(
      name: 'move',
      type: InputActionType.value,
      bindings: [
        InputBinding.composite(
          up: game.input.keyboard.keyW,
          down: game.input.keyboard.keyS,
          left: game.input.keyboard.keyA,
          right: game.input.keyboard.keyD,
        ),
        InputBinding.composite(
          up: game.input.keyboard.upArrow,
          down: game.input.keyboard.downArrow,
          left: game.input.keyboard.leftArrow,
          right: game.input.keyboard.rightArrow,
        ),
      ],
    );
  }
  // ----------------

  @override
  Iterable<Widget> build(BuildContext context) sync* {
    yield GameWidget(components: () => [ObjectTransform(), Camera()..orthographicSize = 5.0]);
  }
}
```

We use `InputBinding.composite` to combine four individual keys into a single 2D vector. By adding both WASD and `upArrow`/`downArrow` etc., we provide multiple control schemes for the player.

### 13. Spawning the Player Entity
Finally, yield the player ship into the game world using the `GameWidget`.

```dart
class MyGameState extends GameState<MyGameWidget> {
  // ... initState and variables ...

  @override
  Iterable<Widget> build(BuildContext context) sync* {
    // Add this: ------
    yield GameWidget(
      components: () => [
        ObjectTransform()..position = Offset.zero,
        SpriteRenderer()
          ..sprite = GameSprite(
            texture: GameTextures.ship,
            pixelsPerUnit: 32.0, // Larger visual size
          ),
        PlayerMovement()..moveAction = moveAction,
      ],
    );
    // ----------------

    yield GameWidget(components: () => [ObjectTransform(), Camera()..orthographicSize = 5.0]);
  }
}
```

We spawn the player at the center of the world. We set `pixelsPerUnit: 32.0` to make the ship appear larger and more prominent. We also pass our `moveAction` into the `PlayerMovement` behavior using the cascade operator.

---

## Final Full Code

```dart
import 'package:flutter/material.dart';
import 'package:goo2d/goo2d.dart';

void main() => runApp(const InputExample());

enum GameTextures with AssetEnum, TextureAssetEnum {
  ship;
  @override
  AssetSource get source => AssetSource.local("assets/sprites/$name.png");
}

class InputExample extends StatelessWidget {
  const InputExample({super.key});

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
  late final InputAction moveAction;

  @override
  void initState() {
    super.initState();
    moveAction = createInputAction(
      name: 'move',
      type: InputActionType.value,
      bindings: [
        InputBinding.composite(
          up: game.input.keyboard.keyW,
          down: game.input.keyboard.keyS,
          left: game.input.keyboard.keyA,
          right: game.input.keyboard.keyD,
        ),
        InputBinding.composite(
          up: game.input.keyboard.upArrow,
          down: game.input.keyboard.downArrow,
          left: game.input.keyboard.leftArrow,
          right: game.input.keyboard.rightArrow,
        ),
      ],
    );
  }

  @override
  Iterable<Widget> build(BuildContext context) sync* {
    yield GameWidget(
      components: () => [
        ObjectTransform()..position = Offset.zero,
        SpriteRenderer()
          ..sprite = GameSprite(
            texture: GameTextures.ship,
            pixelsPerUnit: 32.0,
          ),
        PlayerMovement()..moveAction = moveAction,
      ],
    );

    yield GameWidget(
      components: () => [
        ObjectTransform(),
        Camera()..orthographicSize = 5.0,
      ],
    );
  }
}

class PlayerMovement extends Behavior with Tickable {
  late InputAction moveAction;

  @override
  void onUpdate(double dt) {
    final moveVector = moveAction.readValue<Offset>();
    final transform = getComponent<ObjectTransform>();
    
    transform.position += moveVector * 5.0 * dt;

    final targetRotation = -moveVector.dx * 0.5;
    transform.angle = lerpDouble(transform.angle, targetRotation, 10.0 * dt);
  }

  double lerpDouble(double a, double b, double t) {
    return a + (b - a) * t.clamp(0.0, 1.0);
  }
}
```
