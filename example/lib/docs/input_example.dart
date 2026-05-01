import 'package:flutter/material.dart';
import 'package:goo2d/goo2d.dart';

enum InputExampleTexture with AssetEnum, TextureAssetEnum {
  ship
  ;

  @override
  AssetSource get source => AssetSource.local("assets/sprites/$name.png");
}

class InputExample extends StatelessWidget {
  const InputExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FutureBuilder(
        future: GameAsset.loadAll(InputExampleTexture.values).drain(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return Game(child: InputExampleWorld());
        },
      ),
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
    // Player Ship
    yield GameObjectWidget(
      children: [
        ComponentWidget(
          ObjectTransform.new.withInitialValues(
            (c) => c.position = Offset.zero,
          ),
        ),
        ComponentWidget(
          SpriteRenderer.new.withInitialValues(
            (c) => c
              ..sprite = GameSprite(
                texture: InputExampleTexture.ship,
                pixelsPerUnit: 32.0,
              ),
          ),
        ),
        ComponentWidget(
          PlayerInputMovement.new.withInitialValues(
            (c) => c.moveAction = moveAction,
          ),
        ),
      ],
    );

    // Camera
    yield GameObjectWidget(
      children: [
        ComponentWidget(ObjectTransform.new),
        ComponentWidget(
          Camera.new.withInitialValues((c) => c..orthographicSize = 5.0),
        ),
      ],
    );
  }
}

class PlayerInputMovement extends Behavior with Tickable {
  late InputAction moveAction;

  @override
  void onUpdate(double dt) {
    final moveVector = moveAction.readValue<Offset>();
    final transform = getComponent<ObjectTransform>();

    // Smooth movement with speed 5.0 units per second
    transform.position += moveVector * 5.0 * dt;

    // Subtle rotation based on horizontal movement for "tilt" effect
    final targetRotation = -moveVector.dx * 0.5;
    transform.angle = lerpDouble(transform.angle, targetRotation, 10.0 * dt);
  }

  double lerpDouble(double a, double b, double t) {
    return a + (b - a) * t.clamp(0.0, 1.0);
  }
}
