# Tutorial 1: Your First Game

In this tutorial, we will set up the foundational structure of a Goo2D game. You will learn how to:
1. Initialize a `GameScene`.
2. Create a custom `Component` that renders a simple colored square using Flutter's `CustomPainter`.
3. Put it all together in a `StatefulGameWidget`.

## 1. Setting up the Game Scene

A `GameScene` is a special Flutter widget that acts as the root of your game. It provides the central ticking clock and manages collision detection passes.

Create a new Flutter project and replace `lib/main.dart` with the following:

```dart
import 'package:flutter/material.dart';
import 'package:goo2d/goo2d.dart';

void main() {
  runApp(
    const MaterialApp(
      home: Scaffold(
        body: GameScene(
          child: Player(), // We will create this next
        ),
      ),
    ),
  );
}
```

## 2. Creating a Custom Renderer Component

Goo2D doesn't enforce a specific rendering pipeline. Since we are in Flutter, we can just use the `Canvas`!

Let's create a custom `Component` that listens to the paint phase and draws a rectangle.

```dart
class RectangleRenderer extends Component with Renderable {
  Color color = Colors.blue;
  Size size = const Size(50, 50);

  @override
  void onPaint(Canvas canvas) {
    final paint = Paint()..color = color;
    canvas.drawRect(Offset.zero & size, paint);
  }
}
```

By mixing in `Renderable`, Goo2D knows to call `onPaint` automatically when Flutter draws this object to the screen.

## 3. The Player GameObject

Now we need to create the `Player` widget that we referenced in step 1.

Because our player will eventually move and manage state, we will use a `StatefulGameWidget`.

```dart
class Player extends StatefulGameWidget {
  const Player({super.key});

  @override
  PlayerState createState() => PlayerState();
}

class PlayerState extends GameState<Player> {
  @override
  void initState() {
    super.initState();
    // We add two components here:
    // 1. ObjectTransform for spatial positioning.
    // 2. Our custom RectangleRenderer to draw it.
    addComponent(
      ObjectTransform()..position = const Offset(100, 100),
      RectangleRenderer()..color = Colors.red,
    );
  }
}
```

## 4. Run the Game

If you run the app now, you should see a red 50x50 square rendered at `(100, 100)` on your screen.

Congratulations! You've successfully built a rendering component and added it to the ECS hierarchy. 

Next, let's learn how to make it move.

[Next Tutorial: Input and Movement ->](input-movement.md)
