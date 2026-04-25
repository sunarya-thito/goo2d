# Collisions and Screen Bounds

Goo2D implements a zero-allocation, kinematic Sweep-and-Prune collision detection system. It is designed for fast, AABB (Axis-Aligned Bounding Box) intersection checks. 

**Note:** Goo2D is a kinematic engine. It does not resolve physics (like bouncing, gravity, or mass). It only tells you *when* two shapes overlap; it is up to your code to respond to that overlap.

## Colliders

To make an object collidable, attach a `CollisionTrigger` component to it. There are two built-in shapes:
- `BoxCollisionTrigger`: Defined by a `Rect`.
- `OvalCollisionTrigger`: Defined by an X and Y radius.

```dart
final box = BoxCollisionTrigger()
  ..rect = const Rect.fromLTWH(0, 0, 50, 50);

final circle = OvalCollisionTrigger()
  ..radiusX = 25
  ..radiusY = 25
  ..center = const Offset(25, 25);
```

### Layer Filtering

You can filter which objects collide by setting the `layerMask` bitmask. Two colliders will only generate an event if `(a.layerMask & b.layerMask) != 0`. By default, the mask is `0xFFFFFFFF` (collide with everything).

## Collision Events

When two colliders overlap, the engine broadcasts a `CollisionEvent` to both `GameObject`s. 

To listen for these events, mix in `Collidable` to a component or `GameState`.

```dart
class PlayerState extends GameState<PlayerWidget> with Collidable {
  @override
  void onCollision(CollisionEvent event) {
    // 'event.self' is our collider
    // 'event.other' is what we hit
    
    if (event.other.gameObject.tag == 'Enemy') {
      takeDamage();
    }
  }
}
```

## Screen Bounds Detection

Often, you need to know when an object touches the edge of the screen or completely leaves the viewable area (e.g., to destroy a projectile).

Goo2D handles this globally during the `Screen.update()` pass. You can hook into this by mixing in `ScreenCollidable` or `OuterScreenCollidable`.

### `ScreenCollidable`
Fires when the object intersects the screen boundaries.
- `onEnterScreen()`: Fired the moment *any part* of the object's collider enters the screen bounds.
- `onExitScreen()`: Fired the moment the object is *completely outside* the screen bounds.

### `OuterScreenCollidable`
Fires when the object is fully contained within the screen.
- `onOuterScreenEnter()`: Fired the moment *any part* of the object touches the edge from the inside (it is no longer fully contained).
- `onOuterScreenExit()`: Fired the moment the object is *completely inside* the screen bounds.

```dart
class Projectile extends Behavior with ScreenCollidable {
  @override
  void onExitScreen() {
    // Projectile left the screen, destroy it!
    gameObject.active = false; // or remove it from the tree
  }
}
```
