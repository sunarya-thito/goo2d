import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:goo2d/goo2d.dart';

enum CollisionExampleTexture with AssetEnum, TextureAssetEnum {
  enemy,
  tilesPacked
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
        return const Game(child: CollisionExampleWorld());
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
    yield const MovingBox();
    yield const StationaryTarget();

    yield GameWidget(
      components: () => [
        ObjectTransform(),
        Camera()
          ..orthographicSize = 5.0
          ..depth = 1.0,
      ],
    );
  }
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
      ObjectTransform()..position = const Offset(-2, 0),
      BoxCollisionTrigger()..rect = const Rect.fromLTWH(-0.25, -0.25, 0.5, 0.5),
      BouncingBehavior(),
    );
  }
}

class BouncingBehavior extends Behavior
    with Tickable, OuterScreenCollidable, Collidable, LifecycleListener {
  Offset _velocity = const Offset(2.0, 1.5);
  late SpriteRenderer _renderer;

  @override
  void onMounted() {
    _renderer = SpriteRenderer()
      ..sprite = GameSprite(
        texture: CollisionExampleTexture.enemy,
        pixelsPerUnit: 64.0,
      );
    addComponent(_renderer);
  }

  @override
  void onUpdate(double dt) {
    final transform = getComponent<ObjectTransform>();
    transform.position += _velocity * dt;
  }

  @override
  void onOuterScreenEnter() {
    _velocity = Offset(-_velocity.dx, -_velocity.dy);
  }

  @override
  void onCollision(CollisionEvent event) {
    _renderer.color = Colors.red;
  }
}

class StationaryTarget extends StatefulGameWidget {
  const StationaryTarget({super.key});

  @override
  GameState<StationaryTarget> createState() => _StationaryTargetState();
}

class _StationaryTargetState extends GameState<StationaryTarget> {
  @override
  void initState() {
    super.initState();
    addComponent(
      ObjectTransform()..position = const Offset(0, 0),
      BoxCollisionTrigger()..rect = const Rect.fromLTWH(-0.5, -0.5, 1.0, 1.0),
      SpriteRenderer()
        ..sprite = GameSprite(
          texture: CollisionExampleTexture.tilesPacked,
          pixelsPerUnit: 64.0,
        )
        ..color = Colors.blue.withValues(alpha: 0.5),
    );
  }
}
