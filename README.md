# Goo2D

> **⚠️ Under Heavy Development**
>
> Goo2D is currently in an early, active phase of heavy development. The APIs are subject to change rapidly. At this moment, we **may not accept external contributions**, as the core architecture is still being finalized.

Goo2D is an unopinionated 2D Entity-Component-System (ECS) engine built natively for Flutter. It bridges the gap between traditional game loops and Flutter's RenderObject pipeline, providing a clean, object-oriented architecture for building interactive experiences. 

Goo2D provides the low-level architectural primitives (GameObjects, Components, Coroutines, and Swept Collision) that allow you to build whatever mechanics you need, with seamless interoperability with Flutter's widget tree.

## Key Features

- **Strict Entity-Component Architecture**: Everything is a `GameObject` or a `Component`. No magic, just clean composition.
- **Coroutines & Behaviors**: Write asynchronous game logic sequentially using `startCoroutine` and `YieldInstruction`s like `WaitForSeconds` and `WaitUntil`.
- **Comprehensive Input System**: Fully abstracted `InputAction`s, `ButtonControl`s, and composite bindings.
- **Kinematic Sweep-and-Prune Collisions**: Zero-allocation, AABB-based collision detection via `BoxCollisionTrigger` and `OvalCollisionTrigger`.
- **Flutter Native**: `GameScene` and `StatefulGameWidget` integrate perfectly into any Flutter app. Render directly using the Canvas API.
- **Event Dispatching System**: Clean event broadcasting system with built-in mixins (`Tickable`, `PointerReceiver`, `ScreenCollidable`, etc.) that can be applied directly to components or even to the `GameState` itself.

## Getting Started

### 1. Define your GameObject

Create a custom widget extending `StatefulGameWidget` and implement the `GameState`. Because `GameState` acts as a `GameObject`, you can mix in event receivers directly!

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
    addComponent(
      ObjectTransform()..position = const Offset(50, 50),
      BoxCollisionTrigger()..rect = const Rect.fromLTWH(0, 0, 50, 50),
      // RectangleRenderer is a custom component you create
      RectangleRenderer()..color = Colors.blue, 
    );
  }

  @override
  void onUpdate(double dt) {
    // This is called every frame automatically because we mixed in Tickable!
    final transform = getComponent<ObjectTransform>();
    transform.position += Offset(100 * dt, 0); 
  }

  @override
  Iterable<Widget> build(BuildContext context) sync* {
    // You can yield nested Flutter Widgets or other GameObjects here if needed
  }
}
```

### 2. Add it to a GameScene

The `GameScene` provides the root `GameTicker` and initializes the `InputSystem` and `CollisionTrigger` passes.

```dart
void main() {
  runApp(
    const MaterialApp(
      home: Scaffold(
        body: GameScene(
          child: Player(),
        ),
      ),
    ),
  );
}
```

## Documentation

For full documentation and tutorials, please refer to the `docs/` folder or the generated MkDocs site. It covers:
- Core Architecture & Events
- Transform Hierarchy
- Input and Pointer Systems
- Collisions and Screen Bounds
- Coroutines and Lifecycle
- Step-by-step tutorials for building your first game.
