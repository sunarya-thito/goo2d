import 'dart:math' as math;
import 'package:flutter_soloud/flutter_soloud.dart' as soloud;
import 'package:goo2d/goo2d.dart';

/// A component that acts as the "ears" of a game instance.
/// 3D sounds in the same [GameEngine] will be spatialized relative to this component.
class AudioListener extends Component {}

/// A component that plays a [GameAudio] clip in the game world.
class AudioSource extends Behavior implements LifecycleListener, LateTickable {
  /// The audio clip to play.
  GameAudio? clip;

  /// Whether the audio should start playing automatically when the component is mounted.
  bool playOnAwake = true;

  /// Whether the audio should loop.
  bool loop = false;

  /// The volume of the audio (0.0 to 1.0+).
  double volume = 1.0;

  /// The pitch of the audio (1.0 is normal).
  double pitch = 1.0;

  /// The stereo pan (-1.0 to 1.0). Only used when [spatialBlend] is low.
  double panStereo = 0.0;

  /// Blends between 2D (0.0) and 3D (1.0) audio.
  double spatialBlend = 1.0;

  soloud.SoundHandle? _handle;

  /// Whether the audio is currently playing.
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

  /// Plays the [clip].
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

  /// Pauses the audio.
  void pause() {
    if (_handle != null) {
      soloud.SoLoud.instance.setPause(_handle!, true);
    }
  }

  /// Resumes the audio.
  void unPause() {
    if (_handle != null) {
      soloud.SoLoud.instance.setPause(_handle!, false);
    }
  }

  /// Stops the audio.
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
    if (listenerTransform == null) {
      // Listener has no transform, fallback to center
      soloud.SoLoud.instance.set3dSourceParameters(_handle!, rx, ry, 0, 0, 0, 0);
      return;
    }

    // Calculate relative position
    final sourceWorldPos = transform.position;
    final listenerWorldPos = listenerTransform.position;

    double dx = sourceWorldPos.dx - listenerWorldPos.dx;
    double dy = sourceWorldPos.dy - listenerWorldPos.dy;

    // Rotate relative position by inverse of listener rotation
    final angle = -listenerTransform.angle;
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
