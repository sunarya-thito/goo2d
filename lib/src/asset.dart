import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart' as soloud;
import 'package:http/http.dart' as http;

/// Defines the contract for how raw binary data is retrieved.
/// 
/// [AssetSource] separates the loading strategy from the asset logic.
/// 
/// ```dart
/// final source = AssetSource.local('path/to/asset');
/// ```
abstract interface class AssetSource {
  /// Loads the raw bytes from the source.
  /// 
  /// This is the primary entry point for fetching data. Implementations should 
  /// handle the specific complexities of their storage medium (e.g., HTTP 
  /// status codes or bundle access errors).
  ///
  /// Returns a [Uint8List] containing the raw data.
  Future<Uint8List> loadBytes();

  /// A human-readable name for the asset, usually derived from the source.
  /// 
  /// Used for debugging, logging, and as a key in various asset registries. 
  /// For local files, this is typically the path; for network files, it is 
  /// often the final segment of the URI.
  String get name;

  /// Creates a [LocalSource] from a bundle [path].
  /// 
  /// Loads assets from the application's compiled resource bundle.
  ///
  /// * [path]: The relative path to the asset in the Flutter bundle.
  factory AssetSource.local(String path) = LocalSource;

  /// Creates a [NetworkSource] from a [uri] and optional [headers].
  /// 
  /// Loads assets from a remote web server via HTTP GET.
  ///
  /// * [uri]: The remote address of the asset.
  /// * [headers]: Optional HTTP headers for the request.
  factory AssetSource.network(Uri uri, {Map<String, String>? headers}) =
      NetworkSource;
}

/// An [AssetSource] that loads data from the local Flutter asset bundle.
/// 
/// [LocalSource] is the standard choice for assets packaged with the game. 
/// It utilizes Flutter's `rootBundle` to efficiently read files from the 
/// application's compiled assets.
///
/// ```dart
/// final source = LocalSource('assets/images/player.png');
/// final bytes = await source.loadBytes();
/// ```
class LocalSource implements AssetSource {
  /// The relative path to the asset.
  /// 
  /// Used by [rootBundle] to locate the resource in the application package.
  final String path;
  
  /// Creates a source pointing to a local asset.
  /// 
  /// Initializes the source with the provided bundle path.
  ///
  /// * [path]: The asset path.
  LocalSource(this.path);

  @override
  Future<Uint8List> loadBytes() {
    return rootBundle.load(path).then((data) => data.buffer.asUint8List());
  }

  @override
  String get name => path;
}

/// An [AssetSource] that loads data from a network URL.
/// 
/// [NetworkSource] allows for dynamic asset loading from remote servers. 
/// This is particularly useful for downloadable content (DLC) or games 
/// with large asset libraries that shouldn't be bundled in the initial binary.
/// 
/// It supports custom HTTP headers for authentication or version tracking.
///
/// ```dart
/// final source = NetworkSource(Uri.parse('https://example.com/map.json'));
/// ```
class NetworkSource implements AssetSource {
  /// The URI of the remote resource.
  /// 
  /// Defines the web address used to fetch the asset data.
  final Uri uri;
  
  /// Optional HTTP headers for the request.
  /// 
  /// Used for authentication or content-negotiation with the server.
  final Map<String, String>? headers;
  
  /// Creates a source pointing to a network URI.
  /// 
  /// Initializes the source with a remote address and optional headers.
  ///
  /// * [uri]: The target URI.
  /// * [headers]: Custom headers for the HTTP request.
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

/// A mixin that provides common registration and loading logic for asset enums.
/// 
/// Enums implementing [AssetEnum] serve as a strongly-typed registry for the 
/// game's assets. This allows developers to reference assets via enum values 
/// (e.g., `GameAssets.playerHero`) instead of error-prone string paths.
/// 
/// The mixin handles caching of the actual [GameAsset] instances, ensuring 
/// that multiple accesses to the same enum member return the same object.
///
/// ```dart
/// enum MyImages with AssetEnum, TextureAssetEnum {
///   player('assets/player.png');
///   final String path;
///   const MyImages(this.path);
///   @override
///   AssetSource get source => AssetSource.local(path);
/// }
/// ```
mixin AssetEnum on Enum implements GameAsset {
  static final Map<Enum, GameAsset> _registries = {};

  /// Creates the actual [GameAsset] instance for this enum value.
  /// 
  /// This must be implemented by the enum to define which specific 
  /// subclass (e.g., [GameTexture], [GameAudio]) should be created.
  @protected
  GameAsset register();

  /// The underlying [GameAsset] instance.
  /// 
  /// Lazily creates the instance via [register] and caches it in a 
  /// static registry map.
  GameAsset get asset => _registries.putIfAbsent(this, register);

  /// Clears all cached asset instances in the registry.
  ///
  /// Use this during testing or when switching between levels to free up 
  /// memory allocated by the registry.
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
/// 
/// Provides convenience accessors that mirror the [GameTexture] API, 
/// allowing developers to manipulate pixels directly on the enum member. 
/// This is particularly powerful for procedurally generated graphics 
/// or dynamic UI elements defined in an enum.
///
/// See also:
/// * [GameTexture] for the underlying texture implementation.
mixin TextureAssetEnum on AssetEnum implements GameTexture {
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
/// 
/// Simplifies access to the [soloud.AudioSource] by delegating to the 
/// internal [GameAudio] instance.
///
/// See also:
/// * [GameAudio] for the underlying audio implementation.
mixin AudioAssetEnum on AssetEnum implements GameAudio {
  @override
  AssetSource get source;

  @override
  GameAsset register() => GameAudio(source);

  GameAudio get _instance => asset as GameAudio;

  @override
  soloud.AudioSource get audioSource => _instance.audioSource;
}

/// Snapshot of the current progress during a batch asset load operation.
/// 
/// Used in [GameAsset.loadAll] to provide UI feedback while the game 
/// prepares its resources. This progress is typically displayed in a 
/// loading screen and tracks [GameAsset] instances.
/// 
/// ```dart
/// final progress = GameAssetProgress(asset, 5, 10);
/// ```
class GameAssetProgress {
  /// The asset currently being processed.
  /// 
  /// Reference to the specific [GameAsset] that triggered this update.
  final GameAsset loadingAsset;
  
  /// Total number of assets already loaded.
  /// 
  /// The count of assets that have completed their loading process.
  final int assetLoaded;
  
  /// Total number of assets in the batch.
  /// 
  /// The size of the asset collection being loaded in this operation.
  final int assetCount;

  /// Creates a progress snapshot.
  /// 
  /// Encapsulates the current state of a batch load operation.
  ///
  /// * [loadingAsset]: The asset currently being loaded.
  /// * [assetLoaded]: The number of completed loads.
  /// * [assetCount]: The total number of assets to load.
  GameAssetProgress(this.loadingAsset, this.assetLoaded, this.assetCount);

  /// Returns the progress ratio from 0.0 to 1.0.
  /// 
  /// Calculated by dividing [assetLoaded] by [assetCount].
  double get progress => assetLoaded / assetCount;
}

/// Base class for all runtime asset instances in the engine.
/// 
/// [GameAsset] manages the lifecycle of heavy resources (Textures, Audio). 
/// It provides hooks for [load] and [unload] to keep memory usage 
/// under control.
/// 
/// ```dart
/// final asset = MyAsset();
/// await asset.load();
/// ```
///
/// See also:
/// * [GameTexture] for image resources.
/// * [GameAudio] for sound resources.
abstract class GameAsset {
  /// The source that defines the asset's raw data origin.
  /// 
  /// Defines how the raw bytes are retrieved (e.g. from disk or network).
  AssetSource get source;

  /// Loads a collection of assets defined by [AssetEnum]s.
  /// 
  /// Iterates over the provided assets and loads them in parallel.
  /// 
  /// ```dart
  /// GameAsset.loadAll(MyAssets.values);
  /// ```
  ///
  /// * [assets]: The collection of asset definitions to process.
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

  /// Indicates if the asset data has been successfully loaded into memory.
  /// 
  /// Returns true if the internal resource (e.g. image or sound) is ready.
  bool get isLoaded;

  /// Triggers the asynchronous loading of asset data.
  /// 
  /// Implementations should use the [source] to fetch data and then 
  /// perform any necessary decoding (e.g. image decompression).
  Future<void> load();

  /// Releases the asset's memory-resident data.
  /// 
  /// Frees up CPU and GPU resources associated with this asset.
  void unload();
}

/// A GPU-resident image used for rendering.
/// 
/// [GameTexture] maintains a dual-state representation of an image. It has a 
/// CPU-side [Uint32List] buffer for high-performance pixel manipulation and 
/// a GPU-side [ui.Image] for rendering.
/// 
/// After modifying pixels via [setPixel], you MUST call [apply] to synchronize 
/// the CPU buffer to the GPU.
///
/// ```dart
/// final tex = GameTexture(AssetSource.local('player.png'));
/// await tex.load();
/// tex.setPixel(0, 0, Colors.red);
/// await tex.apply();
/// ```
class GameTexture extends GameAsset {
  @override
  final AssetSource source;

  /// Creates a texture instance from a [source].
  /// 
  /// Initializes the texture with its data origin.
  ///
  /// * [source]: The data origin for this texture.
  GameTexture(this.source);

  ui.Image? _loadedImage;
  Uint32List? _buffer;
  bool _isDirty = false;

  /// The logical width of the texture in pixels.
  /// 
  /// Represents the horizontal dimension of the loaded image.
  int get width => _loadedImage?.width ?? 0;
  
  /// The logical height of the texture in pixels.
  /// 
  /// Represents the vertical dimension of the loaded image.
  int get height => _loadedImage?.height ?? 0;

  @override
  bool get isLoaded => _loadedImage != null;

  @override
  Future<void> load() async {
    if (isLoaded) return;
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

  /// The GPU-side image representation.
  /// 
  /// Throws an [AssertionError] if the texture hasn't been loaded yet.
  ui.Image get image {
    assert(_loadedImage != null, 'Texture not yet loaded');
    return _loadedImage!;
  }

  /// Unity-parity Apply(). Uploads CPU buffer to GPU image.
  /// 
  /// This operation is relatively expensive as it involves creating a 
  /// new [ui.Image] from the current byte buffer. Only call this after 
  /// finishing a batch of pixel updates.
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

  /// Reads the color of a specific pixel in the CPU buffer.
  /// 
  /// Performs a direct lookup in the internal [Uint32List].
  /// 
  /// * [x]: The horizontal coordinate.
  /// * [y]: The vertical coordinate.
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

  /// Performs bilinear interpolation to read a color.
  /// 
  /// Samples four neighboring pixels to compute a filtered color.
  /// 
  /// * [u]: Normalized horizontal coordinate.
  /// * [v]: Normalized vertical coordinate.
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

  /// Returns the raw CPU buffer as a byte list.
  /// 
  /// Provides the underlying memory as a [Uint8List] for direct I/O.
  Uint8List getPixelData() => _buffer!.buffer.asUint8List();

  /// Returns all pixels in the buffer as a color list.
  /// 
  /// Converts the internal 32-bit buffer into a list of [ui.Color] objects.
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

  /// Returns a copy of the raw 32-bit buffer.
  /// 
  /// Provides direct access to the pixel data as a [Uint32List].
  /// 
  /// This is useful for fast read-only access to the entire texture.
  Uint32List getPixels32() => Uint32List.fromList(_buffer!);

  /// Writes a color to a specific pixel in the CPU buffer.
  /// 
  /// Updates the internal buffer and marks the texture as dirty.
  /// 
  /// * [x]: The horizontal coordinate.
  /// * [y]: The vertical coordinate.
  /// * [color]: The color to write.
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

  /// Overwrites the CPU buffer with raw byte data.
  /// 
  /// Directly replaces the internal storage with the provided bytes.
  /// 
  /// * [data]: The new byte buffer in RGBA8888 format.
  void setPixelData(Uint8List data) {
    _buffer = Uint32List.fromList(data.buffer.asUint32List());
    _isDirty = true;
  }

  /// Sets multiple pixels at once from a list of colors.
  /// 
  /// Batch updates the internal buffer from a color collection.
  /// 
  /// * [pixels]: The list of colors. Must match texture dimensions.
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

  /// Overwrites the CPU buffer with a 32-bit array.
  /// 
  /// Directly replaces the internal storage with the provided pixels.
  /// 
  /// * [pixels]: The new pixel buffer.
  void setPixels32(Uint32List pixels) {
    _buffer = Uint32List.fromList(pixels);
    _isDirty = true;
  }
}

/// A sound resource used for audio playback.
/// 
/// [GameAudio] manages the lifecycle of memory-resident audio sources 
/// using the SoLoud engine.
/// 
/// ```dart
/// final audio = GameAudio(source);
/// await audio.load();
/// ```
class GameAudio extends GameAsset {
  @override
  final AssetSource source;

  /// Creates an audio instance from a [source].
  /// 
  /// Initializes the audio resource with its data origin.
  /// 
  /// * [source]: The data origin for this sound.
  GameAudio(this.source);

  soloud.AudioSource? _loadedAudioSource;

  @override
  Future<void> load() async {
    if (isLoaded) return;
    final bytes = await source.loadBytes();
    _loadedAudioSource = await soloud.SoLoud.instance.loadMem(
      '$hashCode',
      bytes,
    );
  }

  @override
  bool get isLoaded => _loadedAudioSource != null;

  /// The underlying SoLoud audio source.
  /// 
  /// Throws an [AssertionError] if the audio hasn't been loaded yet.
  soloud.AudioSource get audioSource {
    assert(_loadedAudioSource != null, 'Audio not yet loaded');
    return _loadedAudioSource!;
  }

  @override
  void unload() {
    soloud.SoLoud.instance.disposeSource(audioSource);
  }
}
