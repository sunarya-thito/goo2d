---
sidebar_position: 1
---

# Cookbook: Follow Camera

In a world larger than the screen, you need a camera that tracks the player. This tutorial builds a smooth tracking system and includes a movement controller so you can verify the results in real-time.

## Live Demo

Click "Play" below to see the result. Use **WASD** to move the ship and watch the camera follow smoothly.

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
Before writing any code, you must register your assets with Flutter so the engine can access them.

1.  Create a directory named `assets/sprites/` in your project root.
2.  Place the `ship.png` file into that directory.
3.  Add the directory to your `pubspec.yaml` file:

```yaml
flutter:
  assets:
    - assets/sprites/
```

### 1. Basic Imports
Every Goo2D project starts with the core engine and material libraries. Define the `main` function to launch your application.

```dart
import 'package:flutter/material.dart';
import 'package:goo2d/goo2d.dart';

void main() => runApp(const CameraExample());
```

### 2. The Main Widget
Create the root `StatelessWidget`. We use a simple `MaterialApp` with a loading placeholder that we will replace once our game assets are ready.

```dart
// ... imports ...

class CameraExample extends StatelessWidget {
  const CameraExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Loading...', style: TextStyle(color: Colors.white))),
        backgroundColor: Colors.black,
      ),
    );
  }
}
```

### 3. Texture Definitions
Define your assets using an enum. Mixing in `AssetEnum` and `TextureAssetEnum` allows the engine to recognize these as image resources that can be pre-loaded.

```dart
// ADD THIS ENUM:
enum GameTextures with AssetEnum, TextureAssetEnum {
  ship;
  @override
  AssetSource get source => AssetSource.local("assets/sprites/$name.png");
}

class CameraExample extends StatelessWidget {
// ...
```

### 4. Asset Pre-loading
Update the `CameraExample` to use a `FutureBuilder`. We use `GameAsset.loadAll` to ensure all textures are fully loaded into GPU memory before the game widget is initialized.

```dart
class CameraExample extends StatelessWidget {
  const CameraExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: FutureBuilder(
          future: GameAsset.loadAll(GameTextures.values).drain(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            return const Game(child: MyGameWidget());
          },
        ),
      ),
    );
  }
}
```

### 5. The Game Widget Pair
Define the `StatefulGameWidget` and its corresponding `GameState`. In Goo2D, major game systems and scene logic are managed within these classes.

```dart
class MyGameWidget extends StatefulGameWidget {
  const MyGameWidget({super.key});
  @override
  GameState<MyGameWidget> createState() => MyGameState();
}

class MyGameState extends GameState<MyGameWidget> {
  @override
  Iterable<Widget> build(BuildContext context) sync* {
    // We will yield game entities here in later steps
  }
}
```

### 6. The Behavior Class
Custom game logic is encapsulated in behaviors. Create a `FollowTarget` class that extends `Behavior`.

```dart
class FollowTarget extends Behavior {
}
```

### 7. Adding Lifecycle Mixins
Mix in `LifecycleListener` and `LateTickable`. Using `LateTickable` ensures the camera update logic runs after all other objects have moved, preventing visual jitter.

```dart
// ADD 'with LifecycleListener, LateTickable'
class FollowTarget extends Behavior with LifecycleListener, LateTickable {
}
```

### 8. Defining the Target Reference
Define a `late` field for the `GameTag`. This allows the behavior to identify which entity it should follow in the scene without needing a direct constructor reference.

```dart
class FollowTarget extends Behavior with LifecycleListener, LateTickable {
  late GameTag targetTag;
}
```

### 9. Overriding the Late Update Loop
Override `onLateUpdate`. This method receives the frame delta time (`dt`) and serves as the entry point for our tracking logic every frame.

```dart
class FollowTarget extends Behavior with LifecycleListener, LateTickable {
  late GameTag targetTag;

  @override
  void onLateUpdate(double dt) {
    // Implementation details follow
  }
}
```

### 10. Accessing the Transform Component
Inside `onLateUpdate`, use `getComponent` to grab the `ObjectTransform` of the entity this behavior is attached to. This is the position we will be modifying.

```dart
  @override
  void onLateUpdate(double dt) {
    // Find the transform component on the camera entity
    final transform = getComponent<ObjectTransform>();
  }
```

### 11. Resolving the Target Position
Use the `targetTag` to find the player's `GameObject` in the world, then retrieve its `ObjectTransform`. We use `tryGetComponent` to handle cases where the player might be missing.

```dart
  @override
  void onLateUpdate(double dt) {
    final transform = getComponent<ObjectTransform>();

    // Resolve the player's transform using its tag
    final target = targetTag.gameObject?.tryGetComponent<ObjectTransform>();
    if (target == null) return;
  }
```

### 12. Implementing Smooth Interpolation
Use `Offset.lerp` to smoothly move the camera's position toward the target. Moving a fraction (0.1) toward the target each frame creates a natural "smooth follow" effect.

```dart
  @override
  void onLateUpdate(double dt) {
    final transform = getComponent<ObjectTransform>();
    final target = targetTag.gameObject?.tryGetComponent<ObjectTransform>();
    if (target == null) return;

    // Linear interpolation for smooth motion
    transform.position = Offset.lerp(
      transform.position,
      target.position,
      0.1,
    )!;
  }
```

### 13. Making the Player Move
To verify the camera follow works, define a `MovementBehavior` that reads WASD keys and moves the entity.

```dart
class MovementBehavior extends Behavior with Tickable {
  @override
  void onUpdate(double dt) {
    final transform = getComponent<ObjectTransform>();
    
    // Simple direct keyboard reading
    double dx = 0, dy = 0;
    if (keyboard.keyW.isPressed) dy -= 1;
    if (keyboard.keyS.isPressed) dy += 1;
    if (keyboard.keyA.isPressed) dx -= 1;
    if (keyboard.keyD.isPressed) dx += 1;
    
    transform.position += Offset(dx, dy) * 5.0 * dt;
  }
}
```

### 14. Spawning the Player Entity
In the `MyGameState.build` method, define a tag for the player and yield a `GameWidget`. We attach the `MovementBehavior` so the ship can move.

```dart
class MyGameState extends GameState<MyGameWidget> {
  @override
  Iterable<Widget> build(BuildContext context) sync* {
    const playerTag = GameTag('Player');

    // Yield the player entity widget
    yield GameWidget(
      key: playerTag,
      components: () => [
        ObjectTransform()..position = Offset.zero,
        SpriteRenderer()..sprite = GameSprite(texture: GameTextures.ship),
        MovementBehavior(), // Add movement logic here
      ],
    );
  }
}
```

### 15. Spawning the Camera Entity (Final)
Add the camera entity to the scene. We attach the `FollowTarget` behavior and use a cascade operator (`..`) to set the `targetTag` to our player's tag.

```dart
class MyGameState extends GameState<MyGameWidget> {
  @override
  Iterable<Widget> build(BuildContext context) sync* {
    const playerTag = GameTag('Player');

    yield GameWidget(
      key: playerTag,
      components: () => [
        ObjectTransform()..position = Offset.zero,
        SpriteRenderer()..sprite = GameSprite(texture: GameTextures.ship),
        MovementBehavior(),
      ],
    );

    // Yield the camera entity widget
    yield GameWidget(
      key: const GameTag('MainCamera'),
      components: () => [
        ObjectTransform(),
        Camera(),
        // Configure the behavior via cascade
        FollowTarget()..targetTag = playerTag,
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

void main() => runApp(const CameraExample());

enum GameTextures with AssetEnum, TextureAssetEnum {
  ship;
  @override
  AssetSource get source => AssetSource.local("assets/sprites/$name.png");
}

class CameraExample extends StatelessWidget {
  const CameraExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: FutureBuilder(
          future: GameAsset.loadAll(GameTextures.values).drain(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            return const Game(child: MyGameWidget());
          },
        ),
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
    const playerTag = GameTag('Player');

    yield GameWidget(
      key: playerTag,
      components: () => [
        ObjectTransform()..position = Offset.zero,
        SpriteRenderer()..sprite = GameSprite(texture: GameTextures.ship),
        MovementBehavior(),
      ],
    );

    yield GameWidget(
      key: const GameTag('MainCamera'),
      components: () => [
        ObjectTransform(),
        Camera(),
        FollowTarget()..targetTag = playerTag,
      ],
    );
  }
}

class MovementBehavior extends Behavior with Tickable {
  @override
  void onUpdate(double dt) {
    final transform = getComponent<ObjectTransform>();
    double dx = 0, dy = 0;
    if (keyboard.keyW.isPressed) dy -= 1;
    if (keyboard.keyS.isPressed) dy += 1;
    if (keyboard.keyA.isPressed) dx -= 1;
    if (keyboard.keyD.isPressed) dx += 1;
    transform.position += Offset(dx, dy) * 5.0 * dt;
  }
}

class FollowTarget extends Behavior with LifecycleListener, LateTickable {
  late GameTag targetTag;

  @override
  void onLateUpdate(double dt) {
    final transform = getComponent<ObjectTransform>();
    final target = targetTag.gameObject?.tryGetComponent<ObjectTransform>();
    if (target == null) return;

    transform.position = Offset.lerp(
      transform.position,
      target.position,
      0.1,
    )!;
  }
}
```
