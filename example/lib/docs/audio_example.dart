import 'package:flutter/material.dart';
import 'package:goo2d/goo2d.dart';

enum AudioExampleSound with AssetEnum, AudioAssetEnum {
  bgm,
  click,
  ;

  @override
  AssetSource get source => AssetSource.local('assets/audios/$name.ogg');
}

class AudioExample extends StatefulGameWidget {
  const AudioExample({super.key});

  @override
  GameState<AudioExample> createState() => _AudioExampleState();
}

class _AudioExampleState extends GameState<AudioExample> {
  @override
  Iterable<Widget> build(BuildContext context) sync* {
    const mainCamera = GameTag('MainCamera');

    // Background Music
    yield GameWidget(
      key: const GameTag('BGM'),
      components: [
        ObjectTransform.new,
        AudioSource.new.withParams((c) => c
          ..clip = AudioExampleSound.bgm
          ..loop = true
          ..volume = 0.5),
      ],
    );

    // Audio Listener (attached to camera)
    yield GameWidget(
      key: mainCamera,
      components: [
        ObjectTransform.new,
        Camera.new.withParams((c) => c..orthographicSize = 5),
        AudioListener.new,
      ],
    );

    // Clickable Sound Object
    yield GameWidget(
      key: const GameTag('SFX'),
      components: [
        ObjectTransform.new,
        AudioSource.new.withParams((c) => c
          ..clip = AudioExampleSound.click
          ..playOnAwake = false),
        _ClickToPlay.new,
      ],
    );
  }
}

class _ClickToPlay extends Behavior with PointerReceiver {
  @override
  void onPointerDown(PointerDownEvent event) {
    getComponent<AudioSource>().play();
  }
}
