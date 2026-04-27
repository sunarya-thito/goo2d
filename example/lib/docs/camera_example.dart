import 'package:flutter/material.dart';
import 'package:goo2d/goo2d.dart';

class CameraExample extends StatefulGameWidget {
  const CameraExample({super.key});

  @override
  GameState<CameraExample> createState() => _CameraExampleState();
}

class _CameraExampleState extends GameState<CameraExample> {
  late final InputAction moveAction;

  @override
  void initState() {
    super.initState();
    // In Goo2D, createInputAction is a helper on GameState
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
  }

  @override
  Iterable<Widget> build(BuildContext context) sync* {
    const playerTag = GameTag('Player');

    yield const WorldBackground();

    yield PlayerHelicopter(
      key: playerTag,
      moveAction: moveAction,
    );

    yield GameWidget(
      key: const GameTag('MainCamera'),
      components: () => [
        ObjectTransform(),
        Camera()
          ..depth = 1.0
          ..backgroundColor = Colors.black
          ..orthographicSize = 5.0,
        FollowPlayer(targetTag: playerTag),
      ],
    );

    yield const SimpleHUD();
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
    final paint = Paint()..color = Colors.green.withValues(alpha: 0.2);
    for (int x = -10; x < 10; x++) {
      for (int y = -10; y < 10; y++) {
        final pos = Offset(x * 4.0, y * 4.0);
        canvas.drawCircle(pos, 0.2, paint);
      }
    }
  }
}

class PlayerHelicopter extends StatefulGameWidget {
  final InputAction moveAction;
  const PlayerHelicopter({super.key, required this.moveAction});
  @override
  GameState<PlayerHelicopter> createState() => _PlayerHelicopterState();
}

class _PlayerHelicopterState extends GameState<PlayerHelicopter> {
  @override
  void initState() {
    super.initState();
    addComponent(
      ObjectTransform()..position = Offset.zero,
      HelicopterMovement(moveAction: widget.moveAction),
    );
  }

  @override
  Iterable<Widget> build(BuildContext context) sync* {
    yield const Text('🚁', style: TextStyle(fontSize: 40));
  }
}

class HelicopterMovement extends Behavior with Tickable {
  final InputAction moveAction;
  HelicopterMovement({required this.moveAction});

  @override
  void onUpdate(double dt) {
    // readValue<Offset>() is used for vector2/composite bindings
    final move = moveAction.readValue<Offset>();
    final transform = getComponent<ObjectTransform>();
    transform.position += move * 5.0 * dt;
  }
}

class FollowPlayer extends Behavior with LateTickable {
  final GameTag targetTag;
  FollowPlayer({required this.targetTag});

  @override
  void onLateUpdate(double dt) {
    final target = targetTag.gameObject?.tryGetComponent<ObjectTransform>();
    if (target != null) {
      final transform = getComponent<ObjectTransform>();
      transform.position = Offset.lerp(
        transform.position,
        target.position,
        0.1,
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
    yield CanvasWidget(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(10),
            color: Colors.black54,
            child: const Text(
              'UI is fixed to screen - WASD to Move',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }
}
