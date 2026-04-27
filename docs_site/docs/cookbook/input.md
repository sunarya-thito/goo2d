---
sidebar_position: 3
---

# Cookbook: Input & Movement

Goo2D uses an action-based input system. Instead of checking for specific keys, you define logical actions (like "move") and bind keys to them. This tutorial explains how to implement 2D movement by creating a dedicated player widget.

## Assets Used

This tutorial uses assets from the [Kenney Pixel Shmup](https://kenney-assets.itch.io/pixel-shmup) pack.

| Preview | Asset | Action |
| :--- | :--- | :--- |
| ![](/img/cookbook/ship.png) | `ship.png` | [Download](/img/cookbook/ship.png) |

---

## Tutorial

### 1. Asset & Scaffolding
Define the textures for the player and set up the main Flutter entry point. We use a `FutureBuilder` to ensure all assets are loaded into GPU memory before the game starts.

```dart
import 'package:flutter/material.dart';
import 'package:goo2d/goo2d.dart';

enum PlayerTextures with AssetEnum, TextureAssetEnum {
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
        future: GameAsset.loadAll(PlayerTextures.values).drain(),
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

### 2. The Player Widget
Create a `StatefulGameWidget` specifically for the player. This pattern allows the player to encapsulate its own components, actions, and movement logic within its corresponding `GameState`.

```dart
class Player extends StatefulGameWidget {
  const Player({super.key});
  @override
  GameState<Player> createState() => PlayerState();
}

class PlayerState extends GameState<Player> with Tickable {
  // Movement logic will be defined here
}
```

### 3. Declaring State Variables
Inside `PlayerState`, declare `late` variables for the `InputAction` and the `ObjectTransform`. These will be initialized in the `initState` method once the engine is ready.

```dart
class PlayerState extends GameState<Player> with Tickable {
  late InputAction moveAction;
  late ObjectTransform playerTransform;

  @override
  void initState() {
    super.initState();
  }
}
```

### 4. Binding Input Actions
In `initState`, use `createInputAction` to define a logical 'move' action. We use `InputBinding.composite` to map the WASD keys to a 2D vector (Offset) that we can read later in the update loop.

```dart
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
    ],
  );
}
```

### 5. Attaching Components
Use the `addComponent` method to attach visuals and a transform to the player entity. We cache the `ObjectTransform` reference so we don't have to look it up every frame during movement.

```dart
@override
void initState() {
  super.initState();
  
  // ... action setup from previous step ...

  addComponent(
    playerTransform = ObjectTransform(),
    SpriteRenderer()..sprite = GameSprite(texture: PlayerTextures.ship),
  );
}
```

### 6. Processing Movement
Override `onUpdate` to read the input vector from our action. We multiply the vector by a speed constant and the frame delta time (`dt`) to ensure frame-rate independent movement.

```dart
@override
void onUpdate(double dt) {
  // Read the current (x, y) input vector
  final dir = moveAction.readValue<Offset>();
  
  // Apply movement to the cached transform
  playerTransform.position += dir * 10.0 * dt;
}
```

### 7. Constructing the Scene
Define the world widget and use the `build` method to yield the `Player` entity. In Goo2D, the game tree is built declaratively using widgets, similar to standard Flutter UI.

```dart
class MyGameWidget extends StatefulGameWidget {
  const MyGameWidget({super.key});
  @override
  GameState<MyGameWidget> createState() => MyGameState();
}

class MyGameState extends GameState<MyGameWidget> {
  @override
  Iterable<Widget> build(BuildContext context) sync* {
    // Yield the player widget into the game world
    yield const Player();
  }
}
```

---

## Full Implementation

```dart
import 'package:flutter/material.dart';
import 'package:goo2d/goo2d.dart';

void main() => runApp(const InputExample());

enum PlayerTextures with AssetEnum, TextureAssetEnum {
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
        future: GameAsset.loadAll(PlayerTextures.values).drain(),
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
    yield const Player();
  }
}

class Player extends StatefulGameWidget {
  const Player({super.key});
  @override
  GameState<Player> createState() => PlayerState();
}

class PlayerState extends GameState<Player> with Tickable {
  late InputAction moveAction;
  late ObjectTransform playerTransform;

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
      ],
    );

    addComponent(
      playerTransform = ObjectTransform(),
      SpriteRenderer()..sprite = GameSprite(texture: PlayerTextures.ship),
    );
  }

  @override
  void onUpdate(double dt) {
    final dir = moveAction.readValue<Offset>();
    playerTransform.position += dir * 10.0 * dt;
  }
}
```
