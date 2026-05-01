import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:goo2d/goo2d.dart';
// ignore: implementation_imports
import 'package:goo2d/src/component.dart';
import 'dart:math' as math;

enum CollisionExampleTexture with AssetEnum, TextureAssetEnum {
  enemy,
  ship
  ;

  @override
  AssetSource get source => AssetSource.local("assets/sprites/$name.png");
}

class CollisionExample extends StatefulWidget {
  const CollisionExample({super.key});

  @override
  State<CollisionExample> createState() => _CollisionExampleState();
}

class _CollisionExampleState extends State<CollisionExample> {
  Future<void>? _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = _load();
  }

  Future<void> _load() async {
    await for (final p in GameAsset.loadAll(CollisionExampleTexture.values)) {
      if (kDebugMode) {
        print(
          'Loading ${p.loadingAsset.source.name} (${p.assetLoaded}/${p.assetCount})',
        );
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
        return Game(child: CollisionExampleWorld());
      },
    );
  }
}

class CollisionExampleWorld extends StatefulGameWidget {
  const CollisionExampleWorld({super.key});

  @override
  GameState<CollisionExampleWorld> createState() =>
      _CollisionExampleWorldState();
}

class _CollisionExampleWorldState extends GameState<CollisionExampleWorld> {
  @override
  Iterable<Widget> build(BuildContext context) sync* {
    yield MovingBox();

    // Denser grid fully contained within the visible area (orthographicSize 5.0)
    for (double x = -8; x <= 8; x += 2.0) {
      for (double y = -4; y <= 4; y += 2.0) {
        // Skip the center area where the ship starts
        if (x.abs() < 1.5 && y.abs() < 1.5) continue;
        yield StationaryTarget(position: Offset(x, y));
      }
    }

    yield GameWidget(
      components: [
        ObjectTransform.new,
        Camera.new.withParams(
          (c) => c
            ..orthographicSize = 5.0
            ..depth = 1.0,
        ),
      ],
    );
  }

  List<Component> get c => [
    ObjectTransform(),
    Camera()
      ..orthographicSize = 5.0
      ..depth = 1.0,
  ];
}

class MovingBox extends StatefulGameWidget {
  const MovingBox({super.key});

  @override
  GameState<MovingBox> createState() => _MovingBoxState();
}

class _MovingBoxState extends GameState<MovingBox> {
  @override
  void initState() {
    super.initState();
    addComponent(
      ObjectTransform.new.withParams((c) => c.position = const Offset(-2, 0)),
      BoxCollider.new.withParams((c) => c.size = const Size(0.5, 0.5)),
      BouncingBehavior.new,
    );
  }
}

class BouncingBehavior extends Behavior
    with Tickable, OuterScreenCollidable, CollisionListener, LifecycleListener {
  Offset _velocity = const Offset(2.0, 1.5);
  late SpriteRenderer _renderer;

  @override
  void onMounted() {
    _renderer =
        internalCreateComponent(
              SpriteRenderer.new.withParams(
                (c) => c
                  ..sprite = GameSprite(
                    texture: CollisionExampleTexture.enemy,
                    pixelsPerUnit: 32.0,
                  ),
              ),
            )
            as SpriteRenderer;
    addComponent(_renderer);
  }

  @override
  void onUpdate(double dt) {
    final transform = getComponent<ObjectTransform>();
    transform.position += _velocity * dt;
  }

  @override
  void onOuterScreenEnter() {
    final transform = getComponent<ObjectTransform>();
    final camera = game.cameras.main;

    // Get world coordinates of screen corners
    final tl = camera.screenToWorldPoint(Offset.zero, game.ticker.screenSize);
    final br = camera.screenToWorldPoint(
      Offset(game.ticker.screenSize.width, game.ticker.screenSize.height),
      game.ticker.screenSize,
    );

    final left = math.min(tl.dx, br.dx);
    final right = math.max(tl.dx, br.dx);
    final top = math.max(tl.dy, br.dy);
    final bottom = math.min(tl.dy, br.dy);

    final random = math.Random();
    // Bounce horizontally
    if (transform.position.dx - 0.8 <= left && _velocity.dx < 0) {
      _velocity = Offset(
        -_velocity.dx,
        _velocity.dy + (random.nextDouble() - 0.5) * 0.5,
      );
    } else if (transform.position.dx + 0.8 >= right && _velocity.dx > 0) {
      _velocity = Offset(
        -_velocity.dx,
        _velocity.dy + (random.nextDouble() - 0.5) * 0.5,
      );
    }

    // Bounce vertically
    if (transform.position.dy + 0.8 >= top && _velocity.dy > 0) {
      _velocity = Offset(
        _velocity.dx + (random.nextDouble() - 0.5) * 0.5,
        -_velocity.dy,
      );
    } else if (transform.position.dy - 0.8 <= bottom && _velocity.dy < 0) {
      _velocity = Offset(
        _velocity.dx + (random.nextDouble() - 0.5) * 0.5,
        -_velocity.dy,
      );
    }

    // Normalize speed
    final speed = 3.0;
    final currentSpeed = _velocity.distance;
    if (currentSpeed > 0) {
      _velocity = Offset(
        (_velocity.dx / currentSpeed) * speed,
        (_velocity.dy / currentSpeed) * speed,
      );
    }
  }

  int _hitCount = 0;
  final List<Color> _colors = [
    Colors.red,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.white,
  ];

  @override
  void onCollisionEnter(Collision collision) {
    _hitCount = (_hitCount + 1) % _colors.length;
    _renderer.color = _colors[_hitCount];

    final transform = getComponent<ObjectTransform>();
    final selfPos = transform.position;
    final otherPos = collision.otherCollider.gameObject
        .getComponent<ObjectTransform>()
        .position;
    final diff = selfPos - otherPos;

    // Determine which axis has more overlap/separation
    final random = math.Random();
    if (diff.dx.abs() > diff.dy.abs()) {
      // Horizontal collision: Only flip if moving towards the object
      if ((_velocity.dx > 0 && diff.dx < 0) ||
          (_velocity.dx < 0 && diff.dx > 0)) {
        _velocity = Offset(
          -_velocity.dx,
          _velocity.dy + (random.nextDouble() - 0.5) * 0.5,
        );
        // Small push-out to prevent sticking
        transform.position += Offset(_velocity.dx.sign * 0.1, 0);
      }
    } else {
      // Vertical collision: Only flip if moving towards the object
      if ((_velocity.dy > 0 && diff.dy < 0) ||
          (_velocity.dy < 0 && diff.dy > 0)) {
        _velocity = Offset(
          _velocity.dx + (random.nextDouble() - 0.5) * 0.5,
          -_velocity.dy,
        );
        // Small push-out to prevent sticking
        transform.position += Offset(0, _velocity.dy.sign * 0.1);
      }
    }

    // Normalize speed to keep it consistent
    final speed = 3.0; // Fixed speed
    final currentSpeed = _velocity.distance;
    if (currentSpeed > 0) {
      _velocity = Offset(
        (_velocity.dx / currentSpeed) * speed,
        (_velocity.dy / currentSpeed) * speed,
      );
    }
  }
}

class StationaryTarget extends StatefulGameWidget {
  final Offset position;
  const StationaryTarget({super.key, required this.position});

  @override
  GameState<StationaryTarget> createState() => _StationaryTargetState();
}

class _StationaryTargetState extends GameState<StationaryTarget> {
  @override
  void initState() {
    super.initState();
    addComponent(
      ObjectTransform.new.withParams((c) => c.position = widget.position),
      BoxCollider.new.withParams((c) => c.size = const Size(0.5, 0.5)),
      SpriteRenderer.new.withParams(
        (c) => c
          ..sprite = GameSprite(
            texture: CollisionExampleTexture.ship,
            pixelsPerUnit: 32.0,
          )
          ..color = Colors.blue.withValues(alpha: 0.5),
      ),
    );
  }
}
