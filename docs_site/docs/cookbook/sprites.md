---
sidebar_position: 2
---

# Cookbook: Sprite Sheets & Grids

For animations and tilemaps, sprite sheets are more efficient than individual images. This tutorial explains how to slice a texture into a uniform grid and render specific frames using the engine's declarative widget pattern.

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

enum FXTextures with AssetEnum, TextureAssetEnum {
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
        future: GameAsset.loadAll(FXTextures.values).drain(),
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
      texture: FXTextures.explosion,
      columns: 13,
      rows: 1,
      ppu: 64.0, // Each frame is 64x64 pixels
    );
  }
}
```

### 4. Creating the Rendering Loop
Add the `build` method. In Goo2D, the `GameState` uses this method to tell the engine what entities to draw on the screen every frame.

```dart
class MyGameState extends GameState<MyGameWidget> {
  // ... variables and initState ...

  @override
  Iterable<Widget> build(BuildContext context) sync* {
    // Entities will be yielded in the next step
  }
}
```

### 5. Rendering a Specific Frame
Yield the entity using `GameWidget`. We access a specific frame from our sheet using the `[(column, row)]` operator. This allows you to easily switch frames for manual animations or tile picking.

```dart
class MyGameState extends GameState<MyGameWidget> {
  // ... variables and initState ...

  @override
  Iterable<Widget> build(BuildContext context) sync* {
    // Display the 6th frame in the row
    yield GameWidget(
      components: () => [
        ObjectTransform(),
        SpriteRenderer()..sprite = explosionSheet[(5, 0)],
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

enum FXTextures with AssetEnum, TextureAssetEnum {
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
        future: GameAsset.loadAll(FXTextures.values).drain(),
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

  @override
  void initState() {
    super.initState();
    
    explosionSheet = SpriteSheet.grid(
      texture: FXTextures.explosion,
      columns: 13,
      rows: 1,
      ppu: 64.0,
    );
  }

  @override
  Iterable<Widget> build(BuildContext context) sync* {
    yield GameWidget(
      components: () => [
        ObjectTransform(),
        SpriteRenderer()..sprite = explosionSheet[(5, 0)],
      ],
    );
  }
}
```
