# Architecture

Goo2D is built on a strict Entity-Component-System (ECS) architecture, heavily inspired by traditional game engines, but adapted to fit naturally within Flutter's widget tree.

## GameObjects and Components

Everything in your game is either a `GameObject` or a `Component`. 

- **`GameObject`**: A container. It has a parent, children, and a list of components. In Goo2D, `GameElement` (created by `GameWidget`) and `StatefulGameElement` (created by `StatefulGameWidget`) act as `GameObject`s.
- **`Component`**: A piece of logic or data attached to a `GameObject`. Components can access their owning `GameObject` via the `gameObject` property. In Goo2D, your `GameState` is also a `Component`.

You can query components attached to a GameObject using:
- `getComponent<T>()` / `tryGetComponent<T>()`
- `getComponents<T>()`
- `getComponentInParent<T>()`
- `getComponentsInChildren<T>()`

## Flutter Integration

Goo2D bridges the gap between ECS and Flutter by making `GameObject`s double as `BuildContext`s and `RenderObjectElement`s. 

- **`GameRenderObject`**: A custom `RenderBox` that intercepts Flutter's painting and hit-testing phases. It applies coordinate transforms and dispatches raw `PointerEvent`s to the `GameObject`'s event system.
- **`GameWidget`**: A stateless widget that creates a `GameElement`. It takes a list of `Component`s.
- **`StatefulGameWidget`**: A stateful widget that creates a `StatefulGameElement` (the `GameObject`) and a `GameState` (a `Component` attached to it).

## The Transform Hierarchy

The `ObjectTransform` component is crucial for spatial positioning. 

If an `ObjectTransform` is attached to a `GameObject`, it automatically discovers its parent's `ObjectTransform` and establishes a transform hierarchy. 

```dart
final transform = getComponent<ObjectTransform>();
transform.localPosition = const Offset(10, 0); // Relative to parent
transform.localAngle = ObjectTransform.degrees(45); // 45 degrees rotation
transform.localScale = const Offset(2, 2); // 2x scale
```

The transform calculates a `localMatrix` and a `worldMatrix`. The `GameRenderObject` uses this `worldMatrix` to automatically push a `TransformLayer` into Flutter's rendering pipeline. This means any drawing done by components is automatically translated, rotated, and scaled correctly!

## Built-in Event Mixins

Goo2D uses a robust event broadcasting system. Events are dispatched to a `GameObject`, which then propagates the event to any `Component`s that implement the required listener mixin.

Because `GameState` implements `Component`, **you can apply these mixins directly to your `GameState`** to listen to events directly without needing extra components.

Here are the built-in mixins:

- `Tickable`: Listens for `onUpdate(double dt)` every frame.
- `Renderable`: Listens for `onPaint(Canvas canvas)` during Flutter's paint phase.
- `PointerReceiver`: Listens for mouse/touch inputs (`onPointerDown`, `onPointerHover`, etc.).
- `LifecycleListener`: Listens for `onMounted` and `onUnmounted` when the component/object is added or removed.
- `Collidable`: Listens for `onCollision(CollisionEvent event)` when `CollisionTrigger`s overlap.
- `ScreenCollidable`: Listens for `onEnterScreen` and `onExitScreen`.
- `OuterScreenCollidable`: Listens for `onOuterScreenEnter` and `onOuterScreenExit`.

## Creating Custom Events and Mixins

You aren't limited to the built-in events. You can create your own custom events and mixins to decouple your game logic.

### 1. Define the Mixin
Create a mixin that implements `EventListener`.

```dart
mixin Damageable implements EventListener {
  void takeDamage(int amount);
}
```

### 2. Define the Event
Create a class extending `Event<YourMixin>`. Implement the `dispatch` method.

```dart
class DamageEvent extends Event<Damageable> {
  final int amount;
  const DamageEvent(this.amount);

  @override
  void dispatch(Damageable listener) {
    listener.takeDamage(amount);
  }
}
```

### 3. Implement and Broadcast

Now you can mix `Damageable` into any component or `GameState`:

```dart
class HealthComponent extends Component with Damageable {
  int health = 100;

  @override
  void takeDamage(int amount) {
    health -= amount;
    print('Health is now $health');
  }
}
```

And broadcast it from anywhere:

```dart
// Hit the player!
playerGameObject.broadcastEvent(const DamageEvent(10));
```
