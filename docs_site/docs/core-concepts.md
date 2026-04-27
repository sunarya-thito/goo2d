---
sidebar_position: 2
---

# Core Concepts

Goo2D introduces a few key concepts that bridge standard Flutter widget development with a game engine architecture. If you know how `StatefulWidget` works, you already understand most of it.

## The Game Tree

Every object in your game is a `StatefulGameWidget`. Its `build` method uses a `sync*` generator to yield children, which can be other `StatefulGameWidget`s, `GameWidget`s, or normal Flutter widgets.

```dart
class BattleWorld extends StatefulGameWidget {
  @override
  GameState<BattleWorld> createState() => BattleWorldState();
}

class BattleWorldState extends GameState<BattleWorld> {
  @override
  Iterable<Widget> build(BuildContext context) sync* {
    yield const Background();
    yield const Player();
    yield const FPSUI();
  }
}
```

## What is a Component?

A **Component** is a self-contained piece of data or behavior that you attach to a game object. Rather than putting everything into one class, you compose your game objects by attaching multiple small components, each responsible for one thing.

For example:
- `ObjectTransform` — tracks the object's position, rotation, and scale in the game world
- `SpriteRenderer` — draws a sprite onto the game canvas each frame
- `BoxCollisionTrigger` — defines a rectangular hitbox for collision detection
- `AudioSource` — plays a sound clip attached to this object

## Attaching Components (`initState`)

`GameState.initState` is the right place to configure your game object. Use `addComponent` to attach the components it needs.

```dart
class PlayerState extends GameState<Player> {
  @override
  void initState() {
    super.initState();
    addComponent(
      ObjectTransform()..position = Offset.zero,
      SpriteRenderer()
        ..sprite = GameSprite(
          texture: MyTexture.ship,
          pixelsPerUnit: 64.0,
        ),
      OvalCollisionTrigger()
        ..radiusX = 0.2
        ..radiusY = 0.2,
    );
  }

}
```

`SpriteRenderer` draws directly onto the game Canvas. The `build` method is optional — it defaults to returning an empty list, so you only need to override it when you want to add children.

## Inline Game Objects (`GameWidget`)

You don't have to create a `StatefulGameWidget` subclass for every object. For simple, data-driven objects (like bullets or enemies), you can use `GameWidget` and define all components inline:

```dart
// Spawning a bullet inline, no class needed
GameWidget(
  components: () => [
    ObjectTransform()..position = spawnPosition,
    SpriteRenderer()..sprite = bulletSprite,
    BulletController()..direction = facing,
    OvalCollisionTrigger()..radiusX = 0.2,
  ],
);
```

## Behaviors (Logic Components)

A `Behavior` is a type of `Component` designed to hold game logic. Instead of putting all your movement, shooting, and AI code into `GameState`, you split it into separate `Behavior` classes — one per responsibility. This keeps your code easier to read and reuse.

To make a Behavior respond to engine events, you mix in the interfaces you need:

```dart
class BulletController extends Behavior with Tickable, Collidable, LifecycleListener {
  late Offset direction;
  late ObjectTransform _transform;

  @override
  void onMounted() {
    // Called once when the object enters the game tree
    _transform = getComponent<ObjectTransform>();
  }

  @override
  void onUpdate(double dt) {
    // Called every frame automatically
    _transform.position += direction * 15.0 * dt;
  }

  @override
  void onCollision(CollisionEvent collision) {
    // Called when a sibling CollisionTrigger overlaps another
  }
}
```

Behaviors can access sibling components via `getComponent<T>()` and parent components via `getComponentInParent<T>()`.

## Flutter Interoperability

The `Game` widget is a standard Flutter widget. It can be placed anywhere inside a normal Flutter widget tree — inside a `Column`, inside a `Stack`, inside a `Dialog`. The engine does not take over your entire app.

```dart
// A Flutter UI that embeds the game inside a card layout
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text('My Game')),
    body: Column(
      children: [
        Expanded(
          child: Game(
            child: BattleWorld(),
          ),
        ),
        // Normal Flutter widgets can live below the game
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Quit'),
        ),
      ],
    ),
  );
}
```

Conversely, normal Flutter widgets can be yielded directly from any `GameState.build()`. You do not have to use `SpriteRenderer` or custom Canvas rendering for everything. Simple `Container`, `Text`, or `Image` widgets work just fine as children of a `GameWidget`.

## Flutter Widget UI (`build` + `CanvasWidget`)

When you do want to use Flutter widgets (for text, containers, etc.), `build` is the right place. 

*   **With `CanvasWidget`**: Pins the widget to **screen space**. It acts as a HUD or UI overlay that stays fixed regardless of where the camera moves.
*   **Without `CanvasWidget`**: Places the widget directly in **world space**. The widget will be subject to the camera's position and zoom, effectively moving and scaling like any other physical object in the game world.

```dart
class FPSState extends GameState<FPSUI> with Tickable {
  double _fps = 0;

  @override
  void onUpdate(double dt) {
    if (dt > 0) {
      setState(() {
        _fps = _fps * 0.9 + (1.0 / dt) * 0.1;
      });
    }
  }

  @override
  Iterable<Widget> build(BuildContext context) sync* {
    // Wrapped in CanvasWidget to stay fixed on screen
    yield CanvasWidget(
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Text('FPS: ${_fps.round()}'),
      ),
    );
    
    // NOT wrapped - this label will move/zoom with the camera
    yield const Text('In-World Label');
  }
}
```

Note that `setState` here is called inside `onUpdate` to trigger a rebuild with the new values, exactly like a standard Flutter `StatefulWidget`.

### Rendering Order & Layering

The order in which you `yield` widgets in your `build` method strictly determines their **rendering order** (draw order). 

This allows for advanced layering: if you yield a `CanvasWidget` *before* a world-space object, that screen-space UI element will actually appear **behind** the game world. 

```dart
@override
Iterable<Widget> build(BuildContext context) sync* {
  // 1. Rendered first (bottom layer)
  yield CanvasWidget(child: BackgroundUI()); 

  // 2. Rendered on top of the BackgroundUI
  yield const PlayerShip(); 
  
  // 3. Rendered on top of everything
  yield CanvasWidget(child: ForegroundHUD());
}
```

## Asset Management

Goo2D provides a flexible asset system that integrates with Flutter's asset bundle. You typically define your assets using enums:

```dart
enum MySprites with AssetEnum, TextureAssetEnum {
  player,
  enemy;

  @override
  AssetSource get source => AssetSource.local("assets/sprites/$name.png");
}

// Load all assets before starting the game
Future<void> main() async {
  // If we are using audio, we should initialize AudioSystem first.
  // You can skip this if you are not using audio.
  await AudioSystem.initialize();
  
  // Load all textures/sounds and show progress in debug mode
  await for (final p in GameAsset.loadAll(MySprites.values)) {
    if (kDebugMode) {
      print('Loading ${p.loadingAsset.source.name} (${p.assetLoaded}/${p.assetCount})');
    }
  }
  
  runApp(const MaterialApp(home: Game(child: MyGame())));
}
```

## Built-in Mixins (Interfaces)

Goo2D uses mixins to give your components special powers. Instead of complex inheritance, you just "mix in" the functionality you need.

### 1. `Tickable` & `LateTickable`
Gives you access to the engine's update loop. Use `onUpdate` for primary logic and `onLateUpdate` for logic that depends on other objects' positions (like cameras).

```dart
class Mover extends Behavior with Tickable {
  @override
  void onUpdate(double dt) => transform.position += velocity * dt;
}

class SmoothFollow extends Behavior with LateTickable {
  @override
  void onLateUpdate(double dt) => followTarget();
}
```

### 2. `Collidable`
Enables collision detection callbacks. You must also have a `CollisionTrigger` component on the same object.

```dart
class Hazard extends Behavior with Collidable {
  @override
  void onCollision(CollisionEvent event) {
    print('Hit ${event.other.gameObject.tag}');
  }
}
```

### 3. `LifecycleListener`
Provides hooks for when a component enters or leaves the game tree.

```dart
class Spawner extends Behavior with LifecycleListener {
  @override
  void onMounted() => print('Object spawned!');

  @override
  void onUnmounted() => print('Object destroyed!');
}
```

### 4. `ScreenCollidable` & `OuterScreenCollidable`
Automates logic for when objects interact with the screen boundaries (viewport).

*   `ScreenCollidable`: Callbacks for entering or fully exiting the screen.
*   `OuterScreenCollidable`: Callbacks for when an object starts to leave or is fully inside the screen.

```dart
class Bullet extends Behavior with ScreenCollidable {
  @override
  void onExitScreen() => gameObject.destroy(); // Auto-cleanup
}
```

### 5. `Renderable`
For performance-critical visuals like tiled backgrounds, you can bypass Flutter widgets entirely and draw directly on the `Canvas` by mixing `Renderable` into a `Component`:

```dart
import 'dart:ui' as ui;
class TiledBackground extends Component with Renderable {
  @override
  void render(ui.Canvas canvas) {
    // Draw directly on the game canvas using low-level Canvas API
    canvas.drawImageRect(sprite.texture.image, sprite.rect, destRect, paint);
  }
}
```

## Accessing Components

In Goo2D's component-based architecture, logic often needs to interact with other components. **Crucially, the `GameState` of your object is itself a pre-attached component**, meaning you can access your state variables directly from any behavior.

### 1. Sibling Components
Use `getComponent<T>()` to find another component attached to the **same** Game Object. 

```dart
// 1. Define the Widget
class MyPlayer extends StatefulGameWidget {
  const MyPlayer({super.key});

  @override
  GameState<MyPlayer> createState() => MyPlayerState();
}

// 2. Define the State (which is automatically attached as a Component)
class MyPlayerState extends GameState<MyPlayer> {
  int health = 100;
  
  void takeDamage(int amount) {
    setState(() {
      health -= amount;
    });
  }

  @override
  void initState() {
    super.initState();
    // Logic is delegated to separate Behavior components
    addComponent(
      HealthBehavior(),
      SpriteRenderer()..sprite = playerSprite,
    );
  }
}

// 3. Access the State from a sub-Behavior
class HealthBehavior extends Behavior {
  late SpriteRenderer renderer;
  late MyPlayerState playerState;

  @override
  void onMounted() {
    // Sibling lookup: access the renderer
    renderer = getComponent<SpriteRenderer>();
    
    // GameState lookup: access the MyPlayerState component owned by this object
    playerState = getComponent<MyPlayerState>();
  }

  void onDamage() {
    renderer.color = Colors.red;
    playerState.takeDamage(10);
  }
}
```

### 2. Parent & Ancestor Components
Use `getComponentInParent<T>()` to search upwards through the game object hierarchy. This is the standard way for "child" entities (like a bullet) to find and notify "parent" systems (like the world manager).

```dart
class BulletBehavior extends Behavior with ScreenCollidable {
  @override
  void onExitScreen() {
    // Find the world state to remove this bullet
    final world = getComponentInParent<BattleWorldState>();
    world.destroyBullet(gameObject);
  }
}
```

## State Management

Goo2D leverages Flutter's reactive nature for state management. Since every `GameState` is also a Flutter `State`, you can use familiar patterns to keep your game synchronized.

### 1. Local State (setState)
When you want to update the UI or the arrangement of game objects, call `setState()`. This triggers the `build()` method, allowing you to update the world tree reactively.

```dart
class PlayerState extends GameState<Player> {
  int _score = 0;

  void addPoint() {
    setState(() {
      _score++;
    });
  }

  @override
  Iterable<Widget> build(BuildContext context) sync* {
    // Re-yielding widgets with new values when setState is called
    yield Text('Score: $_score');
    
    // You can even conditionally yield game objects
    if (_score > 10) {
      yield const SpecialEffect();
    }
  }
}
```

### 2. Global/Shared State (InheritedWidget)
For data that many objects need to access (like global settings or high-level game state), use `InheritedWidget`. This allows any descendant component to access the data without manual parent-searching.

```dart
// 1. Define the provider
class GameSettings extends InheritedWidget {
  final double difficulty;
  const GameSettings({required this.difficulty, required super.child});

  static GameSettings of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GameSettings>()!;

  @override
  bool updateShouldNotify(GameSettings oldWidget) => difficulty != oldWidget.difficulty;
}

// 2. Wrap your game world
class BattleWorldState extends GameState<BattleWorld> {
  @override
  Iterable<Widget> build(BuildContext context) sync* {
    // 1. Wrap multiple objects using GameWidget
    yield GameSettings(
      difficulty: 2.0,
      child: GameWidget(
        children: [
          const Player(),
          const Enemy(),
        ],
      ),
    );

    // 2. Or wrap a single object directly
    yield GameSettings(
      difficulty: 2.0,
      child: const Player(),
    );
    yield GameSettings(
      difficulty: 2.0,
      child: const Enemy(),
    );
  }
}

// 3. Access anywhere in a descendant build() method
class EnemyState extends GameState<Enemy> {
  @override
  Iterable<Widget> build(BuildContext context) sync* {
    // Find the nearest GameSettings in the game tree
    final difficulty = GameSettings.of(context).difficulty;
    
    yield Text('Strength: ${10 * difficulty}');
  }
}
```

