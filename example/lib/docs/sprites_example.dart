import 'package:flutter/material.dart';
import 'package:goo2d/goo2d.dart';

enum SpriteExampleTexture with AssetEnum, TextureAssetEnum {
  explosion
  ;

  @override
  AssetSource get source => AssetSource.local("assets/sprites/$name.png");
}

class SpriteExample extends StatefulWidget {
  const SpriteExample({super.key});

  @override
  State<SpriteExample> createState() => _SpriteExampleState();
}

class _SpriteExampleState extends State<SpriteExample> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: GameAsset.loadAll(SpriteExampleTexture.values).drain(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        return const Game(child: SpriteWorld());
      },
    );
  }
}

class SpriteWorld extends StatefulGameWidget {
  const SpriteWorld({super.key});

  @override
  GameState<SpriteWorld> createState() => _SpriteWorldState();
}

class _SpriteWorldState extends GameState<SpriteWorld> with Tickable {
  late final SpriteSheet explosionSheet;
  int _currentFrame = 0;
  double _timer = 0;

  @override
  void initState() {
    super.initState();
    explosionSheet = SpriteSheet.grid(
      texture: SpriteExampleTexture.explosion,
      columns: 13,
      rows: 1,
      ppu: 64.0,
    );
  }

  @override
  void onUpdate(double dt) {
    _timer += dt;
    if (_timer > 0.1) {
      _timer = 0;
      setState(() {
        _currentFrame = (_currentFrame + 1) % 13;
      });
    }
  }

  @override
  Iterable<Widget> build(BuildContext context) sync* {
    yield GameWidget(
      components: () => [
        ObjectTransform()..scale = const Offset(2, 2),
        SpriteRenderer()..sprite = explosionSheet[(_currentFrame, 0)],
      ],
    );

    yield CanvasWidget(
      child: const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 200),
          child: Text(
            'Sprite Sheet Animation: 13 Frames',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      ),
    );

    yield GameWidget(
      components: () => [
        ObjectTransform(),
        Camera()..orthographicSize = 5.0,
      ],
    );
  }
}
