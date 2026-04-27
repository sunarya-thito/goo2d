---
sidebar_position: 4
---

# Cookbook: Collisions & Triggers

Detecting interaction between game objects is a core mechanic. This tutorial explains how to use `CollisionTrigger` components and `Behavior` classes to handle the results of an impact using the engine's declarative widget pattern.

## Live Demo

Click "Play" below to see the result. Use **WASD** to move the ship into the stationary enemy and watch the enemy turn red on impact.

<iframe 
  src="/goo2d/play/#/collision" 
  width="100%" 
  height="400px" 
  style={{ border: 'none', borderRadius: '8px', background: '#000' }}
/>

## Assets Used

This tutorial uses assets from the [Kenney Pixel Shmup](https://kenney-assets.itch.io/pixel-shmup) pack.

| Preview | Asset | Action |
| :--- | :--- | :--- |
| ![](/img/cookbook/ship.png) | `ship.png` | [Download](/img/cookbook/ship.png) |
| ![](/img/cookbook/enemy.png) | `enemy.png` | [Download](/img/cookbook/enemy.png) |

---

## Tutorial

### 0. Asset Setup
Before writing any code, you must register your assets with Flutter.

1.  Create a directory named `assets/sprites/` in your project root.
2.  Place the `ship.png` and `enemy.png` files into that directory.
3.  Add the directory to your `pubspec.yaml` file:

```yaml
flutter:
  assets:
    - assets/sprites/
```

### 1. Asset & Scaffolding
Start by defining the textures and the main Flutter widget. We use `GameAsset.loadAll` within a `FutureBuilder` to ensure all sprites are loaded into memory before the world is constructed.

```dart
import 'package:flutter/material.dart';
import 'package:goo2d/goo2d.dart';

void main() => runApp(const CollisionExample());

enum GameTextures with AssetEnum, TextureAssetEnum {
  ship, enemy;
  @override
  AssetSource get source => AssetSource.local("assets/sprites/$name.png");
}

class CollisionExample extends StatelessWidget {
  const CollisionExample({super.key});

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

### 2. The Collision Behavior
Create a behavior that handles impact logic. Mix in `Collidable` to enable the `onCollision` callback. We will use this to change the color of the object when it hits something.

```dart
class HitBehavior extends Behavior with Collidable {
  @override
  void onCollision(CollisionEvent event) {
    // Access the renderer component and change its color
    final renderer = getComponent<SpriteRenderer>();
    renderer.color = Colors.red;
  }
}
```

### 3. Adding Player Movement
To make the example verifiable, we add a behavior that reads keyboard input. This allows you to manually drive the ship into a collision target.

```dart
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
```

### 4. Defining the Game World
Create the `MyGameState` class. This is where we will yield the entities that participate in the collision system.

```dart
class MyGameWidget extends StatefulGameWidget {
  const MyGameWidget({super.key});
  @override
  GameState<MyGameWidget> createState() => MyGameState();
}

class MyGameState extends GameState<MyGameWidget> {
  @override
  Iterable<Widget> build(BuildContext context) sync* {
    // Entities will be yielded in the next steps
  }
}
```

### 5. Spawning the Player Ship
Yield a `GameWidget` for the ship. Attach a `BoxCollisionTrigger` to define the physical boundaries of the object. Note that we attach the `MovementBehavior` for verifiability.

```dart
  @override
  Iterable<Widget> build(BuildContext context) sync* {
    yield GameWidget(
      components: () => [
        ObjectTransform()..position = const Offset(-2, 0),
        SpriteRenderer()..sprite = GameSprite(texture: GameTextures.ship),
        BoxCollisionTrigger()..rect = const Rect.fromLTWH(-0.4, -0.4, 0.8, 0.8),
        MovementBehavior(),
      ],
    );
  }
```

### 6. Spawning the Stationary Enemy
Yield a second `GameWidget` for the enemy. We attach the `HitBehavior` here so that the enemy reacts when the player ship collides with it.

```dart
  @override
  Iterable<Widget> build(BuildContext context) sync* {
    // ... player ship ...

    yield GameWidget(
      components: () => [
        ObjectTransform()..position = const Offset(2, 0),
        SpriteRenderer()..sprite = GameSprite(texture: GameTextures.enemy),
        BoxCollisionTrigger()..rect = const Rect.fromLTWH(-0.4, -0.4, 0.8, 0.8),
        HitBehavior(), // This component reacts to hits
      ],
    );
  }
```

### 7. Adding the Camera
Finally, add a `Camera` entity to the build sequence. Without a camera, the engine won't know which part of the world to project onto the screen.

```dart
  @override
  Iterable<Widget> build(BuildContext context) sync* {
    // ... ship and enemy ...

    yield GameWidget(
      components: () => [
        ObjectTransform(),
        Camera()..orthographicSize = 5.0,
      ],
    );
  }
```

---

## Full Implementation

```dart
import 'package:flutter/material.dart';
import 'package:goo2d/goo2d.dart';

void main() => runApp(const CollisionExample());

enum GameTextures with AssetEnum, TextureAssetEnum {
  ship, enemy;
  @override
  AssetSource get source => AssetSource.local("assets/sprites/$name.png");
}

class CollisionExample extends StatelessWidget {
  const CollisionExample({super.key});

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
        ObjectTransform()..position = const Offset(-2, 0),
        SpriteRenderer()..sprite = GameSprite(texture: GameTextures.ship),
        BoxCollisionTrigger()..rect = const Rect.fromLTWH(-0.4, -0.4, 0.8, 0.8),
        MovementBehavior(),
      ],
    );

    yield GameWidget(
      components: () => [
        ObjectTransform()..position = const Offset(2, 0),
        SpriteRenderer()..sprite = GameSprite(texture: GameTextures.enemy),
        BoxCollisionTrigger()..rect = const Rect.fromLTWH(-0.4, -0.4, 0.8, 0.8),
        HitBehavior(),
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

class HitBehavior extends Behavior with Collidable {
  @override
  void onCollision(CollisionEvent event) {
    final renderer = getComponent<SpriteRenderer>();
    renderer.color = Colors.red;
  }
}
```
