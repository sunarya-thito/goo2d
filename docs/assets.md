# Asset System

Goo2D features a typed, enum-based asset system that simplifies asset management, registration, and loading. By using enums as keys, you get full autocomplete and type safety throughout your game.

## The Enum Pattern

Instead of referencing assets by strings, you define an `enum` and apply mixins that describe the asset's type and location.

### Defining Assets

To define a set of assets, create an enum that uses `AssetEnum` and a specialized mixin like `LocalGameSpriteEnum`.

```dart
enum MyAssets with AssetEnum, LocalGameSpriteEnum {
  player,
  coin,
  background;

  @override
  String get path => 'assets/images/$name.png';
}
```

### Supported Mixins

- `LocalGameSpriteEnum`: For local image assets.
- `NetworkGameSpriteEnum`: For images loaded from a URL.
- `LocalGameAudioEnum`: For local sound effects and music.
- `NetworkGameAudioEnum`: For remote audio streams.

## Loading Assets

Assets in Goo2D are lazily initialized. To preload them (e.g., during a loading screen), use `GameAsset.loadAll`.

```dart
void main() {
  // Load all assets defined in MyAssets
  GameAsset.loadAll(MyAssets.values).listen((progress) {
    print("Loading: ${progress.progress * 100}%");
  });
}
```

## Using Assets in Components

To use an asset, simply use the enum value directly. Since the enum implements the `GameAsset` interface, it can be passed directly to any component that needs an asset.

```dart
final renderer = SpriteRenderer()
  ..sprite = MyAssets.player;
```

### Accessing Data

Once loaded, you can access the underlying data directly from the enum value:

```dart
// Access the Flutter ui.Image
final image = MyAssets.player.image;

// Access the AudioSource (using flutter_soloud)
final audio = MyAudio.theme.audioSource;
```

## How it Works

The system uses a **Delegation Pattern** combined with a **Singleton Registry**.
1. Each asset mixin (like `LocalGameSpriteEnum`) implements the corresponding `GameAsset` interface (like `GameSprite`).
2. When you access a property like `image`, the mixin internally retrieves the real `GameAsset` instance from a static map (creating it if necessary) and delegates the call to it.
3. This allows enum values to "act" as real asset objects while remaining easily collectible via `MyEnum.values`.

