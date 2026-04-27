---
sidebar_position: 2
---

# Cookbook: Sprite Sheets & Grids

For animations and tilemaps, sprite sheets are more efficient than individual images. This tutorial explains how to slice a texture into a uniform grid and render specific frames using the engine's declarative widget pattern.

## Live Demo

Click "Play" below to see the result. The demo slices a single texture and cycles through frames using a timer in the game loop.

<iframe 
  src="/goo2d/play/#/sprites" 
  width="100%" 
  height="400px" 
  style={{ border: 'none', borderRadius: '8px', background: '#000' }}
/>

## Assets Used

This tutorial uses assets from the [ansimuz Explosion Pack](https://ansimuz.itch.io/explosion-animations-pack).

| Preview | Asset | Action |
| :--- | :--- | :--- |
| ![](/img/cookbook/explosion.png) | `explosion.png` | [Download](/img/cookbook/explosion.png) |

---

## Tutorial

### 0. Asset Setup
Before writing any code, you must register your assets with Flutter.

1.  Create a directory named `assets/sprites/` in your project root.
2.  Place the `explosion.png` file into that directory.
3.  Add the directory to your `pubspec.yaml` file:

```yaml
flutter:
  assets:
    - assets/sprites/
```

### 1. Asset & Scaffolding
Set up the textures and root widget. We pre-load the explosion texture using a `FutureBuilder` to ensure it's available for slicing during initialization.

```dart
import 'package:flutter/material.dart';
import 'package:goo2d/goo2d.dart';

void main() => runApp(const SpriteExample());

enum GameTextures with AssetEnum, TextureAssetEnum {
  explosion;
  @override
  AssetSource get source => AssetSource.local("assets/sprites/$name.png");
}

class SpriteExample extends StatelessWidget {
  const SpriteExample({super.key});

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

### 2. Declaring the Sheet Reference
In your `GameState`, declare a `late final` variable for the `SpriteSheet`. This variable will hold our sliced sub-textures once they are initialized.

```dart
class MyGameWidget extends StatefulGameWidget {
  const MyGameWidget({super.key});
  @override
  GameState<MyGameWidget> createState() => MyGameState();
}

class MyGameState extends GameState<MyGameWidget> {
  // We initialize this sheet once the game state is created
  late final SpriteSheet explosionSheet;
}
```

### 3. Slicing the Texture Grid
Override `initState` to define the grid dimensions. We slice the explosion texture into 13 horizontal frames. The `ppu` (Pixels Per Unit) determines the size of the sprite relative to the world coordinate system.

```dart
class MyGameState extends GameState<MyGameWidget> {
  late final SpriteSheet explosionSheet;

  @override
  void initState() {
    super.initState();
    
    // Create a 13x1 grid from the explosion texture
    explosionSheet = SpriteSheet.grid(
      texture: GameTextures.explosion,
      columns: 13,
      rows: 1,
      ppu: 64.0, // Each frame is 64x64 pixels
    );
  }
}
```

### 4. Creating the Animation Logic
To make the example verifiable, add an `onUpdate` loop that increments the current frame index over time. This creates a running animation that we can see in the demo.

```dart
class MyGameState extends GameState<MyGameWidget> {
  late final SpriteSheet explosionSheet;
  int currentFrame = 0;
  double timer = 0;

  @override
  void onUpdate(double dt) {
    timer += dt;
    if (timer > 0.1) { // Change frame every 100ms
      timer = 0;
      setState(() {
        currentFrame = (currentFrame + 1) % 13;
      });
    }
  }
  
  // ... rest of the class ...
}
```

### 5. Rendering the Sprite
Implement the `build` method to render the entity. We access a specific frame from our sheet using the `[(column, row)]` operator, passing in our dynamic `currentFrame` index.

```dart
class MyGameState extends GameState<MyGameWidget> {
  // ... variables and initState ...

  @override
  Iterable<Widget> build(BuildContext context) sync* {
    yield GameWidget(
      components: () => [
        ObjectTransform(),
        SpriteRenderer()..sprite = explosionSheet[(currentFrame, 0)],
      ],
    );

    // Add a camera to see the world
    yield GameWidget(
      components: () => [
        ObjectTransform(),
        Camera()..orthographicSize = 5.0,
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

void main() => runApp(const SpriteExample());

enum GameTextures with AssetEnum, TextureAssetEnum {
  explosion;
  @override
  AssetSource get source => AssetSource.local("assets/sprites/$name.png");
}

class SpriteExample extends StatelessWidget {
  const SpriteExample({super.key});

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
  late final SpriteSheet explosionSheet;
  int currentFrame = 0;
  double timer = 0;

  @override
  void initState() {
    super.initState();
    explosionSheet = SpriteSheet.grid(
      texture: GameTextures.explosion,
      columns: 13,
      rows: 1,
      ppu: 64.0,
    );
  }

  @override
  void onUpdate(double dt) {
    timer += dt;
    if (timer > 0.1) {
      timer = 0;
      setState(() {
        currentFrame = (currentFrame + 1) % 13;
      });
    }
  }

  @override
  Iterable<Widget> build(BuildContext context) sync* {
    yield GameWidget(
      components: () => [
        ObjectTransform(),
        SpriteRenderer()..sprite = explosionSheet[(currentFrame, 0)],
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
```
