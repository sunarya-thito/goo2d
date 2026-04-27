---
sidebar_position: 1
---

# Getting Started

Goo2D is a low-level 2D Entity-Component-System (ECS) engine built natively for Flutter. 
It strips away standard UI boilerplate, providing the architectural primitives—GameObjects, Components, Coroutines, and Swept Collision—required to build games directly on the Flutter Canvas.

## Installation

Add Goo2D to your `pubspec.yaml` dependencies:

```yaml
dependencies:
  goo2d: ^1.0.0
```

## Quickstart

Building a game world uses the standard Flutter `build` syntax you already know, paired with a dedicated `onUpdate` game loop.

```dart
import 'package:flutter/material.dart';
import 'package:goo2d/goo2d.dart';

class Player extends StatefulGameWidget {
  const Player({super.key});
  
  @override
  PlayerState createState() => PlayerState();
}

class PlayerState extends GameState<Player> with Tickable {
  @override
  void initState() {
    super.initState();
    // Attach components: position, sprite, and hitbox
    addComponent(
      ObjectTransform()..position = const Offset(0, 0),
      SpriteRenderer()
        ..sprite = GameSprite(
          texture: MyTexture.ship,
          pixelsPerUnit: 64.0,
        ),
      BoxCollisionTrigger()..rect = const Rect.fromLTWH(0, 0, 1, 1),
    );
  }

  @override
  void onUpdate(double dt) {
    // Runs automatically every frame
    final transform = getComponent<ObjectTransform>();
    transform.position += Offset(2 * dt, 0);
  }
}
```

### Mount the Engine

Wrap your game objects inside the `Game` widget. This initializes the core engine loop, input systems, and collision passes.

```dart
void main() {
  runApp(
    const MaterialApp(
      home: Scaffold(
        body: Game(
          child: Player(), 
        ),
      ),
    ),
  );
}
```
