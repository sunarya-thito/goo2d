import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:goo2d/goo2d.dart';

void main() {
  runApp(const MyApp());
}

enum MyGameTexture with AssetEnum, TextureAssetEnum {
  ship,
  tiles_packed,
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
  // because we are using audio
  await AudioSystem.initialize();

  await for (final asset in GameAsset.loadAll(MyGameTexture.values)) {
    if (kDebugMode) {
      print(
        'Loading ${asset.loadingAsset.source.name} (${asset.assetLoaded} / ${asset.assetCount})',
      );
    }
  }

  await for (final asset in GameAsset.loadAll(MyGameSound.values)) {
    if (kDebugMode) {
      print(
        'Loading ${asset.loadingAsset.source.name} (${asset.assetLoaded} / ${asset.assetCount})',
      );
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: FutureBuilder(
          future: loadAllGameAssets(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error!.toString()));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            const minimapTag = GameTag('MinimapCamera');

            return Game(
              child: Stack(
                children: [
                  const SpaceWorld(),
                  Positioned(
                    right: 20,
                    top: 20,
                    width: 150,
                    height: 150,
                    child: CanvasWidget(
                      child: MinimapUI(cameraTag: minimapTag),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    left: 20,
                    child: CanvasWidget(
                      child: Text(
                        'W (thrust) -  A (rotate left) - D (rotate right) - spacebar (shoot) ',
                        style: TextStyle(fontSize: 24, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class MinimapUI extends StatelessWidget {
  final GameTag cameraTag;
  const MinimapUI({super.key, required this.cameraTag});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 2),
        color: Colors.black.withValues(alpha: 0.5),
      ),
      child: CameraView(cameraTag: cameraTag),
    );
  }
}

class SpaceWorld extends StatefulGameWidget {
  const SpaceWorld({super.key});

  @override
  GameState<SpaceWorld> createState() => WorldState();
}

class WorldState extends GameState<SpaceWorld> with Tickable {
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
    yield* _buildWorldContent();
  }

  Iterable<Widget> _buildWorldContent() sync* {
    const playerTag = GameTag('Player');

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

    yield WorldProvider(
      world: this,
      child: Player(key: playerTag),
    );

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
    final playerPos = player.getComponent<ObjectTransform>().position;
    final playerAngle = player.getComponent<ObjectTransform>().angle;

    // Direction player is facing
    final forwardDir = Offset(
      -math.sin(-playerAngle),
      -math.cos(-playerAngle),
    );

    // Spawn mostly in front of the player (arc of +/- 60 degrees)
    final randomAngleOffset =
        (math.Random().nextDouble() - 0.5) * (math.pi / 1.5);
    final spawnAngle =
        math.atan2(forwardDir.dy, forwardDir.dx) + randomAngleOffset;

    final spawnPos =
        playerPos + Offset(math.cos(spawnAngle), math.sin(spawnAngle)) * 15.0;

    setState(() {
      enemies.add(
        GameWidget(
          key: GameTag(UniqueKey()),
          components: () => [
            ObjectTransform()..position = spawnPos,
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

  void addBullet(Widget bullet) {
    setState(() => bullets.add(bullet));
  }

  void removeBullet(Widget bullet) {
    setState(() => bullets.remove(bullet));
  }
}

class FollowTarget extends Behavior with LifecycleListener, LateTickable {
  final GameTag targetTag;
  FollowTarget({required this.targetTag});

  late ObjectTransform _transform;

  @override
  void onMounted() {
    _transform = getComponent<ObjectTransform>();
  }

  @override
  void onLateUpdate(double dt) {
    final target = targetTag.gameObject?.tryGetComponent<ObjectTransform>();
    if (target != null) {
      _transform.position = target.position;
    }
  }
}

class CameraShake extends Behavior with LifecycleListener, LateTickable {
  double _trauma = 0;
  double _magnitude = 0;
  Offset _currentOffset = Offset.zero;
  Offset _targetOffset = Offset.zero;
  Offset _velocity = Offset.zero;
  final math.Random _random = math.Random();
  double _timer = 0;

  void shake([double duration = 0.4, double magnitude = 0.25]) {
    _trauma = 1.0;
    _magnitude = magnitude;
    _decayRate = 1.0 / duration;
  }

  double _decayRate = 2.0;

  @override
  void onLateUpdate(double dt) {
    if (_trauma > 0) {
      _trauma = math.max(0, _trauma - _decayRate * dt);

      _timer -= dt;
      if (_timer <= 0) {
        _timer = 0.02;
        final strength = _trauma * _trauma;
        _targetOffset = Offset(
          (_random.nextDouble() * 2 - 1) * _magnitude * strength,
          (_random.nextDouble() * 2 - 1) * _magnitude * strength,
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

      final transform = getComponent<ObjectTransform>();
      transform.position += _currentOffset;
    } else {
      _currentOffset = Offset.zero;
      _velocity = Offset.zero;
    }
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
  GameState<Player> createState() => PlayerState();
}

class PlayerState extends GameState<Player> with Tickable {
  late InputAction moveAction;
  late InputAction shootAction;
  late WorldState _world;
  late GameSprite _bulletSprite;
  late AudioSource _audioSource;

  @override
  void initState() {
    super.initState();
    _world = getComponentInParent<WorldState>();
    _bulletSprite = SpriteSheet.grid(
      texture: MyGameTexture.tiles_packed,
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
      ObjectTransform()..position = const Offset(0, 0),
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

  double _shootTimer = 0;
  double _rotationVelocity = 0;
  double _rotationVelocityVelocity = 0;
  double _currentSpeed = 2.0;
  double _currentSpeedVelocity = 0;
  static const double shootCooldown = 0.1;
  static const double baseMoveSpeed = 2.0;
  static const double boostMoveSpeed = 4.0;
  static const double rotationSpeed = 4.5;

  @override
  void onUpdate(double dt) {
    final transform = getComponent<ObjectTransform>();

    final bool rotateLeft = game.input.keyboard.keyA.isPressed;
    final bool rotateRight = game.input.keyboard.keyD.isPressed;
    final bool thrusting = moveAction.inProgress;
    final bool shooting = shootAction.inProgress;

    double targetRotationInput = 0;
    if (rotateLeft) targetRotationInput += 1.0;
    if (rotateRight) targetRotationInput -= 1.0;

    final res = MathUtils.smoothDamp(
      _rotationVelocity,
      targetRotationInput * rotationSpeed,
      _rotationVelocityVelocity,
      0.1, 
      dt,
    );
    _rotationVelocity = res.value;
    _rotationVelocityVelocity = res.velocity;
    transform.angle += _rotationVelocity * dt;

    final facing = Offset(
      -math.sin(-transform.angle),
      -math.cos(-transform.angle),
    );

    final targetSpeed = thrusting ? boostMoveSpeed : baseMoveSpeed;
    final speedRes = MathUtils.smoothDamp(
      _currentSpeed,
      targetSpeed,
      _currentSpeedVelocity,
      0.4, 
      dt,
    );
    _currentSpeed = speedRes.value;
    _currentSpeedVelocity = speedRes.velocity;

    transform.position += facing * _currentSpeed * dt;

    if (!transform.position.dx.isFinite || !transform.position.dy.isFinite) {
      transform.position = Offset.zero;
    }
    if (!transform.angle.isFinite) {
      transform.angle = 0;
    }

    _shootTimer -= dt;
    if (shooting && _shootTimer <= 0) {
      shoot(facing);
      _shootTimer = shootCooldown;
    }
  }

  void shoot(Offset direction) {
    _audioSource.play();
    final transform = getComponent<ObjectTransform>();
    _world.addBullet(
      GameWidget(
        key: GameTag(UniqueKey()),
        components: () => [
          ObjectTransform()
            ..position = transform.position + direction * 0.25
            ..angle = transform.angle,
          SpriteRenderer()
            ..sprite = _bulletSprite
            ..filterQuality = ui.FilterQuality.none,
          BulletController()..direction = direction,
          BulletOutOfScreenDestroyer(),
          OvalCollisionTrigger()
            ..radiusX = 0.2
            ..radiusY = 0.2,
        ],
      ),
    );
  }
}

class BulletController extends Behavior
    with Tickable, LifecycleListener, Collidable {
  late Offset direction;
  late ObjectTransform _transform;
  late WorldState world;
  double _lifetime = 0;
  static const double maxLifetime = 2.0;

  @override
  void onMounted() {
    _transform = getComponent<ObjectTransform>();
    world = getComponentInParent<WorldState>();
  }

  @override
  void onUpdate(double dt) {
    _transform.position += direction * 15.0 * dt;

    _lifetime += dt;
    if (_lifetime >= maxLifetime) {
      world._destroyObject(gameObject);
    }
  }

  @override
  void onCollision(CollisionEvent collision) {
    // If we hit an enemy, destroy ourselves
    final other = collision.other;
    if (other.gameObject.tryGetComponent<EnemyController>() != null) {
      world._destroyObject(gameObject);
    }
  }
}

class EnemyController extends Behavior
    with Tickable, LifecycleListener, Collidable {
  late ObjectTransform _transform;
  late WorldState world;
  late double speed;
  late double _swerveOffset;
  late double _swerveSpeed;

  @override
  void onMounted() {
    _transform = getComponent<ObjectTransform>();
    world = getComponentInParent<WorldState>();

    final rand = math.Random();
    speed = 1.5 + rand.nextDouble() * 1.5;
    _swerveOffset = rand.nextDouble() * math.pi * 2;
    _swerveSpeed = 0.5 + rand.nextDouble() * 1.5;
  }

  @override
  void onUpdate(double dt) {
    final player = const GameTag('Player').gameObject;
    if (player == null) return;
    final playerPos = player.getComponent<ObjectTransform>().position;

    final toPlayer = playerPos - _transform.position;
    final distance = toPlayer.distance;
    if (distance > 0.1) {
      final dir = toPlayer / distance;

      // Follow player
      _transform.position += dir * speed * dt;

      // Lateral swerve to prevent perfect lines
      final sideDir = Offset(-dir.dy, dir.dx);
      final swerve =
          math.sin(game.ticker.time * _swerveSpeed + _swerveOffset) * 1.2;
      _transform.position += sideDir * swerve * dt;

      // Face the player (offset by pi to fix backward orientation)
      _transform.angle = -math.atan2(toPlayer.dx, toPlayer.dy) + math.pi;
    }
  }

  @override
  void onCollision(CollisionEvent collision) {
    // If hit by a bullet or the player, destroy ourselves
    final other = collision.other;

    if (other.gameObject.tag == const GameTag('Player')) {
      // Hit player! Trigger effects
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

class BlinkEffect extends Behavior with LifecycleListener, Tickable {
  double _timer = 0;
  late SpriteRenderer _renderer;

  @override
  void onMounted() {
    _renderer = getComponent<SpriteRenderer>();
  }

  void blink([double duration = 0.15]) {
    _timer = duration;
    _renderer.color = Colors.white;
    _renderer.blendMode = ui.BlendMode.srcIn;
  }

  @override
  void onUpdate(double dt) {
    if (_timer > 0) {
      _timer -= dt;
      if (_timer <= 0) {
        _renderer.color = Colors.white;
        _renderer.blendMode = ui.BlendMode.modulate;
      }
    }
  }
}

class ExplosionController extends Behavior with Tickable, LifecycleListener {
  late SpriteRenderer _renderer;
  int _frame = 0;
  double _timer = 0;
  static const double frameDuration = 0.05;

  @override
  void onMounted() {
    _renderer = getComponent<SpriteRenderer>();
  }

  @override
  void onUpdate(double dt) {
    _timer += dt;
    if (_timer >= frameDuration) {
      _timer = 0;
      _frame++;
      if (_frame >= 13) {
        getComponentInParent<WorldState>()._destroyObject(gameObject);
      } else {
        _renderer.sprite =
            getComponentInParent<WorldState>().explosionSheet[(_frame, 0)];
      }
    }
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

class TiledBackground extends Component with LifecycleListener, Renderable {
  late SpriteSheet _sheet;

  @override
  void onMounted() {
    _sheet = SpriteSheet.grid(
      texture: MyGameTexture.tiles_packed,
      rows: 10,
      columns: 12,
    );
  }

  // Simple hash for deterministic decorations
  int _hash(int x, int y) {
    var h = x * 374761393 + y * 668265263;
    h = (h ^ (h >> 13)) * 12741261;
    return h & 0x7FFFFFFF;
  }

  void _drawTile(ui.Canvas canvas, GameSprite sprite, Offset pos, double size) {
    // Increase overlap to 0.01 and disable anti-alias to ensure no gaps are visible
    const double bleed = 0.01;
    final paint = ui.Paint()
      ..filterQuality = ui.FilterQuality.none
      ..isAntiAlias = false;
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.translate(0, size);
    canvas.scale(1, -1);
    canvas.drawImageRect(
      sprite.texture.image,
      sprite.rect,
      ui.Rect.fromLTWH(0, 0, size + bleed, size + bleed),
      paint,
    );
    canvas.restore();
  }

  @override
  void render(ui.Canvas canvas) {
    final grass = _sheet[(2, 4)]; // col 2, row 4
    final double size = grass.rect.width / grass.pixelsPerUnit;

    // Find camera position to draw around it
    final camera = const GameTag(
      'MainCamera',
    ).gameObject?.tryGetComponent<ObjectTransform>();
    final pos = camera?.position ?? Offset.zero;
    if (!pos.dx.isFinite || !pos.dy.isFinite) return;

    final int camX = (pos.dx / size).floor();
    final int camY = (pos.dy / size).floor();

    // Draw tiles in a range around the camera
    // Range is larger now since tiles are smaller
    const int range = 25;
    for (int y = camY - range; y <= camY + range; y++) {
      for (int x = camX - range; x <= camX + range; x++) {
        final worldPos = Offset(
          x.toDouble() * size,
          y.toDouble() * size,
        );

        // Draw grass
        _drawTile(canvas, grass, worldPos, size);

        // Draw random decoration
        final h = _hash(x, y);
        if (h % 10 == 0) {
          // 10% chance
          final int decoRow = 3 + (h % 6); // rows 3, 4, 5, 6, 7
          final deco = _sheet[(0, decoRow)]; // col 0
          _drawTile(canvas, deco, worldPos, size);
        }
      }
    }
  }
}
