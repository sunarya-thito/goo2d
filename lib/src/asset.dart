import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:http/http.dart' as http;

mixin AssetEnum on Enum implements GameAsset {
  static final Map<Enum, GameAsset> _registries = {};

  /// Creates the actual [GameAsset] instance for this enum value.
  @protected
  GameAsset register();

  /// The underlying [GameAsset] instance.
  GameAsset get _asset => _registries.putIfAbsent(this, register);

  @override
  Future<Uint8List> loadBytes() => _asset.loadBytes();

  @override
  Future<void> load() => _asset.load();

  @override
  String get assetName => _asset.assetName;

  @override
  void unload() => _asset.unload();
}

/// A mixin for [AssetEnum] that represents a local sprite asset.
mixin LocalGameSpriteEnum on AssetEnum implements LocalGameSprite {
  /// The local file path to the sprite.
  @override
  String get path;

  @override
  GameAsset register() => GameSprite.local(path);

  LocalGameSprite get _instance => _asset as LocalGameSprite;

  @override
  ui.Image get image => _instance.image;

  @override
  String get assetName => _instance.assetName;

  @override
  Future<void> load() => _instance.load();

  @override
  void unload() => _instance.unload();

  @override
  Future<Uint8List> loadBytes() => _instance.loadBytes();
}

/// A mixin for [AssetEnum] that represents a network sprite asset.
mixin NetworkGameSpriteEnum on AssetEnum implements NetworkGameSprite {
  /// The URI of the sprite.
  @override
  Uri get uri;

  @override
  GameAsset register() => GameSprite.network(uri);

  NetworkGameSprite get _instance => _asset as NetworkGameSprite;

  @override
  String get assetName => _instance.assetName;

  @override
  ui.Image get image => _instance.image;

  @override
  Future<void> load() => _instance.load();

  @override
  void unload() => _instance.unload();

  @override
  Future<Uint8List> loadBytes() => _instance.loadBytes();
}

/// A mixin for [AssetEnum] that represents a local audio asset.
mixin LocalGameAudioEnum on AssetEnum implements LocalGameAudio {
  /// The local file path to the audio file.
  @override
  String get path;

  @override
  GameAsset register() => GameAudio.local(path);

  LocalGameAudio get _instance => _asset as LocalGameAudio;

  @override
  String get assetName => _instance.assetName;

  @override
  AudioSource get audioSource => _instance.audioSource;

  @override
  Future<void> load() => _instance.load();

  @override
  void unload() => _instance.unload();

  @override
  Future<Uint8List> loadBytes() => _instance.loadBytes();
}

/// A mixin for [AssetEnum] that represents a network audio asset.
mixin NetworkGameAudioEnum on AssetEnum implements NetworkGameAudio {
  /// The URI of the audio file.
  @override
  Uri get uri;

  @override
  GameAsset register() => GameAudio.network(uri);

  NetworkGameAudio get _instance => _asset as NetworkGameAudio;

  @override
  String get assetName => _instance.assetName;

  @override
  AudioSource get audioSource => _instance.audioSource;

  @override
  Future<void> load() => _instance.load();

  @override
  void unload() => _instance.unload();

  @override
  Future<Uint8List> loadBytes() => _instance.loadBytes();
}

class GameAssetProgress {
  final GameAsset? loadingAsset;
  final int assetLoaded;
  final int assetCount;

  GameAssetProgress(this.loadingAsset, this.assetLoaded, this.assetCount);

  double get progress => assetLoaded / assetCount;
}

abstract class GameAsset {
  /// Loads a collection of assets defined by [AssetEnum]s.
  ///
  /// This iterates over the provided [assets], initializes them via their `call()`
  /// method, and loads them asynchronously.
  static Stream<GameAssetProgress> loadAll<T extends AssetEnum>(
    Iterable<AssetEnum> assets,
  ) async* {
    int count = 0;
    for (var asset in assets) {
      await asset.load();
      count++;
      yield GameAssetProgress(asset, count, assets.length);
    }
  }

  String get assetName;
  @protected
  Future<Uint8List> loadBytes();
  Future<void> load();
  void unload();
}

mixin LocalGameAsset on GameAsset {
  String get path;

  @override
  Future<Uint8List> loadBytes() {
    return rootBundle.load(path).then((data) => data.buffer.asUint8List());
  }
}

mixin NetworkGameAsset on GameAsset {
  Uri get uri;

  @override
  Future<Uint8List> loadBytes() {
    return http.get(uri).then((response) => response.bodyBytes);
  }
}

abstract class GameSprite implements GameAsset {
  factory GameSprite.local(String path) = LocalGameSprite;
  factory GameSprite.network(Uri uri) = NetworkGameSprite;
  GameSprite();
  ui.Image? _loadedImage;

  @override
  Future<void> load() async {
    final bytes = await loadBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frameInfo = await codec.getNextFrame();
      _loadedImage = frameInfo.image;
    } finally {
      codec.dispose();
    }
  }

  @override
  void unload() {
    _loadedImage = null;
  }

  ui.Image get image {
    assert(_loadedImage != null, 'Image not yet loaded');
    return _loadedImage!;
  }
}

class LocalGameSprite extends GameSprite with LocalGameAsset {
  @override
  final String path;

  @override
  String get assetName => path;

  LocalGameSprite(this.path);
}

class NetworkGameSprite extends GameSprite with NetworkGameAsset {
  @override
  final Uri uri;

  @override
  String get assetName => uri.pathSegments.lastOrNull ?? uri.toString();

  NetworkGameSprite(this.uri);
}

abstract class GameAudio extends GameAsset {
  factory GameAudio.local(String path) = LocalGameAudio;
  factory GameAudio.network(Uri uri) = NetworkGameAudio;
  GameAudio();
  AudioSource? _loadedAudioSource;

  @override
  Future<void> load() async {
    final bytes = await loadBytes();
    _loadedAudioSource = await SoLoud.instance.loadMem('$hashCode', bytes);
  }

  AudioSource get audioSource {
    assert(_loadedAudioSource != null, 'Audio not yet loaded');
    return _loadedAudioSource!;
  }

  @override
  void unload() {
    SoLoud.instance.disposeSource(audioSource);
  }
}

class LocalGameAudio extends GameAudio with LocalGameAsset {
  @override
  final String path;
  LocalGameAudio(this.path);

  @override
  String get assetName => path;
}

class NetworkGameAudio extends GameAudio with NetworkGameAsset {
  @override
  final Uri uri;

  @override
  String get assetName => uri.pathSegments.lastOrNull ?? uri.toString();

  NetworkGameAudio(this.uri);
}
