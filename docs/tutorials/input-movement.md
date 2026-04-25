# Tutorial 2: Input and Movement

In the last tutorial, we created a red square. Now, we will make it move using the keyboard.

## 1. Defining the Input Action

First, we need to define an `InputAction` that maps the WASD keys (or Arrow Keys) to a 2D vector. We do this outside of our components, usually globally or in a dedicated input manager.

```dart
final moveAction = InputAction(
  name: 'Move',
  type: InputActionType.value,
  bindings: [
    KeyboardCompositeBinding.wasd(),
    KeyboardCompositeBinding.arrows(),
  ],
);
```

We must explicitly enable the action, perhaps in our `main` function or the `Player`'s `initState`.

```dart
moveAction.enable();
```

## 2. Updating the PlayerState

To make the player move every frame, we need to read the `moveAction` and apply it to the player's `ObjectTransform`.

To run code every frame, we mix `Tickable` directly into our `PlayerState`.

```dart
class PlayerState extends GameState<Player> with Tickable {
  final double speed = 200.0; // pixels per second

  @override
  void initState() {
    moveAction.enable(); // Enable the input action

    addComponent(
      ObjectTransform()..position = const Offset(100, 100),
      RectangleRenderer()..color = Colors.red,
    );
  }

  @override
  void onUpdate(double dt) {
    // 1. Read the input vector
    final input = moveAction.readValue<Vector2>();

    // 2. Get the transform
    final transform = getComponent<ObjectTransform>();

    // 3. Apply the movement (normalized so diagonal movement isn't faster)
    if (input.length > 0) {
      input.normalize();
      transform.position += Offset(input.x, input.y) * speed * dt;
    }
  }

  @override
  Iterable<Widget> build(BuildContext context) sync* {}
}
```

## 3. Run the Game

Run the app again. You can now use `W,A,S,D` or the arrow keys to move the red square around the screen!

Notice how smooth the movement is? That's because we multiply the input by `dt` (delta time), ensuring the movement is frame-rate independent.

[Next Tutorial: Collisions and Screen Bounds ->](collisions-screen.md)
