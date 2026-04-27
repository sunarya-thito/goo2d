---
sidebar_position: 1
---

# Cookbook: Camera Follow

In a world larger than the screen, you need a camera that tracks the player. This tutorial builds a tracking system using interpolation to coordinate the camera position and ensure the view remains steady as the player moves.

## Live Demo

Click "Play" below to see the result. Use **WASD** or **Arrow Keys** to move the ship and watch the camera follow smoothly.

<iframe 
  src="/goo2d/play/#/camera" 
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
Start with the necessary imports and the entry point of your application.

```dart
// Add this: ------
import 'package:flutter/material.dart';
import 'package:goo2d/goo2d.dart';
import 'dart:math' as math;

void main() => runApp(const CameraExample());
// ----------------
```

We import the Goo2D package and standard Flutter material library. We also include `dart:math` as `math` to provide the exponential functions needed for framerate-independent interpolation.

### 2. The Root Widget
Create a `StatefulWidget` that will act as the root of your application.

```dart
import 'package:flutter/material.dart';
import 'package:goo2d/goo2d.dart';
import 'dart:math' as math;

void main() => runApp(const CameraExample());

// Add this: ------
class CameraExample extends StatefulWidget {
  const CameraExample({super.key});

  @override
  State<CameraExample> createState() => _CameraExampleState();
}

class _CameraExampleState extends State<CameraExample> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
// ----------------
```

The `CameraExample` widget sets up a standard `MaterialApp`. We use a `StatefulWidget` here because we need to manage the lifecycle of our game assets, ensuring everything is loaded before the engine starts.

### 3. Defining Textures
Use an `enum` with `AssetEnum` and `TextureAssetEnum` to manage your sprite assets cleanly.

```dart
import 'package:flutter/material.dart';
import 'package:goo2d/goo2d.dart';
import 'dart:math' as math;

void main() => runApp(const CameraExample());

// Add this: ------
enum CameraExampleTexture with AssetEnum, TextureAssetEnum {
  ship;
  @override
  AssetSource get source => AssetSource.local("assets/sprites/$name.png");
}
// ----------------

class CameraExample extends StatefulWidget {
// ... existing CameraExample implementation ...
```

This enum acts as a strongly-typed registry for our sprites. The `AssetSource.local` helper automatically maps the enum names to the file paths in your assets folder.

### 4. Loading Assets
Add a field to track the asset loading progress and initialize it in `initState`.

```dart
class _CameraExampleState extends State<CameraExample> {
  // Add this: ------
  late final Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = GameAsset.loadAll(CameraExampleTexture.values).drain();
  }
  // ----------------

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
```

We call `GameAsset.loadAll` to begin fetching the textures. The `drain()` method is used to convert the stream of loading events into a single future that completes only when every texture is ready in GPU memory.

### 5. Starting the Engine
Update the build method to use a `FutureBuilder` to launch the game engine once assets are ready.

```dart
class _CameraExampleState extends State<CameraExample> {
  late final Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = GameAsset.loadAll(CameraExampleTexture.values).drain();
  }

  @override
  Widget build(BuildContext context) {
    // Add this: ------
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: FutureBuilder(
          future: _loadFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }
            return const Game(child: CameraExampleWorld());
          },
        ),
      ),
    );
    // ----------------
  }
}
```

The `FutureBuilder` ensures that the `Game` widget is only created once all assets are fully available. We pass `CameraExampleWorld` as the child, which will host our game scene.

### 6. The Empty Game World
Define the `StatefulGameWidget` and its corresponding `GameState`.

```dart
import 'package:flutter/material.dart';
import 'package:goo2d/goo2d.dart';
import 'dart:math' as math;

// ... enum definitions ...

// Add this: ------
class CameraExampleWorld extends StatefulGameWidget {
  const CameraExampleWorld({super.key});

  @override
  GameState<CameraExampleWorld> createState() => _CameraExampleWorldState();
}

class _CameraExampleWorldState extends GameState<CameraExampleWorld> {
  @override
  Iterable<Widget> build(BuildContext context) sync* {
  }
}
// ----------------
```

The `CameraExampleWorld` widget is the container for our game simulation. It uses a `GameState` to manage the lifecycle and components of the game world coordinate system.

### 7. Creating the Follow Behavior
Implement the behavior that makes the camera track a target object.

```dart
// Add this: ------
class FollowPlayer extends Behavior with LateTickable {
  late GameTag targetTag;

  @override
  void onLateUpdate(double dt) {
    final target = targetTag.gameObject?.tryGetComponent<ObjectTransform>();
    if (target != null) {
      final transform = getComponent<ObjectTransform>();
      
      transform.position = Offset.lerp(
        transform.position,
        target.position,
        1.0 - math.exp(-5.0 * dt),
      )!;
    }
  }
}
// ----------------
```

We use `LateTickable` to ensure the camera updates **after** all other objects have moved, preventing visual jitter. The formula `1.0 - math.exp(-5.0 * dt)` provides framerate-independent exponential decay, ensuring the tracking feels the same regardless of performance.

### 8. Implementing Ship Movement
Create a behavior to handle player input and update the ship's position.

```dart
// Add this: ------
class ShipMovement extends Behavior with Tickable {
  late InputAction moveAction;

  @override
  void onUpdate(double dt) {
    final moveVector = moveAction.readValue<Offset>();
    final transform = getComponent<ObjectTransform>();
    
    transform.position += moveVector * 5.0 * dt;
  }
}
// ----------------
```

This behavior reads a 2D vector from an `InputAction` and applies it to the object's `ObjectTransform`. We multiply by `dt` to ensure the movement speed is consistent across different devices.

### 9. Defining the Player Action
Update the world state to initialize the movement input action.

```dart
class _CameraExampleWorldState extends GameState<CameraExampleWorld> {
  // Add this: ------
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
          right: game.input.keyboard.rightArrow,
        ),
      ],
    );
  }
  // ----------------

  @override
  Iterable<Widget> build(BuildContext context) sync* {
  }
}
```

We use `createInputAction` to define a logical movement action. By binding keys to an action rather than checking them directly, we keep our behavior logic clean and reusable.

### 10. The Player Ship Entity
Create a class for the player ship and initialize its components.

```dart
// Add this: ------
class PlayerShip extends StatefulGameWidget {
  final InputAction moveAction;
  const PlayerShip({super.key, required this.moveAction});
  @override
  GameState<PlayerShip> createState() => _PlayerShipState();
}

class _PlayerShipState extends GameState<PlayerShip> {
  @override
  void initState() {
    super.initState();
    addComponent(
      ObjectTransform()..position = Offset.zero,
      SpriteRenderer()
        ..sprite = GameSprite(
          texture: CameraExampleTexture.ship,
          pixelsPerUnit: 32,
        ),
      ShipMovement()..moveAction = widget.moveAction,
    );
  }

  @override
  Iterable<Widget> build(BuildContext context) sync* {}
}
// ----------------
```

The `PlayerShip` is composed of a transform, a renderer, and our custom movement behavior. Setting `pixelsPerUnit: 32` ensures the sprite size is correctly mapped to our world units.

### 11. Assembling the World
Yield the background, player, and camera in the world's build method.

```dart
class _CameraExampleWorldState extends GameState<CameraExampleWorld> {
  late final InputAction moveAction;

  // ... initState implementation ...

  @override
  Iterable<Widget> build(BuildContext context) sync* {
    // Add this: ------
    const playerTag = GameTag('Player');

    yield PlayerShip(
      key: playerTag,
      moveAction: moveAction,
    );

    yield GameWidget(
      key: const GameTag('MainCamera'),
      components: () => [
        ObjectTransform(),
        Camera()
          ..depth = 1.0
          ..backgroundColor = Colors.black
          ..orthographicSize = 5.0,
        FollowPlayer()..targetTag = playerTag,
      ],
    );
    // ----------------
  }
}
```

In the assembly step, we yield the `PlayerShip` and a `GameWidget` for the camera. By setting `depth: 1.0`, we designate this camera as the primary viewport. The `FollowPlayer` behavior is attached to the camera and configured to track the `playerTag`.

---

## Final Full Code

```dart
import 'package:flutter/material.dart';
import 'package:goo2d/goo2d.dart';
import 'dart:math' as math;

void main() => runApp(const CameraExample());

enum CameraExampleTexture with AssetEnum, TextureAssetEnum {
  ship;
  @override
  AssetSource get source => AssetSource.local("assets/sprites/$name.png");
}

class CameraExample extends StatefulWidget {
  const CameraExample({super.key});

  @override
  State<CameraExample> createState() => _CameraExampleState();
}

class _CameraExampleState extends State<CameraExample> {
  late final Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = GameAsset.loadAll(CameraExampleTexture.values).drain();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: FutureBuilder(
          future: _loadFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }
            return const Game(child: CameraExampleWorld());
          },
        ),
      ),
    );
  }
}

class CameraExampleWorld extends StatefulGameWidget {
  const CameraExampleWorld({super.key});

  @override
  GameState<CameraExampleWorld> createState() => _CameraExampleWorldState();
}

class _CameraExampleWorldState extends GameState<CameraExampleWorld> {
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
    const playerTag = GameTag('Player');

    yield PlayerShip(
      key: playerTag,
      moveAction: moveAction,
    );

    yield GameWidget(
      key: const GameTag('MainCamera'),
      components: () => [
        ObjectTransform(),
        Camera()
          ..depth = 1.0
          ..backgroundColor = Colors.black
          ..orthographicSize = 5.0,
        FollowPlayer()..targetTag = playerTag,
      ],
    );
  }
}

class PlayerShip extends StatefulGameWidget {
  final InputAction moveAction;
  const PlayerShip({super.key, required this.moveAction});
  @override
  GameState<PlayerShip> createState() => _PlayerShipState();
}

class _PlayerShipState extends GameState<PlayerShip> {
  @override
  void initState() {
    super.initState();
    addComponent(
      ObjectTransform()..position = Offset.zero,
      SpriteRenderer()
        ..sprite = GameSprite(
          texture: CameraExampleTexture.ship,
          pixelsPerUnit: 32,
        ),
      ShipMovement()..moveAction = widget.moveAction,
    );
  }

  @override
  Iterable<Widget> build(BuildContext context) sync* {}
}

class ShipMovement extends Behavior with Tickable {
  late InputAction moveAction;

  @override
  void onUpdate(double dt) {
    final moveVector = moveAction.readValue<Offset>();
    final transform = getComponent<ObjectTransform>();
    transform.position += moveVector * 5.0 * dt;
  }
}

class FollowPlayer extends Behavior with LateTickable {
  late GameTag targetTag;

  @override
  void onLateUpdate(double dt) {
    final target = targetTag.gameObject?.tryGetComponent<ObjectTransform>();
    if (target != null) {
      final transform = getComponent<ObjectTransform>();
      transform.position = Offset.lerp(
        transform.position,
        target.position,
        1.0 - math.exp(-5.0 * dt),
      )!;
    }
  }
}
```
