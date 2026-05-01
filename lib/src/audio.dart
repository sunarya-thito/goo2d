import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter_soloud/flutter_soloud.dart' as soloud;
import 'package:goo2d/src/component.dart';
import 'package:goo2d/src/game.dart';
import 'package:goo2d/src/object.dart';
import 'package:goo2d/src/lifecycle.dart';
import 'package:goo2d/src/asset.dart';
import 'package:goo2d/src/transform.dart';
import 'package:goo2d/src/camera.dart';
import 'package:goo2d/src/ticker.dart';

/// A component that acts as the "ears" of a game instance.
/// 
/// The [AudioListener] determines the orientation and position from 
/// which sounds in the [GameEngine] are heard. For spatial audio to 
/// function, exactly one [AudioListener] should be active in the 
/// scene, typically attached to the [Camera.main] GameObject.
/// 
/// ```dart
/// mainCamera.addComponent(AudioListener());
/// ```
class AudioListener extends Component {}

/// A component that plays a [GameAudio] clip in the game world.
/// 
/// [AudioSource] provides a comprehensive interface for triggering 
/// and managing sound playback. It supports both standard 2D playback 
/// and spatialized 3D audio that reacts to the relative position and 
/// rotation of an [AudioListener].
/// 
/// The component automatically handles the lifecycle of its sound 
/// handles, ensuring that playback is cleaned up when the component 
/// is unmounted.
/// 
/// ```dart
/// final source = gameObject.addComponent(AudioSource())
///   ..clip = mySoundEffect
///   ..loop = true
///   ..spatialBlend = 1.0;
/// 
/// source.play();
/// ```
class AudioSource extends Behavior implements LifecycleListener, LateTickable {
  /// The audio clip to be played by this source.
  /// 
  /// This must be a [GameAudio] asset loaded via the [AssetSource] 
  /// system. If the clip is not loaded when [play] is called, it 
  /// will be loaded asynchronously before playback begins.
  GameAudio? clip;

  /// Whether the audio should start playing automatically when the component is mounted.
  /// 
  /// When true, the [play] method is invoked during the [onMounted] lifecycle 
  /// hook, provided that a valid [clip] is assigned.
  bool playOnAwake = true;

  /// Whether the audio should loop indefinitely.
  /// 
  /// If enabled, the sound will automatically restart from the beginning 
  /// once it reaches the end, until [stop] or [pause] is called.
  bool loop = false;

  /// The volume level of the playback.
  /// 
  /// Typically ranges from 0.0 (silent) to 1.0 (full volume), though 
  /// values above 1.0 are supported for amplification.
  double volume = 1.0;

  /// The pitch and playback speed of the audio.
  /// 
  /// A value of 1.0 is normal speed. Lower values result in lower 
  /// pitch and slower playback, while higher values increase both.
  double pitch = 1.0;

  /// The stereo panning for 2D audio.
  /// 
  /// Ranges from -1.0 (full left) to 1.0 (full right). This property 
  /// is only significant when [spatialBlend] is 0.0.
  double panStereo = 0.0;

  /// Blends the audio between 2D (0.0) and 3D spatialized (1.0) modes.
  /// 
  /// In 2D mode, the position of the [GameObject] is ignored. In 3D 
  /// mode, the audio is spatialized relative to the active [AudioListener].
  double spatialBlend = 1.0;

  soloud.SoundHandle? _handle;

  /// Indicates whether the audio is currently playing.
  /// 
  /// Returns `true` only if there is a valid, active voice handle 
  /// managed by the underlying `SoLoud` engine.
  bool get isPlaying =>
      _handle != null && soloud.SoLoud.instance.getIsValidVoiceHandle(_handle!);

  @override
  void onMounted() {
    if (playOnAwake && clip != null) {
      play();
    }
  }

  @override
  void onUnmounted() {
    stop();
  }

  /// Starts or restarts playback of the assigned [clip].
  /// 
  /// If the clip is not yet loaded, this method will wait for the 
  /// [GameAudio.load] task to complete. Any existing playback from 
  /// this source is stopped before the new sound begins.
  Future<void> play() async {
    if (clip == null) return;

    // Ensure clip is loaded
    if (!clip!.isLoaded) {
      await clip!.load();
    }

    stop();

    // SoLoud.instance.play is typically synchronous in latest versions
    _handle = soloud.SoLoud.instance.play(
      clip!.audioSource,
      volume: volume,
      paused: false,
      looping: loop,
    );

    if (_handle != null) {
      game.audio.registerHandle(_handle!);
      soloud.SoLoud.instance.setRelativePlaySpeed(_handle!, pitch);
      _update3dParameters();
    }
  }

  /// Pauses the active audio playback.
  /// 
  /// This maintains the current playback position, allowing it to be 
  /// resumed later via [unPause].
  void pause() {
    if (_handle != null) {
      soloud.SoLoud.instance.setPause(_handle!, true);
    }
  }

  /// Resumes playback if the audio was previously paused.
  /// 
  /// The sound continues from the exact position where it was last 
  /// suspended by a call to [pause].
  void unPause() {
    if (_handle != null) {
      soloud.SoLoud.instance.setPause(_handle!, false);
    }
  }

  /// Stops playback and releases the associated voice handle.
  /// 
  /// This method terminates the active voice in the `SoLoud` engine and 
  /// unregisters the handle from the [AudioSystem] to prevent resource leaks.
  void stop() {
    if (_handle != null && soloud.SoLoud.instance.isInitialized) {
      if (soloud.SoLoud.instance.getIsValidVoiceHandle(_handle!)) {
        soloud.SoLoud.instance.stop(_handle!);
      }
      game.audio.unregisterHandle(_handle!);
      _handle = null;
    }
  }

  @override
  void onLateUpdate(double dt) {
    if (isPlaying) {
      _update3dParameters();
    }
  }

  /// Calculates and applies 3D audio parameters relative to the listener.
  /// 
  /// This method performs relative coordinate transformation, rotating 
  /// the source position into the listener's local space to achieve 
  /// accurate directional audio and Doppler-like effects.
  void _update3dParameters() {
    if (_handle == null) return;

    final transform = tryGetComponent<ObjectTransform>();
    if (transform == null) return;

    if (spatialBlend <= 0.0) {
      // 2D Mode
      soloud.SoLoud.instance.setPan(_handle!, panStereo);
      // Reset 3D position to origin so it sounds "center" if somehow it was 3D before
      soloud.SoLoud.instance.set3dSourceParameters(_handle!, 0, 0, 0, 0, 0, 0);
      return;
    }

    // 3D Mode with Relative Positioning
    // Find the listener in this game instance.
    // We check the main camera first, then look for any AudioListener component.
    AudioListener? listener;
    if (game.cameras.isReady) {
      listener = game.cameras.main.gameObject.tryGetComponent<AudioListener>();
    }

    listener ??= game.cameras.allCameras
        .map((c) => c.gameObject.tryGetComponent<AudioListener>())
        .whereType<AudioListener>()
        .firstOrNull;

    if (listener == null) {
      // No listener in this game instance, fallback to "at origin"
      soloud.SoLoud.instance.set3dSourceParameters(_handle!, 0, 0, 0, 0, 0, 0);
      return;
    }

    final listenerTransform = listener.gameObject
        .tryGetComponent<ObjectTransform>();

    // Calculate relative position
    final sourceWorldPos = transform.position;
    final listenerWorldPos = listenerTransform?.position ?? Offset.zero;

    double dx = sourceWorldPos.dx - listenerWorldPos.dx;
    double dy = sourceWorldPos.dy - listenerWorldPos.dy;

    // Rotate relative position by inverse of listener rotation
    final angle = -(listenerTransform?.angle ?? 0.0);
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);

    final rx = dx * cosA - dy * sinA;
    final ry = dx * sinA + dy * cosA;

    // We set velocity to 0 for now as we don't track it explicitly in this simplified version
    soloud.SoLoud.instance.set3dSourceParameters(_handle!, rx, ry, 0, 0, 0, 0);

    // Update other properties if they changed
    soloud.SoLoud.instance.setVolume(_handle!, volume);
    soloud.SoLoud.instance.setRelativePlaySpeed(_handle!, pitch);
  }
}
