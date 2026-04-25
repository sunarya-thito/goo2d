# Input System

Goo2D provides a robust, abstracted Input System designed to handle keyboard input, dynamic bindings, and state tracking. 

## The `InputSystem` and `KeyboardDevice`

The `InputSystem` acts as the global registry for all input actions. It updates once per frame during the `GameTicker` pass. 

Under the hood, it uses the Flutter `ServicesBinding` to listen to raw keyboard events and maps them to a global `KeyboardDevice`. This device tracks the state of every `LogicalKeyboardKey` as a `ButtonControl`.

## `InputAction` and Bindings

You rarely interact with raw keys directly. Instead, you create an `InputAction`. An `InputAction` is an abstract representation of an intent (e.g., "Jump", "Move", "Fire").

An `InputAction` is composed of one or more `InputBinding`s. If any binding is active, the action is active.

### `SimpleInputBinding`

A simple binding maps a single control (like a key press) to an action.

```dart
import 'package:flutter/services.dart';
import 'package:goo2d/goo2d.dart';

final jumpAction = InputAction(
  name: 'Jump',
  type: InputActionType.button,
  bindings: [
    KeyboardBinding(LogicalKeyboardKey.space),
    KeyboardBinding(LogicalKeyboardKey.arrowUp),
  ],
);

// Remember to enable it!
jumpAction.enable();
```

### `Vector2CompositeBinding`

A composite binding groups multiple controls into a single value. The most common use case is a 2D movement vector (WASD or Arrow Keys).

```dart
final moveAction = InputAction(
  name: 'Move',
  type: InputActionType.value,
  bindings: [
    KeyboardCompositeBinding.wasd(),
    KeyboardCompositeBinding.arrows(),
  ],
);

moveAction.enable();

// Later, in your update loop:
final movementVector = moveAction.readValue<Vector2>(); 
// Returns a Vector2(x, y) where x and y are between -1 and 1.
```

## Input Action Phases

Actions go through distinct phases:
1. `disabled`: The action is off.
2. `waiting`: The action is enabled but no input is detected.
3. `started`: Input was just detected.
4. `performed`: The input is actively being held or evaluated.
5. `canceled`: The input was released.

You can listen to these phases using the action's `InputEvent`s:

```dart
jumpAction.started + (context) {
  print("Jump started!");
};

jumpAction.canceled + (context) {
  print("Jump released!");
};
```

## Polling Input State

If you don't want to use events, you can poll the state directly in your `onUpdate` loop:

```dart
if (jumpAction.wasPerformedThisFrame) {
  // Jump!
}

if (jumpAction.inProgress) {
  // Charge jump power...
}
```

## Pointer Events

For mouse and touch input, Goo2D hooks into Flutter's hit-testing pipeline. 

By mixing `PointerReceiver` into a `Component` or `GameState`, you can receive raw pointer events. 

```dart
class ClickableComponent extends Component with PointerReceiver {
  @override
  void onPointerDown(PointerDownEvent event) {
    print("Clicked at ${event.localPosition}");
  }

  @override
  void onPointerHover(PointerHoverEvent event) {
    print("Mouse is hovering over the object bounds!");
  }
}
```

> **Note:** Pointer events require the `GameObject` to have a spatial boundary so Flutter knows where to hit-test. You must attach an `ObjectSize` component or a `CollisionTrigger` to the `GameObject` for pointer events to register correctly.
