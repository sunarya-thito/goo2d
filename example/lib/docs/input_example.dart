import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:goo2d/goo2d.dart';

enum InputExampleTexture with AssetEnum, TextureAssetEnum {
  ship;
  @override
  AssetSource get source => AssetSource.local("assets/sprites/$name.png");
}

class InputExample extends StatefulWidget {
  const InputExample({super.key});

  @override
  State<InputExample> createState() => _InputExampleState();
}

class _InputExampleState extends State<InputExample> {
  Future<void>? _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = _load();
  }

  Future<void> _load() async {
    await for (final p in GameAsset.loadAll(InputExampleTexture.values)) {
      if (kDebugMode) {
        print('Loading ${p.loadingAsset.source.name} (${p.assetLoaded}/${p.assetCount})');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        return const Game(child: InputExampleWorld());
      },
    );
  }
}

class InputExampleWorld extends StatefulGameWidget {
  const InputExampleWorld({super.key});

  @override
  GameState<InputExampleWorld> createState() => _InputExampleWorldState();
}

class _InputExampleWorldState extends GameState<InputExampleWorld> {
  late final InputAction moveAction;

  @override
  void initState() {
    super.initState();
    moveAction = createInputAction(
      name: 'move',
      type: InputActionType.value,
      bindings: [
        InputBinding.composite(
          up: game.input.keyboard.keyW,
          down: game.input.keyboard.keyS,
          left: game.input.keyboard.keyA,
          right: game.input.keyboard.keyD,
        ),
      ],
    );

    addComponent(
      ObjectTransform()..position = Offset.zero,
      SpriteRenderer()
        ..sprite = GameSprite(
          texture: InputExampleTexture.ship,
          pixelsPerUnit: 64.0,
        ),
      PlayerInputMovement(moveAction: moveAction),
    );
  }
}

class PlayerInputMovement extends Behavior with Tickable {
  final InputAction moveAction;
  PlayerInputMovement({required this.moveAction});

  @override
  void onUpdate(double dt) {
    final moveVector = moveAction.readValue<Offset>();
    final transform = getComponent<ObjectTransform>();
    transform.position += moveVector * 5.0 * dt;
  }
}
