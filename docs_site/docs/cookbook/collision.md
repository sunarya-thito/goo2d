---
sidebar_position: 4
---

# Cookbook: Collisions & Triggers

Detecting interaction between game objects is a core mechanic. This tutorial explains how to use `CollisionTrigger` components and `Behavior` classes to handle physical reactions like bouncing and visual state changes.

## Live Demo

Click "Play" below to see the result. The red ship bounces off the screen edges and the stationary blue ships. Each collision cycles the ship's color.

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

### 1. Basic Imports & main()
Start with the minimum imports and the entry point of your application.

```dart
// Add this: ------
import 'package:flutter/material.dart';
import 'package:goo2d/goo2d.dart';
import 'dart:math' as math;

void main() => runApp(const CollisionExample());
// ----------------
```

We import the Goo2D package and standard Flutter material library. We also include `dart:math` which we will use later for boundary calculations and randomized bounces.

### 2. The Root Widget
Create a `StatelessWidget` that will act as the root of your application.

```dart
import 'package:flutter/material.dart';
import 'package:goo2d/goo2d.dart';
import 'dart:math' as math;

void main() => runApp(const CollisionExample());

// Add this: ------
class CollisionExample extends StatelessWidget {
  const CollisionExample({super.key});

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

The `CollisionExample` widget sets up a standard `MaterialApp`. For now, it just shows a simple loading text while we prepare the game world.

### 3. Defining Textures
Use an `enum` with `AssetEnum` and `TextureAssetEnum` to manage your sprite assets cleanly.

```dart
import 'package:flutter/material.dart';
import 'package:goo2d/goo2d.dart';
import 'dart:math' as math;

void main() => runApp(const CollisionExample());

// Add this: ------
enum GameTextures with AssetEnum, TextureAssetEnum {
  ship, enemy;
  @override
  AssetSource get source => AssetSource.local("assets/sprites/$name.png");
}
// ----------------

class CollisionExample extends StatelessWidget {
  const CollisionExample({super.key});

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
class CollisionExample extends StatelessWidget {
  const CollisionExample({super.key});

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
          return const Game(child: MyGameWorld());
        },
      ),
      // ----------------
    );
  }
}
```

Game textures must be uploaded to the GPU before they can be rendered. `GameAsset.loadAll().drain()` waits for all registered assets to be fully loaded, preventing "flickering" or missing sprites when the game starts.

### 5. The Empty Game World
Define the `StatefulGameWidget` and its corresponding `GameState`.

```dart
import 'package:flutter/material.dart';
import 'package:goo2d/goo2d.dart';
import 'dart:math' as math;

// ... enum definitions ...

// Add this: ------
class MyGameWorld extends StatefulGameWidget {
  const MyGameWorld({super.key});
  @override
  GameState<MyGameWorld> createState() => MyGameWorldState();
}

class MyGameWorldState extends GameState<MyGameWorld> {
  @override
  Iterable<Widget> build(BuildContext context) sync* {
  }
}
// ----------------
```

The `MyGameWorld` widget is the container for our game simulation. It uses a `GameState` to manage the lifecycle and components of the game world.

### 6. Adding the Camera
Every game world needs a camera to define what part of the space is visible on screen.

```dart
class MyGameWorldState extends GameState<MyGameWorld> {
  @override
  Iterable<Widget> build(BuildContext context) sync* {
    // Add this: ------
    yield GameWidget(components: () => [ObjectTransform(), Camera()..orthographicSize = 5.0]);
    // ----------------
  }
}
```

We yield a `GameWidget` containing a `Camera` component. The `orthographicSize = 5.0` determines the vertical view size; specifically, it means 5 world units from the center of the screen to the top and bottom edges.

### 7. Defining the Behavior
Create the `ProjectileBehavior` class. Behaviours are used to add custom logic to your game objects.

```dart
// Add this: ------
class ProjectileBehavior extends Behavior with Tickable {
  @override
  void onUpdate(double dt) {
  }
}
// ----------------
```

We create a class that extends `Behavior` and mixes in `Tickable`. This gives us access to the `onUpdate` method, which fires every frame of the game.

### 8. Adding Movement Velocity
Now we define the velocity that will control our ship's movement.

```dart
class ProjectileBehavior extends Behavior with Tickable {
  // Add this: ------
  Offset velocity = const Offset(3.0, 2.0);
  // ----------------

  @override
  void onUpdate(double dt) {
  }
}
```

We define a `velocity` field as an `Offset`. This represents how many world units the ship will move in the X and Y directions every second.

### 9. Implementing Movement Logic
Update the position of the object every frame based on its velocity.

```dart
class ProjectileBehavior extends Behavior with Tickable {
  Offset velocity = const Offset(3.0, 2.0);

  @override
  void onUpdate(double dt) {
    // Add this: ------
    final transform = getComponent<ObjectTransform>();
    transform.position += velocity * dt;
    // ----------------
  }
}
```

Inside `onUpdate`, we fetch the parent object's `ObjectTransform` component and increment its `position` by our velocity. We multiply by `dt` (delta time) to ensure the movement speed is consistent regardless of the frame rate.

### 10. Spawning the Moving Ship
Let's add our moving ship to the game world.

```dart
class MyGameWorldState extends GameState<MyGameWorld> {
  @override
  Iterable<Widget> build(BuildContext context) sync* {
    // Add this: ------
    yield GameWidget(
      components: () => [
        ObjectTransform()..position = const Offset(-2, 0),
        SpriteRenderer()..sprite = GameSprite(texture: GameTextures.enemy),
        ProjectileBehavior(),
      ],
    );
    // ----------------

    yield GameWidget(components: () => [ObjectTransform(), Camera()..orthographicSize = 5.0]);
  }
}
```

We add the ship to our world. It consists of a transform (set at x=-2), a `SpriteRenderer` using the `enemy` texture, and the `ProjectileBehavior` we just wrote. The ship will now start moving as soon as the game begins.

### 11. Adding the Hitbox
Add a `BoxCollisionTrigger` to define the collision area.

```dart
class MyGameWorldState extends GameState<MyGameWorld> {
  @override
  Iterable<Widget> build(BuildContext context) sync* {
    yield GameWidget(
      components: () => [
        ObjectTransform()..position = const Offset(-2, 0),
        SpriteRenderer()..sprite = GameSprite(texture: GameTextures.enemy),
        // Add this: ------
        BoxCollisionTrigger()..rect = const Rect.fromLTWH(-0.25, -0.25, 0.5, 0.5),
        // ----------------
        ProjectileBehavior(),
      ],
    );

    yield GameWidget(components: () => [ObjectTransform(), Camera()..orthographicSize = 5.0]);
  }
}
```

The `BoxCollisionTrigger` defines the physical presence of the object. We use a rect of `0.5x0.5` units centered at the origin. Using a hitbox slightly smaller than the visual sprite creates a better "feel" for the player by avoiding collisions on transparent pixel edges.

### 12. Enabling Collision Events
To handle the "hit," the behavior must be made `Collidable`.

```dart
// Add this: ------
class ProjectileBehavior extends Behavior with Tickable, Collidable {
// ----------------
  Offset velocity = const Offset(3.0, 2.0);

  @override
  void onUpdate(double dt) {
    final transform = getComponent<ObjectTransform>();
    transform.position += velocity * dt;
  }

  // Add this: ------
  @override
  void onCollision(CollisionEvent event) {
  }
  // ----------------
}
```

Mixing in `Collidable` tells the engine's physics system to notify this behavior whenever its parent object's trigger overlaps with another trigger. The `onCollision` method will receive an `event` containing details about the other object.

### 13. Implementing the Bounce Logic
Now let's make the ship bounce properly when it hits something.

```dart
class ProjectileBehavior extends Behavior with Tickable, Collidable {
  Offset velocity = const Offset(3.0, 2.0);

  @override
  void onUpdate(double dt) {
    final transform = getComponent<ObjectTransform>();
    transform.position += velocity * dt;
  }

  @override
  void onCollision(CollisionEvent event) {
    // Add this: ------
    final transform = getComponent<ObjectTransform>();
    final otherPos = event.other.gameObject.getComponent<ObjectTransform>().position;
    final diff = transform.position - otherPos;

    if (diff.dx.abs() > diff.dy.abs()) {
      if ((velocity.dx > 0 && diff.dx < 0) || (velocity.dx < 0 && diff.dx > 0)) {
        velocity = Offset(-velocity.dx, velocity.dy);
        transform.position += Offset(velocity.dx.sign * 0.1, 0); 
      }
    } else {
      if ((velocity.dy > 0 && diff.dy < 0) || (velocity.dy < 0 && diff.dy > 0)) {
        velocity = Offset(velocity.dx, -velocity.dy);
        transform.position += Offset(0, velocity.dy.sign * 0.1);
      }
    }
    // ----------------
  }
}
```

We calculate the difference between our position and the obstacle's position to determine the collision axis. We only flip the velocity if we are moving **towards** the other object. Additionally, we add a small `0.1` unit "push" to immediately separate the hitboxes, preventing them from staying stuck together in a loop.

### 14. Adding Stationary Targets
We add some stationary blue ships for our projectile to bounce off of.

```dart
class MyGameWorldState extends GameState<MyGameWorld> {
  @override
  Iterable<Widget> build(BuildContext context) sync* {
    yield GameWidget(
      components: () => [
        ObjectTransform()..position = const Offset(-2, 0),
        SpriteRenderer()..sprite = GameSprite(texture: GameTextures.enemy),
        BoxCollisionTrigger()..rect = const Rect.fromLTWH(-0.25, -0.25, 0.5, 0.5),
        ProjectileBehavior(),
      ],
    );

    // Add this: ------
    for (int i = 0; i < 3; i++) {
      yield GameWidget(
        components: () => [
          ObjectTransform()..position = Offset(i * 3.0, (i % 2 == 0) ? 2.0 : -2.0),
          SpriteRenderer()
            ..sprite = GameSprite(texture: GameTextures.ship)
            ..color = Colors.blue.withValues(alpha: 0.5),
          BoxCollisionTrigger()..rect = const Rect.fromLTWH(-0.25, -0.25, 0.5, 0.5),
        ],
      );
    }
    // ----------------

    yield GameWidget(components: () => [ObjectTransform(), Camera()..orthographicSize = 5.0]);
  }
}
```

Collisions only occur if **both** objects have a `CollisionTrigger`. By adding these blue ships with their own triggers, the moving ship's `onCollision` will now fire whenever it overlaps them.

### 15. Handling Screen Edges
To keep the ship on screen, we use the `OuterScreenCollidable` mixin.

```dart
// Add this: ------
class ProjectileBehavior extends Behavior with Tickable, Collidable, OuterScreenCollidable {
// ----------------
  Offset velocity = const Offset(3.0, 2.0);

  @override
  void onUpdate(double dt) {
    final transform = getComponent<ObjectTransform>();
    transform.position += velocity * dt;
  }

  // ... onCollision ...

  // Add this: ------
  @override
  void onOuterScreenEnter() {
    final camera = game.cameras.main;
    final transform = getComponent<ObjectTransform>();
    final tl = camera.screenToWorldPoint(Offset.zero, game.ticker.screenSize);
    final br = camera.screenToWorldPoint(
      Offset(game.ticker.screenSize.width, game.ticker.screenSize.height),
      game.ticker.screenSize,
    );

    final left = math.min(tl.dx, br.dx);
    final right = math.max(tl.dx, br.dx);
    final top = math.max(tl.dy, br.dy);
    final bottom = math.min(tl.dy, br.dy);

    if (transform.position.dx <= left && velocity.dx < 0) velocity = Offset(-velocity.dx, velocity.dy);
    if (transform.position.dx >= right && velocity.dx > 0) velocity = Offset(-velocity.dx, velocity.dy);
    if (transform.position.dy >= top && velocity.dy > 0) velocity = Offset(velocity.dx, -velocity.dy);
    if (transform.position.dy <= bottom && velocity.dy < 0) velocity = Offset(velocity.dx, -velocity.dy);
  }
  // ----------------
}
```

The `OuterScreenCollidable` mixin provides a callback that fires when any part of the object's hitbox leaves the screen. Inside, we convert screen pixels (Top-Left and Bottom-Right) into world coordinates to find our boundaries, then flip the velocity accordingly.

### 16. Final Full Code
This version includes color cycling and noise to keep the movement dynamic.

```dart
import 'package:flutter/material.dart';
import 'package:goo2d/goo2d.dart';
import 'dart:math' as math;

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
          return const Game(child: MyGameWorld());
        },
      ),
    );
  }
}

class MyGameWorld extends StatefulGameWidget {
  const MyGameWorld({super.key});
  @override
  GameState<MyGameWorld> createState() => MyGameWorldState();
}

class MyGameWorldState extends GameState<MyGameWorld> {
  @override
  Iterable<Widget> build(BuildContext context) sync* {
    yield GameWidget(
      components: () => [
        ObjectTransform()..position = const Offset(-2, 0),
        SpriteRenderer()..sprite = GameSprite(texture: GameTextures.enemy),
        BoxCollisionTrigger()..rect = const Rect.fromLTWH(-0.25, -0.25, 0.5, 0.5),
        ProjectileBehavior(),
      ],
    );

    for (int i = 0; i < 5; i++) {
      yield GameWidget(
        components: () => [
          ObjectTransform()..position = Offset(i * 3.0 - 6.0, (i % 2 == 0) ? 2.0 : -2.0),
          SpriteRenderer()
            ..sprite = GameSprite(texture: GameTextures.ship)
            ..color = Colors.blue.withValues(alpha: 0.5),
          BoxCollisionTrigger()..rect = const Rect.fromLTWH(-0.25, -0.25, 0.5, 0.5),
        ],
      );
    }

    yield GameWidget(components: () => [ObjectTransform(), Camera()..orthographicSize = 5.0]);
  }
}

class ProjectileBehavior extends Behavior with Tickable, Collidable, OuterScreenCollidable {
  Offset velocity = const Offset(3.0, 2.0);
  int hitCount = 0;
  final List<Color> colors = [Colors.red, Colors.green, Colors.yellow, Colors.purple, Colors.orange];

  @override
  void onUpdate(double dt) {
    final transform = getComponent<ObjectTransform>();
    transform.position += velocity * dt;
  }

  @override
  void onCollision(CollisionEvent event) {
    // Cycle color on hit
    hitCount = (hitCount + 1) % colors.length;
    getComponent<SpriteRenderer>().color = colors[hitCount];
    
    final transform = getComponent<ObjectTransform>();
    final otherPos = event.other.gameObject.getComponent<ObjectTransform>().position;
    final diff = transform.position - otherPos;
    final random = math.Random();

    if (diff.dx.abs() > diff.dy.abs()) {
      if ((velocity.dx > 0 && diff.dx < 0) || (velocity.dx < 0 && diff.dx > 0)) {
        velocity = Offset(-velocity.dx, velocity.dy + (random.nextDouble() - 0.5) * 0.5);
        transform.position += Offset(velocity.dx.sign * 0.1, 0);
      }
    } else {
      if ((velocity.dy > 0 && diff.dy < 0) || (velocity.dy < 0 && diff.dy > 0)) {
        velocity = Offset(velocity.dx + (random.nextDouble() - 0.5) * 0.5, -velocity.dy);
        transform.position += Offset(0, velocity.dy.sign * 0.1);
      }
    }
    velocity = (velocity / velocity.distance) * 3.0;
  }

  @override
  void onOuterScreenEnter() {
    final camera = game.cameras.main;
    final transform = getComponent<ObjectTransform>();
    final tl = camera.screenToWorldPoint(Offset.zero, game.ticker.screenSize);
    final br = camera.screenToWorldPoint(
      Offset(game.ticker.screenSize.width, game.ticker.screenSize.height),
      game.ticker.screenSize,
    );

    final left = math.min(tl.dx, br.dx);
    final right = math.max(tl.dx, br.dx);
    final top = math.max(tl.dy, br.dy);
    final bottom = math.min(tl.dy, br.dy);
    final random = math.Random();

    if (transform.position.dx <= left && velocity.dx < 0) {
      velocity = Offset(-velocity.dx, velocity.dy + (random.nextDouble() - 0.5) * 0.5);
    } else if (transform.position.dx >= right && velocity.dx > 0) {
      velocity = Offset(-velocity.dx, velocity.dy + (random.nextDouble() - 0.5) * 0.5);
    }

    if (transform.position.dy >= top && velocity.dy > 0) {
      velocity = Offset(velocity.dx + (random.nextDouble() - 0.5) * 0.5, -velocity.dy);
    } else if (transform.position.dy <= bottom && velocity.dy < 0) {
      velocity = Offset(velocity.dx + (random.nextDouble() - 0.5) * 0.5, -velocity.dy);
    }
    
    velocity = (velocity / velocity.distance) * 3.0;
  }
}
```
