# Tutorial 3: Collisions and Screen Bounds

Our red square can move freely, but it can fly right off the screen. Let's fix that by adding a collider and using the screen bounds detection system.

## 1. Adding a CollisionTrigger

To interact with the collision system, our player needs a `CollisionTrigger`.

Update the `initState` of `PlayerState` to include a `BoxCollisionTrigger` that matches the size of our rendered rectangle.

```dart
@override
void initState() {
  moveAction.enable(); 

  addComponent(
    ObjectTransform()..position = const Offset(100, 100),
    BoxCollisionTrigger()..rect = const Rect.fromLTWH(0, 0, 50, 50), // ADDED
    RectangleRenderer()..color = Colors.red,
  );
}
```

## 2. Preventing Screen Exit

We want the player to stop moving if they hit the edge of the screen.

Goo2D provides the `ScreenCollidable` mixin. By adding it to `PlayerState`, we can listen for `onExitScreen` and `onEnterScreen`. However, the better mixin for clamping inside a screen is usually `OuterScreenCollidable`, which triggers when you try to leave the inside of the screen.

For simplicity, let's just clamp the position manually in `onUpdate` by using the `Screen` dimensions, or we can use the mixin to bounce. Let's use the mixin to turn the square blue when it touches the edge!

```dart
// Mix in OuterScreenCollidable
class PlayerState extends GameState<Player> with Tickable, OuterScreenCollidable {
  final double speed = 200.0;
  
  @override
  void onOuterScreenEnter() {
    // Fired when the player touches the edge of the screen from the inside
    getComponent<RectangleRenderer>().color = Colors.blue;
  }

  @override
  void onOuterScreenExit() {
    // Fired when the player is fully back inside the screen
    getComponent<RectangleRenderer>().color = Colors.red;
  }
  
  // ... rest of the code
}
```

## 3. Detecting Object Collisions

Let's imagine we spawn an enemy somewhere.

```dart
class Enemy extends GameWidget {
  Enemy({super.key}) : super(components: () => [
    ObjectTransform()..position = const Offset(300, 300),
    BoxCollisionTrigger()..rect = const Rect.fromLTWH(0, 0, 50, 50),
    RectangleRenderer()..color = Colors.green,
  ]);
}
```

Add the enemy to your `GameScene` in `main.dart`:

```dart
body: GameScene(
  child: Stack(
    children: [
      const Player(),
      Enemy(),
    ],
  ),
),
```

Now, make the player detect the collision by mixing in `Collidable`:

```dart
class PlayerState extends GameState<Player> with Tickable, OuterScreenCollidable, Collidable {
  
  // ... other methods ...

  @override
  void onCollision(CollisionEvent event) {
    // event.other is the collider we hit.
    // If we hit the green square, let's change our color to yellow!
    getComponent<RectangleRenderer>().color = Colors.yellow;
  }
}
```

Now, when you drive the red square into the green square, it will turn yellow!

[Next Tutorial: Coroutines and Game Logic ->](coroutines-logic.md)
