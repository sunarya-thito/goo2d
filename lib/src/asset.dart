import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart' as soloud;
import 'package:http/http.dart' as http;

/// A dedicated class for asset sources, allowing separation of source from asset logic.
abstract interface class AssetSource {
  /// Loads the raw bytes from the source.
  Future<Uint8List> loadBytes();

  /// A human-readable name for the asset, usually derived from the source.
  String get name;

  /// Creates a [LocalSource] from a bundle [path].
  factory AssetSource.local(String path) = LocalSource;

  /// Creates a [NetworkSource] from a [uri] and optional [headers].
  factory AssetSource.network(Uri uri, {Map<String, String>? headers}) =
      NetworkSource;
}

/// An [AssetSource] that loads data from the local Flutter asset bundle.
class LocalSource implements AssetSource {
  final String path;
  LocalSource(this.path);

  @override
  Future<Uint8List> loadBytes() {
    return rootBundle.load(path).then((data) => data.buffer.asUint8List());
  }

  @override
  String get name => path;
}

/// An [AssetSource] that loads data from a network URL.
class NetworkSource implements AssetSource {
  final Uri uri;
  final Map<String, String>? headers;
  NetworkSource(this.uri, {this.headers});

  @override
  Future<Uint8List> loadBytes() {
    return http
        .get(uri, headers: headers)
        .then((response) => response.bodyBytes);
  }

  @override
  String get name => uri.pathSegments.lastOrNull ?? uri.toString();
}

mixin AssetEnum on Enum implements GameAsset {
  static final Map<Enum, GameAsset> _registries = {};

  /// Creates the actual [GameAsset] instance for this enum value.
  @protected
  GameAsset register();

  /// The underlying [GameAsset] instance.
  GameAsset get asset => _registries.putIfAbsent(this, register);

  @visibleForTesting
  static void reset() {
    _registries.clear();
  }

  @override
  AssetSource get source => asset.source;

  @override
  Future<void> load() => asset.load();

  @override
  bool get isLoaded => asset.isLoaded;

  @override
  void unload() => asset.unload();
}

/// A mixin for [AssetEnum] that represents a texture asset.
mixin TextureAssetEnum on AssetEnum implements GameTexture {
  /// The source of the texture.
  @override
  AssetSource get source;

  @override
  GameAsset register() => GameTexture(source);

  GameTexture get _instance => asset as GameTexture;

  @override
  int get width => _instance.width;

  @override
  int get height => _instance.height;

  @override
  ui.Image get image => _instance.image;

  @override
  Future<void> apply() => _instance.apply();

  @override
  ui.Color getPixel(int x, int y) => _instance.getPixel(x, y);

  @override
  ui.Color getPixelBilinear(double u, double v) =>
      _instance.getPixelBilinear(u, v);

  @override
  Uint8List getPixelData() => _instance.getPixelData();

  @override
  List<ui.Color> getPixels() => _instance.getPixels();

  @override
  Uint32List getPixels32() => _instance.getPixels32();

  @override
  void setPixel(int x, int y, ui.Color color) =>
      _instance.setPixel(x, y, color);

  @override
  void setPixelData(Uint8List data) => _instance.setPixelData(data);

  @override
  void setPixels(List<ui.Color> pixels) => _instance.setPixels(pixels);

  @override
  void setPixels32(Uint32List pixels) => _instance.setPixels32(pixels);
}

/// A mixin for [AssetEnum] that represents an audio asset.
mixin AudioAssetEnum on AssetEnum implements GameAudio {
  /// The source of the audio.
  @override
  AssetSource get source;

  @override
  GameAsset register() => GameAudio(source);

  GameAudio get _instance => asset as GameAudio;

  @override
  soloud.AudioSource get audioSource => _instance.audioSource;
}

class GameAssetProgress {
  final GameAsset loadingAsset;
  final int assetLoaded;
  final int assetCount;

  GameAssetProgress(this.loadingAsset, this.assetLoaded, this.assetCount);

  double get progress => assetLoaded / assetCount;
}

abstract class GameAsset {
  AssetSource get source;

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

  bool get isLoaded;
  Future<void> load();
  void unload();
}

class GameTexture extends GameAsset {
  @override
  final AssetSource source;

  GameTexture(this.source);

  ui.Image? _loadedImage;
  Uint32List? _buffer;
  bool _isDirty = false;

  int get width => _loadedImage?.width ?? 0;
  int get height => _loadedImage?.height ?? 0;

  @override
  bool get isLoaded => _loadedImage != null;

  @override
  Future<void> load() async {
    final bytes = await source.loadBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frameInfo = await codec.getNextFrame();
      _loadedImage = frameInfo.image;
      final byteData = await _loadedImage!.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      _buffer = Uint32List.fromList(byteData!.buffer.asUint32List());
    } finally {
      codec.dispose();
    }
  }

  @override
  void unload() {
    _loadedImage = null;
    _buffer = null;
    _isDirty = false;
  }

  ui.Image get image {
    assert(_loadedImage != null, 'Texture not yet loaded');
    return _loadedImage!;
  }

  /// Unity-parity Apply(). Uploads CPU buffer to GPU image.
  Future<void> apply() async {
    if (!_isDirty || _buffer == null) return;
    final completer = ui.ImmutableBuffer.fromUint8List(
      _buffer!.buffer.asUint8List(),
    );
    final buffer = await completer;
    final descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: width,
      height: height,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    final codec = await descriptor.instantiateCodec();
    final frame = await codec.getNextFrame();
    _loadedImage = frame.image;
    _isDirty = false;
    codec.dispose();
    buffer.dispose();
  }

  ui.Color getPixel(int x, int y) {
    if (_buffer == null) return const ui.Color(0x00000000);
    final pixel = _buffer![y * width + x];
    // RGBA8888 in Uint32List (LE) is 0xAABBGGRR? No, usually it's 0xRRGGBBAA or similar depending on endianness.
    // Flutter's rawRgba is [R, G, B, A] bytes.
    // In a Uint32List on LE: byte 0 is R, 1 is G, 2 is B, 3 is A.
    // So value is 0xAABBGGRR.
    return ui.Color.fromARGB(
      (pixel >> 24) & 0xFF, // A
      pixel & 0xFF, // R
      (pixel >> 8) & 0xFF, // G
      (pixel >> 16) & 0xFF, // B
    );
  }

  ui.Color getPixelBilinear(double u, double v) {
    if (_buffer == null) return const ui.Color(0x00000000);
    final x = u * (width - 1);
    final y = v * (height - 1);
    final x1 = x.floor();
    final y1 = y.floor();
    final x2 = (x1 + 1).clamp(0, width - 1);
    final y2 = (y1 + 1).clamp(0, height - 1);

    final f11 = getPixel(x1, y1);
    final f21 = getPixel(x2, y1);
    final f12 = getPixel(x1, y2);
    final f22 = getPixel(x2, y2);

    final tx = x - x1;
    final ty = y - y1;

    final r1 = _lerpChannel(f11.r * 255, f21.r * 255, tx);
    final r2 = _lerpChannel(f12.r * 255, f22.r * 255, tx);
    final r = _lerpChannel(r1, r2, ty);

    final g1 = _lerpChannel(f11.g * 255, f21.g * 255, tx);
    final g2 = _lerpChannel(f12.g * 255, f22.g * 255, tx);
    final g = _lerpChannel(g1, g2, ty);

    final b1 = _lerpChannel(f11.b * 255, f21.b * 255, tx);
    final b2 = _lerpChannel(f12.b * 255, f22.b * 255, tx);
    final b = _lerpChannel(b1, b2, ty);

    final a1 = _lerpChannel(f11.a * 255, f21.a * 255, tx);
    final a2 = _lerpChannel(f12.a * 255, f22.a * 255, tx);
    final a = _lerpChannel(a1, a2, ty);

    return ui.Color.fromARGB(
      a.round().clamp(0, 255),
      r.round().clamp(0, 255),
      g.round().clamp(0, 255),
      b.round().clamp(0, 255),
    );
  }

  double _lerpChannel(double a, double b, double t) => a + (b - a) * t;

  Uint8List getPixelData() => _buffer!.buffer.asUint8List();

  List<ui.Color> getPixels() {
    if (_buffer == null) return [];
    return List.generate(width * height, (i) {
      final pixel = _buffer![i];
      return ui.Color.fromARGB(
        (pixel >> 24) & 0xFF,
        pixel & 0xFF,
        (pixel >> 8) & 0xFF,
        (pixel >> 16) & 0xFF,
      );
    });
  }

  Uint32List getPixels32() => Uint32List.fromList(_buffer!);

  void setPixel(int x, int y, ui.Color color) {
    if (_buffer == null) return;
    final pixel =
        ((color.a * 255).round().clamp(0, 255) << 24) |
        ((color.b * 255).round().clamp(0, 255) << 16) |
        ((color.g * 255).round().clamp(0, 255) << 8) |
        (color.r * 255).round().clamp(0, 255);
    _buffer![y * width + x] = pixel;
    _isDirty = true;
  }

  void setPixelData(Uint8List data) {
    _buffer = Uint32List.fromList(data.buffer.asUint32List());
    _isDirty = true;
  }

  void setPixels(List<ui.Color> pixels) {
    if (_buffer == null) return;
    for (var i = 0; i < pixels.length; i++) {
      final color = pixels[i];
      _buffer![i] =
          ((color.a * 255).round().clamp(0, 255) << 24) |
          ((color.b * 255).round().clamp(0, 255) << 16) |
          ((color.g * 255).round().clamp(0, 255) << 8) |
          (color.r * 255).round().clamp(0, 255);
    }
    _isDirty = true;
  }

  void setPixels32(Uint32List pixels) {
    _buffer = Uint32List.fromList(pixels);
    _isDirty = true;
  }
}

class GameAudio extends GameAsset {
  @override
  final AssetSource source;

  GameAudio(this.source);

  soloud.AudioSource? _loadedAudioSource;

  @override
  Future<void> load() async {
    final bytes = await source.loadBytes();
    _loadedAudioSource = await soloud.SoLoud.instance.loadMem(
      '$hashCode',
      bytes,
    );
  }

  @override
  bool get isLoaded => _loadedAudioSource != null;

  soloud.AudioSource get audioSource {
    assert(_loadedAudioSource != null, 'Audio not yet loaded');
    return _loadedAudioSource!;
  }

  @override
  void unload() {
    soloud.SoLoud.instance.disposeSource(audioSource);
  }
}
