import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter_soloud/flutter_soloud.dart' as soloud;
import 'package:goo2d/src/component.dart';
import 'package:goo2d/src/lifecycle.dart';
import 'package:goo2d/src/asset.dart';
import 'package:goo2d/src/transform.dart';
import 'package:goo2d/src/ticker.dart';

class AudioListener extends Component {}

class AudioSource extends Behavior implements LifecycleListener, LateTickable {
  GameAudio? clip;
  bool playOnAwake = true;
  bool loop = false;
  double volume = 1.0;
  double pitch = 1.0;
  double panStereo = 0.0;
  double spatialBlend = 1.0;

  soloud.SoundHandle? _handle;
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
      game.audio?.registerHandle(_handle!);
      soloud.SoLoud.instance.setRelativePlaySpeed(_handle!, pitch);
      _update3dParameters();
    }
  }

  void pause() {
    if (_handle != null) {
      soloud.SoLoud.instance.setPause(_handle!, true);
    }
  }

  void unPause() {
    if (_handle != null) {
      soloud.SoLoud.instance.setPause(_handle!, false);
    }
  }

  void stop() {
    if (_handle != null && soloud.SoLoud.instance.isInitialized) {
      if (soloud.SoLoud.instance.getIsValidVoiceHandle(_handle!)) {
        soloud.SoLoud.instance.stop(_handle!);
      }
      game.audio?.unregisterHandle(_handle!);
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
