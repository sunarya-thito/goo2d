import 'package:flutter/material.dart';
import 'package:goo2d/goo2d.dart';
import 'dart:math' as math;

enum CameraExampleTexture with AssetEnum, TextureAssetEnum {
  ship;
  @override
  AssetSource get source => AssetSource.local("assets/sprites/$name.png");
}

class CameraExample extends StatefulWidget {
  const CameraExample({super.key});

  @override
  State<CameraExample> createState() => _CameraExampleState();
}

class _CameraExampleState extends State<CameraExample> {
  late final Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = GameAsset.loadAll(CameraExampleTexture.values).drain();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        return Game(child: CameraExampleWorld());
      },
    );
  }
}

class CameraExampleWorld extends StatefulGameWidget {
  const CameraExampleWorld({super.key});

  @override
  GameState<CameraExampleWorld> createState() => _CameraExampleWorldState();
}

class _CameraExampleWorldState extends GameState<CameraExampleWorld> {
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
        InputBinding.composite(
          up: game.input.keyboard.upArrow,
          down: game.input.keyboard.downArrow,
          left: game.input.keyboard.leftArrow,
          right: game.input.keyboard.rightArrow,
        ),
      ],
    );
  }

  @override
  Iterable<Widget> build(BuildContext context) sync* {
    const playerTag = GameTag('Player');

    yield WorldBackground();

    yield PlayerShip(
      key: playerTag,
      moveAction: moveAction,
    );

    yield GameWidget(
      key: const GameTag('MainCamera'),
      components: [
        ObjectTransform.new,
        Camera.new.withParams((c) => c
          ..depth = 1.0
          ..backgroundColor = Colors.black
          ..orthographicSize = 5.0),
        FollowPlayer.new.withParams((c) => c.targetTag = playerTag),
      ],
    );

    yield SimpleHUD();
  }
}

class WorldBackground extends StatefulGameWidget {
  const WorldBackground({super.key});
  @override
  GameState<WorldBackground> createState() => _WorldBackgroundState();
}

class _WorldBackgroundState extends GameState<WorldBackground> with Renderable {
  @override
  void render(Canvas canvas) {
    final dotPaint = Paint()..color = Colors.green.withValues(alpha: 0.3);
    for (int x = -10; x <= 10; x++) {
      for (int y = -10; y <= 10; y++) {
        canvas.drawCircle(Offset(x * 2.0, y * 2.0), 0.1, dotPaint);
      }
    }
  }
}

class PlayerShip extends StatefulGameWidget {
  final InputAction moveAction;
  const PlayerShip({super.key, required this.moveAction});
  @override
  GameState<PlayerShip> createState() => _PlayerShipState();
}

class _PlayerShipState extends GameState<PlayerShip> {
  @override
  void initState() {
    super.initState();
    addComponent(
      ObjectTransform.new.withParams((c) => c.position = Offset.zero),
      SpriteRenderer.new.withParams((c) => c
        ..sprite = GameSprite(
          texture: CameraExampleTexture.ship,
          pixelsPerUnit: 32,
        )),
      ShipMovement.new.withParams((c) => c.moveAction = widget.moveAction),
    );
  }

  @override
  Iterable<Widget> build(BuildContext context) sync* {}
}

class ShipMovement extends Behavior with Tickable {
  late InputAction moveAction;

  @override
  void onUpdate(double dt) {
    final moveVector = moveAction.readValue<Offset>();
    final transform = getComponent<ObjectTransform>();
    transform.position += moveVector * 5.0 * dt;
  }
}

class FollowPlayer extends Behavior with LateTickable {
  late GameTag targetTag;

  @override
  void onLateUpdate(double dt) {
    final target = targetTag.gameObject?.tryGetComponent<ObjectTransform>();
    if (target != null) {
      final transform = getComponent<ObjectTransform>();
      // Framerate-independent interpolation
      transform.position = Offset.lerp(
        transform.position,
        target.position,
        1.0 - math.exp(-5.0 * dt),
      )!;
    }
  }
}

class SimpleHUD extends StatefulGameWidget {
  const SimpleHUD({super.key});
  @override
  GameState<SimpleHUD> createState() => _SimpleHUDState();
}

class _SimpleHUDState extends GameState<SimpleHUD> {
  @override
  Iterable<Widget> build(BuildContext context) sync* {
    yield GameWidget(
      components: [ScreenTransform.new],
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(10),
              color: Colors.black54,
              child: const Text(
                'Smooth Camera Follow Example',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
