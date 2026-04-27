---
sidebar_position: 6
---

# Cookbook: Coroutines & Sequences

Coroutines allow you to write multi-step logic in a single, linear function without blocking the main game loop. In Goo2D, coroutines are implemented as Dart `async*` streams that the engine processes frame-by-frame.

## Live Demo

Click the screen to trigger the "Boss Sequence" which includes lerping, charging, and firing sub-routines.

<iframe 
  src="/goo2d/play/#/coroutine" 
  width="100%" 
  height="400px" 
  style={{ border: 'none', borderRadius: '8px', background: '#000' }}
/>

## Assets Used

This tutorial uses assets from the [Kenney Pixel Shmup](https://kenney-assets.itch.io/pixel-shmup) pack.

| Preview | Asset | Action |
| :--- | :--- | :--- |
| ![](/img/cookbook/ship.png) | `ship.png` | [Download](/img/cookbook/ship.png) |
| ![](/img/cookbook/tilesPacked.png) | `tilesPacked.png` | [Download](/img/cookbook/tilesPacked.png) |

---

## Tutorial

### 0. Asset Setup
Before writing any code, you must register your assets with Flutter.

1.  Create a directory named `assets/sprites/` in your project root.
2.  Place the `ship.png` and `tilesPacked.png` files into that directory.
3.  Add the directory to your `pubspec.yaml` file:

```yaml
flutter:
  assets:
    - assets/sprites/
```

### 1. Basic Imports & main()
Start by importing the Goo2D package and setting up the application entry point.

```dart
// Add this: ------
import 'package:flutter/material.dart';
import 'package:goo2d/goo2d.dart';

void main() => runApp(const CoroutineExample());
// ----------------
```

Every Goo2D game starts with a `runApp` call that kicks off the Flutter engine and attaches the game world to the widget tree. We import the Goo2D package which contains all the core components and the `Game` widget.

### 2. Defining Textures
Use an `enum` with `AssetEnum` and `TextureAssetEnum` to manage your sprite assets cleanly.

```dart
// ... imports ...

// Add this: ------
enum CoroutineExampleTexture with AssetEnum, TextureAssetEnum {
  ship,
  tilesPacked;
  @override
  AssetSource get source => AssetSource.local("assets/sprites/$name.png");
}
// ----------------
```

This enum acts as a strongly-typed registry for our sprites. The `AssetSource.local` helper automatically maps the enum names to the file paths in your assets folder, ensuring the engine can locate them during the loading phase.

### 3. The Root Widget
Create a `StatefulWidget` that will act as the root of your application and handle asset loading.

```dart
// ... imports & enums ...

// Add this: ------
class CoroutineExample extends StatefulWidget {
  const CoroutineExample({super.key});

  @override
  State<CoroutineExample> createState() => _CoroutineExampleState();
}

class _CoroutineExampleState extends State<CoroutineExample> {
  late final Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = GameAsset.loadAll(CoroutineExampleTexture.values).drain();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: FutureBuilder(
          future: _loadFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            return const Game(child: CoroutineWorld());
          },
        ),
      ),
    );
  }
}
// ----------------
```

`GameAsset.loadAll().drain()` is a critical step that waits for the asynchronous image decoding process to complete. By using a `FutureBuilder`, we ensure that the game world only appears once all textures are safely uploaded to the GPU.

### 4. Empty Game World
Define the `StatefulGameWidget` and its corresponding `GameState`.

```dart
// ... enum definitions ...

// Add this: ------
class CoroutineWorld extends StatefulGameWidget {
  const CoroutineWorld({super.key});
  @override
  GameState<CoroutineWorld> createState() => _CoroutineWorldState();
}

class _CoroutineWorldState extends GameState<CoroutineWorld> {
  @override
  Iterable<Widget> build(BuildContext context) sync* {
  }
}
// ----------------
```

The `CoroutineWorld` widget serves as the primary container for the game simulation. It utilizes a `GameState` to manage the game lifecycle and provide a reactive environment for our components and coroutines.

### 5. State Properties & Initialization
We need variables to track the game state, including a specific transform for the boss ship.

```dart
class _CoroutineWorldState extends GameState<CoroutineWorld> {
  // Add this: ------
  String _message = 'Tap anywhere to Start';
  final List<Widget> _lasers = [];
  final ObjectTransform _bossTransform = ObjectTransform();

  @override
  void initState() {
    super.initState();
    addComponent(ObjectTransform()); // Anchor at origin
    _bossTransform.position = const Offset(0, -8); // Hide below screen
  }
  // ----------------

  @override
  Iterable<Widget> build(BuildContext context) sync* {
  }
}
```

We initialize `_bossTransform` at a position off-screen to keep the ship hidden during the initial loading phase. The `_lasers` list is prepared to store dynamic projectile widgets that will be spawned later in the tutorial.

### 6. Adding the Camera
Every game world needs a camera to define the viewport and background color.

```dart
class _CoroutineWorldState extends GameState<CoroutineWorld> {
  // ... state properties ...

  @override
  Iterable<Widget> build(BuildContext context) sync* {
    // Add this: ------
    yield GameWidget(
      components: () => [
        ObjectTransform(),
        Camera()
          ..depth = 1
          ..backgroundColor = const Color(0xFF0F0F0F)
          ..orthographicSize = 5,
      ],
    );
    // ----------------
  }
}
```

The `Camera` component defines how world coordinates are mapped to screen pixels. By setting `orthographicSize = 5`, we establish a view where 5 world units correspond to the distance from the screen center to the top or bottom edge.

### 7. Rendering the Boss
Add the boss ship to the game world using its dedicated transform and a `SpriteRenderer`.

```dart
class _CoroutineWorldState extends GameState<CoroutineWorld> {
  // ... state properties ...

  @override
  Iterable<Widget> build(BuildContext context) sync* {
    yield GameWidget(
      components: () => [
        ObjectTransform(),
        Camera()
          ..depth = 1
          ..backgroundColor = const Color(0xFF0F0F0F)
          ..orthographicSize = 5,
      ],
    );

    // Add this: ------
    yield GameWidget(
      components: () => [
        _bossTransform, 
        SpriteRenderer()...sprite = GameSprite(texture: CoroutineExampleTexture.ship, pixelsPerUnit: 32),
      ],
    );
    // ----------------
  }
}
```

We link the `SpriteRenderer` to the `_bossTransform` object created earlier. This connection ensures that any changes we make to the transform's position or scale in our coroutines will be reflected immediately on screen.

### 8. Adding the HUD & GestureDetector
We use a `CanvasWidget` to detect taps and use `stopAllCoroutines` to ensure a clean restart.

```dart
class _CoroutineWorldState extends GameState<CoroutineWorld> {
  // ... state properties ...

  @override
  Iterable<Widget> build(BuildContext context) sync* {
    // ... camera and boss widgets ...
    yield* _lasers;

    // Add this: ------
    yield CanvasWidget(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          // Stop all active instances of these routines
          stopAllCoroutines(bossSequence);
          stopAllCoroutines(fireLasers);

          setState(() {
            _lasers.clear();
            _bossTransform.position = const Offset(0, -8);
            _bossTransform.scale = const Offset(1, 1);
            startCoroutine(bossSequence);
          });
        },
        child: Container(
          color: Colors.transparent,
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 80),
          child: Text(
            _message, 
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
          ),
        ),
      ),
    );
    // ----------------
  }

  // Add this: ------
  Stream bossSequence() async* {
  }
  // ----------------
}
```

`stopAllCoroutines` is a function that clears every running instance of a specific generator function. This is essential when restarting sequences, as it ensures that parallel sub-routines (like firing lasers) don't continue to run in the background.

### 9. Linear Movement (Lerping)
Implement the boss's smooth entrance using linear interpolation and the engine's frame ticker.

```dart
class _CoroutineWorldState extends GameState<CoroutineWorld> {
  // ... existing code ...

  Stream bossSequence() async* {
    // Add this: ------
    setState(() => _message = 'Boss Appearing...');

    final startPos = const Offset(0, -8);
    final endPos = Offset.zero;
    double elapsed = 0;
    
    while (elapsed < 1.5) {
      elapsed += game.ticker.deltaTime;
      final t = (elapsed / 1.5).clamp(0.0, 1.0);
      
      _bossTransform.position = Offset.lerp(
        startPos, 
        endPos, 
        Curves.easeOutBack.transform(t)
      )!;
      
      yield null; // Wait for next frame
    }
    // ----------------
  }
}
```

We multiply our elapsed time by `game.ticker.deltaTime` to ensure the movement speed is consistent regardless of the device's refresh rate. Yielding `null` pauses the coroutine, allowing other game systems to run before resuming on the next frame.

### 10. Charge Effect Logic
Create a sub-routine that handles a pulsing visual effect by scaling the boss ship.

```dart
class _CoroutineWorldState extends GameState<CoroutineWorld> {
  // ... existing code ...

  // Add this: ------
  Stream chargeEffect() async* {
    for (int i = 0; i < 15; i++) {
      _bossTransform.scale = Offset(1.0 + i * 0.05, 1.0 + i * 0.05);
      yield WaitForSeconds(0.04);
    }
    for (int i = 15; i >= 0; i--) {
      _bossTransform.scale = Offset(1.0 + i * 0.05, 1.0 + i * 0.05);
      yield WaitForSeconds(0.04);
    }
  }
  // ----------------

  Stream bossSequence() async* {
    // ... lerp logic ...
    
    // Add this: ------
    _message = 'Charging Energy...';
    yield* chargeEffect();
    // ----------------
  }
}
```

The `chargeEffect` sub-routine demonstrates how to build modular animations using simple loops and `yield*`. This delegation pauses the main `bossSequence` until the child routine has finished its pulsing animation.

### 11. Dual Laser Routine with Options
Define a routine that accepts a set of options (like color) and spawns laser bolts accordingly.

```dart
class _CoroutineWorldState extends GameState<CoroutineWorld> {
  // ... existing code ...

  // Add this: ------
  void addLaser(Widget laser) => setState(() => _lasers.add(laser));

  Stream fireLasers(({Color color}) options) async* {
    while (true) {
      final leftWing = _bossTransform.position + const Offset(-0.3, -0.5);
      final rightWing = _bossTransform.position + const Offset(0.3, -0.5);

      addLaser(Laser(key: UniqueKey(), startPos: leftWing, color: options.color));
      addLaser(Laser(key: UniqueKey(), startPos: rightWing, color: options.color));

      yield WaitForSeconds(0.15);
    }
  }
  // ----------------
}
```

Coroutines in Goo2D can accept a single argument, which is often a Dart record (tuple). This allows you to pass configuration data into your logic loops without cluttering the global state or using complex class constructors.

### 12. Parallel Firing with Options
Use `startCoroutineWithOption` to begin the background firing logic while passing in specific parameters.

```dart
class _CoroutineWorldState extends GameState<CoroutineWorld> {
  // ... existing code ...

  Stream bossSequence() async* {
    // ... lerp & charge ...

    // Add this: ------
    _message = 'Firing Lasers!\n(Press SPACE to Stop)';
    startCoroutineWithOption(fireLasers, option: (color: Colors.redAccent));

    double timer = 0;
    while (timer < 8.0 && !game.input.keyboard.space.isPressed) {
      timer += game.ticker.deltaTime;
      yield null;
    }

    stopAllCoroutines(fireLasers);
    _message = 'Sequence Complete!';
    yield WaitForSeconds(2.0);

    setState(() => _message = 'Tap anywhere to Restart');
    // ----------------
  }
}
```

`startCoroutineWithOption` is the engine-level helper for triggering routines that require external parameters. In this case, we pass a red color record to the firing sequence, which the `fireLasers` routine then uses to tint the generated projectiles.

:::caution[CRITICAL: Coroutine Lifecycle]

#### Handling Sub-routines
Starting a background routine from within a parent coroutine creates an independent lifecycle.

*   **❌ The Problem (Zombie Tasks)**
    ```dart
    Stream bossSequence() async* {
      // Logic starts a parallel firing routine
      startCoroutine(fireLasers); 
      yield WaitForSeconds(10);
    }

    // Somewhere else in your code...
    onTap: () {
      // BUG: This only stops the bossSequence itself.
      // The 'fireLasers' task started inside it continues to run forever!
      stopAllCoroutines(bossSequence); 
      
      startCoroutine(bossSequence); // Now you have TWO firing routines!
    }
    ```
*   **✅ The Solution (Explicit Cleanup)**
    ```dart
    onTap: () {
      // SUCCESS: Explicitly stop all instances of the child routine as well.
      stopAllCoroutines(bossSequence);
      stopAllCoroutines(fireLasers); 
      
      startCoroutine(bossSequence);
    }
    ```

#### Starting Coroutines
A coroutine is a generator; calling the function does not run the code.

*   **❌ The Wrong Way (Silent Fail)**
    ```dart
    void start() {
      bossSequence(); // BUG: Function called, but code never executes!
    }
    ```
*   **✅ The Right Way**
    ```dart
    void start() {
      startCoroutine(bossSequence); // SUCCESS: Logic begins processing
    }
    ```

#### Delegation vs Backgrounding
Choose the right keyword depending on whether the parent should wait.

*   **❌ The Wrong Way (Unintended Parallelism)**
    ```dart
    Stream bossSequence() async* {
      yield chargeEffect(); // BUG: current routine finishes immediately while chargeEffect runs
    }
    ```
*   **✅ The Right Way (Sequential)**
    ```dart
    Stream bossSequence() async* {
      yield* chargeEffect(); // SUCCESS: current routine waits for chargeEffect to finish
    }
    ```

Always use `stopAllCoroutines(method)` to ensure parallel background tasks are terminated when restarting or switching scenes.
:::

### 13. The Laser Widget
Define the `Laser` class and include a color property to support dynamic tinting.

```dart
// Add this: ------
class Laser extends StatefulGameWidget {
  final Offset startPos;
  final Color color;
  const Laser({super.key, required this.startPos, required this.color});
  @override
  GameState<Laser> createState() => _LaserState();
}

class _LaserState extends GameState<Laser> {
  @override
  Iterable<Widget> build(BuildContext context) sync* {
  }
}
// ----------------
```

By adding a `color` property to the `Laser` widget, we allow the parent coroutine to control the visual appearance of each spawned projectile. This data is passed through the widget constructor and accessed via the `widget` getter in the state.

### 14. Laser Movement & Self-Destruction
Implement the laser's movement logic and ensure it cleans up after itself when it leaves the screen.

```dart
class _LaserState extends GameState<Laser> {
  @override
  void initState() {
    super.initState();
    // Add this: ------
    addComponent(ObjectTransform()..position = widget.startPos);
    startCoroutine(move);
    // ----------------
  }

  // Add this: ------
  Stream move() async* {
    final trans = getComponent<ObjectTransform>();
    final world = getComponentInParent<_CoroutineWorldState>();

    while (trans.position.dy > -10) {
      trans.position += const Offset(0, -15.0) * game.ticker.deltaTime;
      yield null;
    }
    world.removeLaser(widget);
  }
  // ----------------

  @override
  Iterable<Widget> build(BuildContext context) sync* {
  }
}
```

In the `move` routine, we access the parent `CoroutineWorld` state to remove the laser once it travels past the screen boundary. This pattern of "self-destructing" components prevents memory leaks and performance degradation over time.

### 15. Laser Rendering with Dynamic Color
Finally, add the `SpriteRenderer` and apply the color passed down from the parent routine.

```dart
class _LaserState extends GameState<Laser> {
  // ... existing code ...

  @override
  Iterable<Widget> build(BuildContext context) sync* {
    // Add this: ------
    yield GameWidget(
      components: () => [
        ObjectTransform()..scale = const Offset(0.3, 1.5),
        SpriteRenderer()
          ..sprite = SpriteSheet.grid(texture: CoroutineExampleTexture.tilesPacked, rows: 10, columns: 12, ppu: 64.0)[(0, 0)]
          ..color = widget.color,
      ],
    );
    // ----------------
  }
}
```

The `SpriteRenderer`'s `color` property is set directly from `widget.color`. This ensures that every laser spawned by the `fireLasers` routine will accurately reflect the configuration provided when the coroutine was started.

---

## Full Implementation

```dart
import 'package:flutter/material.dart';
import 'package:goo2d/goo2d.dart';

void main() => runApp(const CoroutineExample());

enum CoroutineExampleTexture with AssetEnum, TextureAssetEnum {
  ship,
  tilesPacked;
  @override
  AssetSource get source => AssetSource.local("assets/sprites/$name.png");
}

class CoroutineExample extends StatefulWidget {
  const CoroutineExample({super.key});

  @override
  State<CoroutineExample> createState() => _CoroutineExampleState();
}

class _CoroutineExampleState extends State<CoroutineExample> {
  late final Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = GameAsset.loadAll(CoroutineExampleTexture.values).drain();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: FutureBuilder(
          future: _loadFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }
            return const Game(child: CoroutineWorld());
          },
        ),
      ),
    );
  }
}

class CoroutineWorld extends StatefulGameWidget {
  const CoroutineWorld({super.key});
  @override
  GameState<CoroutineWorld> createState() => _CoroutineWorldState();
}

class _CoroutineWorldState extends GameState<CoroutineWorld> {
  String _message = 'Tap anywhere to Start';
  final List<Widget> _lasers = [];
  final ObjectTransform _bossTransform = ObjectTransform();

  @override
  void initState() {
    super.initState();
    addComponent(ObjectTransform());
    _bossTransform.position = const Offset(0, -8);
  }

  void addLaser(Widget laser) => setState(() => _lasers.add(laser));
  void removeLaser(Widget laser) => setState(() => _lasers.remove(laser));

  Stream bossSequence() async* {
    setState(() => _message = 'Boss Appearing...');

    final startPos = const Offset(0, -8);
    final endPos = Offset.zero;
    double elapsed = 0;
    while (elapsed < 1.5) {
      elapsed += game.ticker.deltaTime;
      final t = (elapsed / 1.5).clamp(0.0, 1.0);
      _bossTransform.position = Offset.lerp(
        startPos,
        endPos,
        Curves.easeOutBack.transform(t),
      )!;
      yield null;
    }

    _message = 'Charging Energy...';
    yield* chargeEffect();

    _message = 'Firing Lasers!\n(Press SPACE to Stop)';
    startCoroutineWithOption(fireLasers, option: (color: Colors.redAccent));

    double timer = 0;
    while (timer < 8.0 && !game.input.keyboard.space.isPressed) {
      timer += game.ticker.deltaTime;
      yield null;
    }

    stopAllCoroutines(fireLasers);
    _message = 'Sequence Complete!';
    yield WaitForSeconds(2.0);

    setState(() => _message = 'Tap anywhere to Restart');
  }

  Stream chargeEffect() async* {
    for (int i = 0; i < 15; i++) {
      _bossTransform.scale = Offset(1.0 + i * 0.05, 1.0 + i * 0.05);
      yield WaitForSeconds(0.04);
    }
    for (int i = 15; i >= 0; i--) {
      _bossTransform.scale = Offset(1.0 + i * 0.05, 1.0 + i * 0.05);
      yield WaitForSeconds(0.04);
    }
  }

  Stream fireLasers(({Color color}) options) async* {
    while (true) {
      final leftWing = _bossTransform.position + const Offset(-0.3, -0.5);
      final rightWing = _bossTransform.position + const Offset(0.3, -0.5);

      addLaser(Laser(key: UniqueKey(), startPos: leftWing, color: options.color));
      addLaser(Laser(key: UniqueKey(), startPos: rightWing, color: options.color));

      yield WaitForSeconds(0.15);
    }
  }

  @override
  Iterable<Widget> build(BuildContext context) sync* {
    yield GameWidget(
      components: () => [
        ObjectTransform(),
        Camera()
          ..depth = 1
          ..backgroundColor = const Color(0xFF0F0F0F)
          ..orthographicSize = 5,
      ],
    );

    yield GameWidget(
      components: () => [
        _bossTransform,
        SpriteRenderer()
          ..sprite = GameSprite(texture: CoroutineExampleTexture.ship, pixelsPerUnit: 32),
      ],
    );

    yield* _lasers;

    yield CanvasWidget(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          // Stop all active instances of these routines
          stopAllCoroutines(bossSequence);
          stopAllCoroutines(fireLasers);

          setState(() {
            _lasers.clear();
            _bossTransform.position = const Offset(0, -8);
            _bossTransform.scale = const Offset(1, 1);
            startCoroutine(bossSequence);
          });
        },
        child: Container(
          color: Colors.transparent,
          padding: const EdgeInsets.only(top: 80),
          alignment: Alignment.topCenter,
          child: Text(
            _message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(blurRadius: 10, color: Colors.black),
                Shadow(blurRadius: 2, color: Colors.blueAccent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Laser extends StatefulGameWidget {
  final Offset startPos;
  final Color color;
  const Laser({super.key, required this.startPos, required this.color});
  @override
  GameState<Laser> createState() => _LaserState();
}

class _LaserState extends GameState<Laser> {
  @override
  void initState() {
    super.initState();
    addComponent(ObjectTransform()..position = widget.startPos);
    startCoroutine(move);
  }

  Stream move() async* {
    final trans = getComponent<ObjectTransform>();
    final world = getComponentInParent<_CoroutineWorldState>();

    while (trans.position.dy > -10) {
      trans.position += const Offset(0, -15.0) * game.ticker.deltaTime;
      yield null;
    }
    world.removeLaser(widget);
  }

  @override
  Iterable<Widget> build(BuildContext context) sync* {
    yield GameWidget(
      components: () => [
        ObjectTransform()..scale = const Offset(0.3, 1.5),
        SpriteRenderer()
          ..sprite = SpriteSheet.grid(texture: CoroutineExampleTexture.tilesPacked, rows: 10, columns: 12, ppu: 64.0)[(0, 0)]
          ..color = widget.color,
      ],
    );
  }
}
```
