import 'package:flutter/material.dart';
import 'package:goo2d/goo2d.dart';
import 'dart:math';

enum MyGameSprite with AssetEnum, LocalGameSpriteEnum {
  player,
  bullet
  ;

  @override
  String get path => "assets/sprites/$name.png";
}

enum MyGameSound with AssetEnum, LocalGameAudioEnum {
  shoot
  ;

  @override
  String get path => "assets/audios/$name.mp3";
}

Future<void> loadAllGameAssets() async {
  await GameAsset.loadAll(MyGameSprite.values).last;
  await GameAsset.loadAll(MyGameSound.values).last;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FutureBuilder(
        future: loadAllGameAssets(),
        builder: (context, snapshot) {
          // Game assets failed to load
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error!.toString()));
          }

          // Game assets is still loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Game assets are loaded and game is ready to be started.
          return Game(
            child: World(),
          );
        },
      ),
    );
  }
}

class World extends StatefulGameWidget {
  const World({super.key});

  @override
  GameState<StatefulGameWidget> createState() => WorldState();
}

class WorldState extends GameState<World> {
  final List<Widget> bullets = [];

  @override
  Iterable<Widget> build(BuildContext context) sync* {
    yield WorldProvider(world: this, child: Player());

    yield* bullets;
  }

  void addBullet(Widget bullet) {
    setState(() => bullets.add(bullet));
  }

  void removeBullet(Widget bullet) {
    setState(() => bullets.remove(bullet));
  }
}

class WorldProvider extends InheritedWidget {
  final WorldState world;

  const WorldProvider({super.key, required this.world, required super.child});

  @override
  bool updateShouldNotify(WorldProvider oldWidget) => world != oldWidget.world;

  static WorldState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WorldProvider>()!.world;
}

class Player extends StatefulGameWidget {
  const Player({super.key});

  @override
  GameState<StatefulGameWidget> createState() => PlayerState();
}

class PlayerState extends GameState<Player> {
  late InputAction moveAction;
  late WorldState _world;

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
      ObjectTransform()..position = Offset(200, 200),
      SpriteRenderer()..sprite = MyGameSprite.player,
      SpriteRotationController(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _world = WorldProvider.of(context);
  }

  void shoot(Offset direction) {
    _world.addBullet(
      GameWidget(
        components: () => [
          ObjectTransform(),
          SpriteRenderer()..sprite = MyGameSprite.bullet,
          BulletController()..direction = direction,
          BulletOutOfScreenDestroyer(),
        ],
      ),
    );
  }
}

class SpriteRotationController extends Behavior
    with LifecycleListener, Tickable {
  late PlayerState _playerState;
  late ObjectTransform _transform;

  @override
  void onMounted() {
    _playerState = getComponent<PlayerState>();
    _transform = getComponent<ObjectTransform>();
  }

  @override
  void onUpdate(double dt) {
    final moveValue = _playerState.moveAction.readValue<Offset>() * dt;
    if (moveValue.distanceSquared > 0) {
      _transform.angle = -atan2(moveValue.dy, moveValue.dx);
    }
  }
}

class BulletController extends Behavior with Tickable, LifecycleListener {
  late Offset direction;

  late ObjectTransform _transform;

  @override
  void onMounted() {
    _transform = getComponent<ObjectTransform>();
  }

  @override
  void onUpdate(double dt) {
    _transform.position += direction * dt;
  }
}

class BulletOutOfScreenDestroyer extends Behavior
    with ScreenCollidable, LifecycleListener {
  late WorldState world;

  @override
  void onMounted() {
    world = getComponentInParent<WorldState>();
  }

  @override
  void onExitScreen() {
    world.removeBullet(gameObject.widget);
  }
}
