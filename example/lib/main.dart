import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:goo2d/goo2d.dart';
import 'package:google_fonts/google_fonts.dart';

// --- Assets ---

enum MyGameTexture with AssetEnum, TextureAssetEnum {
  ship,
  tilesPacked,
  enemy,
  explosion,
  ;

  @override
  AssetSource get source => AssetSource.local("assets/sprites/$name.png");
}

enum MyGameSound with AssetEnum, AudioAssetEnum {
  shoot,
  explosion,
  bgm(type: 'wav')
  ;

  final String type;
  const MyGameSound({this.type = 'ogg'});
  @override
  AssetSource get source => AssetSource.local("assets/audios/$name.$type");
}

Future<void> loadAllGameAssets() async {
  await GoogleFonts.pendingFonts([
    GoogleFonts.jersey10(),
  ]);
  await AudioSystem.initialize(); // we use audio, so we need to initialize it.
  await for (final p in GameAsset.loadAll(MyGameTexture.values)) {
    if (kDebugMode) {
      print(
        'Loading ${p.loadingAsset.source.name} (${p.assetLoaded}/${p.assetCount})',
      );
    }
  }
  await for (final p in GameAsset.loadAll(MyGameSound.values)) {
    if (kDebugMode) {
      print(
        'Loading ${p.loadingAsset.source.name} (${p.assetLoaded}/${p.assetCount})',
      );
    }
  }
}

// --- Entry Point ---

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: FutureBuilder(
          future: loadAllGameAssets(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            return DefaultTextStyle(
              style: GoogleFonts.jersey10(),
              child: const Game(
                child: BattleWorld(),
              ),
            );
          },
        ),
      ),
    );
  }
}

// --- Game World ---

class BattleWorld extends StatefulGameWidget {
  const BattleWorld({super.key});
  @override
  GameState<BattleWorld> createState() => BattleWorldState();
}

class BattleWorldState extends GameState<BattleWorld> with Tickable {
  final List<Widget> bullets = [];
  final List<Widget> enemies = [];
  late SpriteSheet<TileCoord> explosionSheet;
  double _enemySpawnTimer = 0;

  @override
  void initState() {
    super.initState();
    explosionSheet = SpriteSheet.grid(
      texture: MyGameTexture.explosion,
      rows: 1,
      columns: 13,
      ppu: 64.0,
    );
  }

  @override
  Iterable<Widget> build(BuildContext context) sync* {
    const playerTag = GameTag('Player');

    // Background & Music
    yield GameWidget(
      key: const GameTag('Background'),
      components: () => [
        ObjectTransform(),
        TiledBackground(),
        AudioSource()
          ..clip = MyGameSound.bgm
          ..loop = true
          ..volume = 0.5,
      ],
    );

    // Player
    yield BattleWorldProvider(
      world: this,
      child: Player(key: playerTag),
    );

    // Cameras
    yield GameWidget(
      key: const GameTag('MainCamera'),
      components: () => [
        ObjectTransform(),
        Camera()
          ..depth = 1.0
          ..backgroundColor = Colors.black
          ..orthographicSize = 2.0,
        FollowTarget(targetTag: playerTag),
        CameraShake(),
      ],
    );

    yield GameWidget(
      key: const GameTag('MinimapCamera'),
      components: () => [
        ObjectTransform(),
        Camera()
          ..depth = 0.0
          ..orthographicSize = 3.0
          ..backgroundColor = Colors.black87,
        FollowTarget(targetTag: playerTag),
      ],
    );

    yield* bullets;
    yield* enemies;

    // HUD
    yield const InstructionsUI(key: GameTag('Instructions'));
    yield const MinimapUI(key: GameTag('Minimap'));
    yield const FPSUI(key: GameTag('FPS'));
  }

  @override
  void onUpdate(double dt) {
    _enemySpawnTimer -= dt;
    if (_enemySpawnTimer <= 0) {
      _spawnEnemy();
      _enemySpawnTimer = 2.0;
    }
  }

  void _spawnEnemy() {
    final player = const GameTag('Player').gameObject;
    if (player == null) return;
    final pTrans = player.getComponent<ObjectTransform>();

    final forward = Offset(-math.sin(-pTrans.angle), -math.cos(-pTrans.angle));
    final angle =
        math.atan2(forward.dy, forward.dx) +
        (math.Random().nextDouble() - 0.5) * (math.pi / 1.5);
    final pos =
        pTrans.position + Offset(math.cos(angle), math.sin(angle)) * 15.0;

    setState(() {
      enemies.add(
        GameWidget(
          key: GameTag(UniqueKey()),
          components: () => [
            ObjectTransform()..position = pos,
            SpriteRenderer()
              ..sprite = GameSprite(
                texture: MyGameTexture.enemy,
                pixelsPerUnit: 64.0,
              )
              ..filterQuality = ui.FilterQuality.none,
            EnemyController(),
            OvalCollisionTrigger()
              ..radiusX = 0.2
              ..radiusY = 0.2,
          ],
        ),
      );
    });
  }

  void _spawnExplosion(Offset position) {
    setState(() {
      enemies.add(
        GameWidget(
          key: GameTag(UniqueKey()),
          components: () => [
            ObjectTransform()
              ..position = position
              ..scale = const Offset(1.0, -1.0),
            SpriteRenderer()
              ..sprite = explosionSheet[(0, 0)]
              ..filterQuality = ui.FilterQuality.none,
            ExplosionController(),
            AudioSource()
              ..clip = MyGameSound.explosion
              ..volume = 1.5,
          ],
        ),
      );
    });
  }

  void _destroyObject(GameObject obj) {
    setState(() {
      bullets.removeWhere((w) => w.key == obj.tag);
      enemies.removeWhere((w) => w.key == obj.tag);
    });
  }

  void addBullet(Widget bullet) => setState(() => bullets.add(bullet));
  void removeBullet(Widget bullet) => setState(() => bullets.remove(bullet));
}

// --- Player & Entities ---

class Player extends StatefulGameWidget {
  const Player({super.key});
  @override
  GameState<Player> createState() => PlayerState();
}

class PlayerState extends GameState<Player> with Tickable {
  late InputAction moveAction, shootAction;
  late BattleWorldState _world;
  late GameSprite _bulletSprite;
  late AudioSource _audioSource;

  @override
  void initState() {
    super.initState();
    _world = getComponentInParent<BattleWorldState>();
    _bulletSprite = SpriteSheet.grid(
      texture: MyGameTexture.tilesPacked,
      rows: 10,
      columns: 12,
      ppu: 64.0,
    )[(0, 0)];

    moveAction = createInputAction(
      name: 'thrust',
      type: InputActionType.button,
      bindings: [InputBinding(control: game.input.keyboard.keyW)],
    );
    shootAction = createInputAction(
      name: 'shoot',
      type: InputActionType.button,
      bindings: [InputBinding(control: game.input.keyboard.space)],
    );

    addComponent(
      ObjectTransform()..position = Offset.zero,
      SpriteRenderer()
        ..sprite = GameSprite(
          texture: MyGameTexture.ship,
          pivot: NormalizedPivot.center,
          pixelsPerUnit: 64.0,
        )
        ..filterQuality = ui.FilterQuality.none,
      OvalCollisionTrigger()
        ..radiusX = 0.2
        ..radiusY = 0.2,
      BlinkEffect(),
      _audioSource = AudioSource()
        ..clip = MyGameSound.shoot
        ..volume = 0.4
        ..playOnAwake = false,
    );
  }

  double _shootTimer = 0,
      _rotationVel = 0,
      _rotationVelVel = 0,
      _speed = 2.0,
      _speedVel = 0;

  @override
  void onUpdate(double dt) {
    final trans = getComponent<ObjectTransform>();
    final kb = game.input.keyboard;

    // Rotation
    double targetRot = 0;
    if (kb.keyA.isPressed) targetRot += 1.0;
    if (kb.keyD.isPressed) targetRot -= 1.0;

    final rotRes = MathUtils.smoothDamp(
      _rotationVel,
      targetRot * 4.5,
      _rotationVelVel,
      0.1,
      dt,
    );
    _rotationVel = rotRes.value;
    _rotationVelVel = rotRes.velocity;
    trans.angle += _rotationVel * dt;

    // Movement
    final facing = Offset(-math.sin(-trans.angle), -math.cos(-trans.angle));
    final speedRes = MathUtils.smoothDamp(
      _speed,
      moveAction.inProgress ? 4.0 : 2.0,
      _speedVel,
      0.4,
      dt,
    );
    _speed = speedRes.value;
    _speedVel = speedRes.velocity;
    trans.position += facing * _speed * dt;

    // Shooting
    _shootTimer -= dt;
    if (shootAction.inProgress && _shootTimer <= 0) {
      _audioSource.play();
      _world.addBullet(
        GameWidget(
          key: GameTag(UniqueKey()),
          components: () => [
            ObjectTransform()
              ..position = trans.position + facing * 0.25
              ..angle = trans.angle,
            SpriteRenderer()
              ..sprite = _bulletSprite
              ..filterQuality = ui.FilterQuality.none,
            BulletController()..direction = facing,
            BulletOutOfScreenDestroyer(),
            OvalCollisionTrigger()
              ..radiusX = 0.2
              ..radiusY = 0.2,
          ],
        ),
      );
      _shootTimer = 0.1;
    }
  }
}

class BulletController extends Behavior
    with Tickable, LifecycleListener, Collidable {
  late Offset direction;
  late ObjectTransform _transform;
  late BattleWorldState world;
  double _lifetime = 0;

  @override
  void onMounted() {
    _transform = getComponent<ObjectTransform>();
    world = getComponentInParent<BattleWorldState>();
  }

  @override
  void onUpdate(double dt) {
    _transform.position += direction * 15.0 * dt;
    if ((_lifetime += dt) >= 2.0) world._destroyObject(gameObject);
  }

  @override
  void onCollision(CollisionEvent collision) {
    if (collision.other.gameObject.tryGetComponent<EnemyController>() != null) {
      world._destroyObject(gameObject);
    }
  }
}

class EnemyController extends Behavior
    with Tickable, LifecycleListener, Collidable {
  late ObjectTransform _transform;
  late BattleWorldState world;
  late double speed, _swerveOffset, _swerveSpeed;

  @override
  void onMounted() {
    _transform = getComponent<ObjectTransform>();
    world = getComponentInParent<BattleWorldState>();
    final rand = math.Random();
    speed = 1.5 + rand.nextDouble() * 1.5;
    _swerveOffset = rand.nextDouble() * math.pi * 2;
    _swerveSpeed = 0.5 + rand.nextDouble() * 1.5;
  }

  @override
  void onUpdate(double dt) {
    final player = const GameTag('Player').gameObject;
    if (player == null) return;
    final toPlayer =
        player.getComponent<ObjectTransform>().position - _transform.position;
    final dist = toPlayer.distance;
    if (dist > 0.1) {
      final dir = toPlayer / dist;
      _transform.position += dir * speed * dt;
      _transform.position +=
          Offset(-dir.dy, dir.dx) *
          math.sin(game.ticker.time * _swerveSpeed + _swerveOffset) *
          1.2 *
          dt;
      _transform.angle = -math.atan2(toPlayer.dx, toPlayer.dy) + math.pi;
    }
  }

  @override
  void onCollision(CollisionEvent collision) {
    final other = collision.other;
    if (other.gameObject.tag == const GameTag('Player')) {
      const GameTag(
        'MainCamera',
      ).gameObject?.getComponent<CameraShake>().shake();
      other.gameObject.getComponent<BlinkEffect>().blink();
    }
    if (other.gameObject.tryGetComponent<BulletController>() != null ||
        other.gameObject.tag == const GameTag('Player')) {
      world._spawnExplosion(_transform.position);
      world._destroyObject(gameObject);
    }
  }
}

// --- Reusable Behaviors & Helpers ---

class FollowTarget extends Behavior with LifecycleListener, LateTickable {
  final GameTag targetTag;
  FollowTarget({required this.targetTag});
  @override
  void onLateUpdate(double dt) {
    final target = targetTag.gameObject?.tryGetComponent<ObjectTransform>();
    if (target != null) {
      getComponent<ObjectTransform>().position = target.position;
    }
  }
}

class CameraShake extends Behavior with LifecycleListener, LateTickable {
  double _trauma = 0, _magnitude = 0, _timer = 0, _decayRate = 2.0;
  Offset _currentOffset = Offset.zero,
      _targetOffset = Offset.zero,
      _velocity = Offset.zero;
  final math.Random _random = math.Random();

  void shake([double duration = 0.4, double magnitude = 0.25]) {
    _trauma = 1.0;
    _magnitude = magnitude;
    _decayRate = 1.0 / duration;
  }

  @override
  void onLateUpdate(double dt) {
    if (_trauma <= 0) return;
    _trauma = math.max(0, _trauma - _decayRate * dt);
    if ((_timer -= dt) <= 0) {
      _timer = 0.02;
      final s = _trauma * _trauma;
      _targetOffset = Offset(
        (_random.nextDouble() * 2 - 1) * _magnitude * s,
        (_random.nextDouble() * 2 - 1) * _magnitude * s,
      );
    }
    final res = MathUtils.smoothDampOffset(
      _currentOffset,
      _targetOffset,
      _velocity,
      0.015,
      dt,
    );
    _currentOffset = res.value;
    _velocity = res.velocity;
    getComponent<ObjectTransform>().position += _currentOffset;
  }
}

class BlinkEffect extends Behavior with LifecycleListener, Tickable {
  double _timer = 0;
  late SpriteRenderer _renderer;
  @override
  void onMounted() => _renderer = getComponent<SpriteRenderer>();
  void blink([double duration = 0.15]) {
    _timer = duration;
    _renderer.color = Colors.white;
    _renderer.blendMode = ui.BlendMode.srcIn;
  }

  @override
  void onUpdate(double dt) {
    if (_timer > 0 && (_timer -= dt) <= 0) {
      _renderer.color = Colors.white;
      _renderer.blendMode = ui.BlendMode.modulate;
    }
  }
}

class ExplosionController extends Behavior with Tickable, LifecycleListener {
  int _frame = 0;
  double _timer = 0;
  @override
  void onUpdate(double dt) {
    if ((_timer += dt) >= 0.05) {
      _timer = 0;
      if (++_frame >= 13) {
        getComponentInParent<BattleWorldState>()._destroyObject(gameObject);
      } else {
        getComponent<SpriteRenderer>().sprite =
            getComponentInParent<BattleWorldState>().explosionSheet[(
              _frame,
              0,
            )];
      }
    }
  }
}

class BulletOutOfScreenDestroyer extends Behavior
    with ScreenCollidable, LifecycleListener {
  @override
  void onExitScreen() =>
      getComponentInParent<BattleWorldState>().removeBullet(gameObject.widget);
}

class TiledBackground extends Component with LifecycleListener, Renderable {
  late SpriteSheet _sheet;
  @override
  void onMounted() => _sheet = SpriteSheet.grid(
    texture: MyGameTexture.tilesPacked,
    rows: 10,
    columns: 12,
  );
  int _hash(int x, int y) {
    var h = x * 374761393 + y * 668265263;
    return (h ^ (h >> 13)) * 12741261 & 0x7FFFFFFF;
  }

  final _paint = ui.Paint()
    ..filterQuality = ui.FilterQuality.none
    ..isAntiAlias = false;

  @override
  void render(ui.Canvas canvas) {
    final grass = _sheet[(2, 4)];
    final double size = grass.rect.width / grass.pixelsPerUnit;

    // Get the visible area in world space.
    ui.Rect bounds = canvas.getLocalClipBounds();

    // Fallback if the clip bounds are missing or practically infinite (no clip).
    if (bounds.width > 10000 || bounds.isEmpty) {
      final camera = game.cameras.main;
      final camPos =
          camera.gameObject.tryGetComponent<ObjectTransform>()?.position ??
          ui.Offset.zero;
      final halfHeight = camera.orthographicSize;
      final screenSize = game.ticker.screenSize;
      final aspect =
          screenSize.height > 0 ? screenSize.width / screenSize.height : 1.0;
      final halfWidth = halfHeight * aspect;

      bounds = ui.Rect.fromLTWH(
        camPos.dx - halfWidth,
        camPos.dy - halfHeight,
        halfWidth * 2,
        halfHeight * 2,
      );
    }

    final int startX = (bounds.left / size).floor() - 2;
    final int endX = (bounds.right / size).ceil() + 2;
    final int startY = (bounds.top / size).floor() - 2;
    final int endY = (bounds.bottom / size).ceil() + 2;

    // Iterate only over visible tiles.
    for (int y = startY; y <= endY; y++) {
      // Optimize by translating/scaling once per row instead of per tile
      canvas.save();
      canvas.translate(startX * size, y * size + size);
      canvas.scale(1, -1);
      for (int x = startX; x <= endX; x++) {
        canvas.drawImageRect(
          grass.texture.image,
          grass.rect,
          ui.Rect.fromLTWH(0, 0, size + 0.01, size + 0.01),
          _paint,
        );
        final h = _hash(x, y);
        if (h % 10 == 0) {
          final deco = _sheet[(0, 3 + (h % 6))];
          canvas.drawImageRect(
            deco.texture.image,
            deco.rect,
            ui.Rect.fromLTWH(0, 0, size + 0.01, size + 0.01),
            _paint,
          );
        }
        canvas.translate(size, 0);
      }
      canvas.restore();
    }
  }
}

// --- UI Components ---

class InstructionsUI extends StatefulGameWidget {
  const InstructionsUI({super.key});
  @override
  GameState<InstructionsUI> createState() => InstructionsState();
}

class InstructionsState extends GameState<InstructionsUI> {
  @override
  Iterable<Widget> build(BuildContext context) sync* {
    yield CanvasWidget(
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: const Text(
            'W (thrust) - A (rotate) - D (rotate) - Space (shoot)',
            style: TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class MinimapUI extends StatefulGameWidget {
  const MinimapUI({super.key});
  @override
  GameState<MinimapUI> createState() => MinimapState();
}

class MinimapState extends GameState<MinimapUI> {
  @override
  Iterable<Widget> build(BuildContext context) sync* {
    yield CanvasWidget(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: 150,
            height: 150,
            foregroundDecoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
            ),
            decoration: const BoxDecoration(color: Colors.black87),
            child: const CameraView(cameraTag: GameTag('MinimapCamera')),
          ),
        ),
      ),
    );
  }
}

class BattleWorldProvider extends InheritedWidget {
  final BattleWorldState world;
  const BattleWorldProvider({
    super.key,
    required this.world,
    required super.child,
  });
  @override
  bool updateShouldNotify(BattleWorldProvider oldWidget) =>
      world != oldWidget.world;
  static BattleWorldState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BattleWorldProvider>()!.world;
}

class FPSUI extends StatefulGameWidget {
  const FPSUI({super.key});
  @override
  GameState<FPSUI> createState() => FPSState();
}

class FPSState extends GameState<FPSUI> with Tickable {
  double _fps = 0;
  double _timer = 0;

  @override
  void onUpdate(double dt) {
    _timer += dt;
    if (dt > 0) {
      _fps = _fps * 0.9 + (1.0 / dt) * 0.1;
    }

    // Only rebuild the FPS UI twice per second to save performance.
    if (_timer >= 0.5) {
      _timer = 0;
      if (mounted) setState(() {});
    }
  }

  @override
  Iterable<Widget> build(BuildContext context) sync* {
    yield CanvasWidget(
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'FPS: ${_fps.round()}',
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
