---
sidebar_position: 6
---

# Cookbook: Audio & Sound

Goo2D integrates with the high-performance SoLoud audio engine via the `AudioSystem`. This tutorial covers setting up the audio system, playing background music, and triggering spatialized sound effects.

## Live Demo

Click "Play" below and then click inside the game area to trigger sound effects. The background music loops automatically.

<iframe 
  src="/goo2d/play/#/audio" 
  width="100%" 
  height="400px" 
  style={{ border: 'none', borderRadius: '8px', background: '#000' }}
/>

## Assets Used

This tutorial uses placeholder sound files. In a real project, you would use `.wav`, `.ogg`, or `.mp3` files.

| Preview | Asset | Action |
| :--- | :--- | :--- |
| 🎵 | `bgm.wav` | [Download](#) |
| 🔊 | `click.ogg` | [Download](#) |

---

## Tutorial

### 0. Web Setup (Crucial)
The underlying `flutter_soloud` engine requires specific JavaScript files to be initialized when running on the Web. If you skip this, you will see obfuscated console errors and hear no sound.

For more information on Web performance and setup, see the **[Web Platform Guide](../web)**.

#### Add Scripts to `index.html`
Open `web/index.html` and add the following scripts inside the `<body>` tag, **before** the `flutter.js` script:

```html
<!-- Add these lines for Goo2D Audio support -->
<script src="assets/packages/flutter_soloud/web/libflutter_soloud_plugin.js" defer></script>
<script src="assets/packages/flutter_soloud/web/init_module.dart.js" defer></script>
```

#### WASM for Performance
When deploying to web, always use the `--wasm` flag for the best performance and audio synchronization:

```bash
flutter build web --wasm
```

### 1. Asset Setup
Register your audio files in your `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/audios/
```

### 2. Defining Audio Assets
Use the `AssetEnum` and `AudioAssetEnum` mixins to define your sound clips. This provides type-safe access to your audio files throughout the game.

```dart
enum GameSounds with AssetEnum, AudioAssetEnum {
  bgm(type: 'wav'),
  click;

  final String type;
  const GameSounds({this.type = 'ogg'});

  @override
  AssetSource get source => AssetSource.local("assets/audios/$name.$type");
}
```

### 3. Initializing the Audio System
The `AudioSystem` must be initialized before any sounds can be played. This is typically done during the game's pre-loading phase.

```dart
void main() => runApp(const AudioExample());

class AudioExample extends StatelessWidget {
  const AudioExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FutureBuilder(
        future: () async {
          // Initialize the audio engine
          await AudioSystem.initialize();
          // Load specific audio assets
          await GameAsset.loadAll(GameSounds.values).drain();
        }(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return const Game(child: MyGameWidget());
        },
      ),
    );
  }
}
```

### 4. Background Music (BGM)
To play looping background music, add an `AudioSource` component to a persistent GameObject. Setting `loop` to true and `playOnAwake` to true ensures it starts immediately and never stops.

```dart
class MyGameState extends GameState<MyGameWidget> {
  @override
  Iterable<Widget> build(BuildContext context) sync* {
    yield GameWidget(
      key: const GameTag('BGM'),
      components: () => [
        ObjectTransform(),
        AudioSource()
          ..clip = GameSounds.bgm
          ..loop = true
          ..volume = 0.5,
      ],
    );
  }
}
```

### 5. Triggering Sound Effects (SFX)
For one-off sounds like clicks or explosions, set `playOnAwake` to false and trigger the `play()` method from a behavior.

```dart
class MyGameState extends GameState<MyGameWidget> {
  @override
  Iterable<Widget> build(BuildContext context) sync* {
    // ... BGM ...

    yield GameWidget(
      key: const GameTag('SFX'),
      components: () => [
        ObjectTransform(),
        AudioSource()
          ..clip = GameSounds.click
          ..playOnAwake = false, // We will trigger it manually
        ClickBehavior(),
      ],
    );
  }
}

class ClickBehavior extends Behavior with PointerListener {
  @override
  void onPointerDown(PointerDownEvent event) {
    // Trigger the sound
    getComponent<AudioSource>().play();
  }
}
```

### 6. Spatial Audio (The Listener)
For 3D or spatial audio, the engine needs to know where the "ears" are. Attach an `AudioListener` component to your camera or player. Sounds will then be panned and attenuated based on their relative position to the listener.

```dart
// In your build method
yield GameWidget(
  key: const GameTag('MainCamera'),
  components: () => [
    ObjectTransform(),
    Camera(),
    AudioListener(), // This acts as the audio center
  ],
);
```

---

## Full Implementation

```dart
import 'package:flutter/material.dart';
import 'package:goo2d/goo2d.dart';

enum GameSounds with AssetEnum, AudioAssetEnum {
  bgm(type: 'wav'),
  click;

  final String type;
  const GameSounds({this.type = 'ogg'});

  @override
  AssetSource get source => AssetSource.local("assets/audios/$name.$type");
}

void main() => runApp(const AudioExample());

class AudioExample extends StatelessWidget {
  const AudioExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FutureBuilder(
        future: () async {
          await AudioSystem.initialize();
          await GameAsset.loadAll(GameSounds.values).drain();
        }(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return const Game(child: MyGameWidget());
        },
      ),
    );
  }
}

class MyGameWidget extends StatefulGameWidget {
  const MyGameWidget({super.key});
  @override
  GameState<MyGameWidget> createState() => MyGameState();
}

class MyGameState extends GameState<MyGameWidget> {
  @override
  Iterable<Widget> build(BuildContext context) sync* {
    // Background Music
    yield GameWidget(
      key: const GameTag('BGM'),
      components: () => [
        ObjectTransform(),
        AudioSource()
          ..clip = GameSounds.bgm
          ..loop = true
          ..volume = 0.5,
      ],
    );

    // Camera with Listener
    yield GameWidget(
      key: const GameTag('MainCamera'),
      components: () => [
        ObjectTransform(),
        Camera()..orthographicSize = 5,
        AudioListener(),
      ],
    );

    // Interactive SFX
    yield GameWidget(
      key: const GameTag('SFX'),
      components: () => [
        ObjectTransform(),
        AudioSource()
          ..clip = GameSounds.click
          ..playOnAwake = false,
        ClickBehavior(),
      ],
    );
  }
}

class ClickBehavior extends Behavior with PointerListener {
  @override
  void onPointerDown(PointerDownEvent event) {
    getComponent<AudioSource>().play();
  }
}
```
