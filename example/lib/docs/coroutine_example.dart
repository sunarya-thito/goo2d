import 'package:flutter/material.dart';
import 'package:goo2d/goo2d.dart';

class CoroutineExample extends StatefulWidget {
  const CoroutineExample({super.key});

  @override
  State<CoroutineExample> createState() => _CoroutineExampleState();
}

class _CoroutineExampleState extends State<CoroutineExample> {
  late final Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = GameAsset.loadAll(CoroutineExampleTexture.values).drain();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: FutureBuilder(
          future: _loadFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }
            return const Game(child: CoroutineWorld());
          },
        ),
      ),
    );
  }
}

enum CoroutineExampleTexture with AssetEnum, TextureAssetEnum {
  ship,
  tilesPacked
  ;

  @override
  AssetSource get source => AssetSource.local("assets/sprites/$name.png");
}

class CoroutineWorld extends StatefulGameWidget {
  const CoroutineWorld({super.key});

  @override
  GameState<CoroutineWorld> createState() => _CoroutineWorldState();
}

class _CoroutineWorldState extends GameState<CoroutineWorld> {
  String _message = 'Tap anywhere to Start';
  final List<Widget> _lasers = [];
  final ObjectTransform _bossTransform = ObjectTransform();

  @override
  void initState() {
    super.initState();
    addComponent(ObjectTransform());
    _bossTransform.position = const Offset(0, -8);
  }

  void addLaser(Widget laser) => setState(() => _lasers.add(laser));
  void removeLaser(Widget laser) => setState(() => _lasers.remove(laser));

  Stream bossSequence() async* {
    setState(() {
      _message = 'Boss Appearing...';
    });

    final startPos = const Offset(0, -8);
    final endPos = Offset.zero;
    double elapsed = 0;
    while (elapsed < 1.5) {
      elapsed += game.ticker.deltaTime;
      final t = (elapsed / 1.5).clamp(0.0, 1.0);
      _bossTransform.position = Offset.lerp(
        startPos,
        endPos,
        Curves.easeOutBack.transform(t),
      )!;
      yield null;
    }

    _message = 'Charging Energy...';
    yield* chargeEffect();

    _message = 'Firing Lasers!\n(Press SPACE to Stop)';
    startCoroutineWithOption(fireLasers, option: (color: Colors.redAccent));

    double timer = 0;
    while (timer < 8.0 && !game.input.keyboard.space.isPressed) {
      timer += game.ticker.deltaTime;
      yield null;
    }

    stopAllCoroutines(fireLasers);
    _message = 'Sequence Complete!';
    yield WaitForSeconds(2.0);

    setState(() {
      _message = 'Tap anywhere to Restart';
    });
  }

  Stream chargeEffect() async* {
    for (int i = 0; i < 15; i++) {
      _bossTransform.scale = Offset(1.0 + i * 0.05, 1.0 + i * 0.05);
      yield WaitForSeconds(0.04);
    }
    for (int i = 15; i >= 0; i--) {
      _bossTransform.scale = Offset(1.0 + i * 0.05, 1.0 + i * 0.05);
      yield WaitForSeconds(0.04);
    }
  }

  Stream fireLasers(({Color color}) options) async* {
    while (true) {
      // Spawn two lasers from the wings
      final leftWing = _bossTransform.position + const Offset(-0.3, -0.5);
      final rightWing = _bossTransform.position + const Offset(0.3, -0.5);

      addLaser(
        Laser(key: UniqueKey(), startPos: leftWing, color: options.color),
      );
      addLaser(
        Laser(key: UniqueKey(), startPos: rightWing, color: options.color),
      );

      yield WaitForSeconds(0.15);
    }
  }

  @override
  Iterable<Widget> build(BuildContext context) sync* {
    yield GameWidget(
      components: () => [
        ObjectTransform(),
        Camera()
          ..depth = 1
          ..backgroundColor = const Color(0xFF0F0F0F)
          ..orthographicSize = 5,
      ],
    );

    yield GameWidget(
      components: () => [
        _bossTransform,
        SpriteRenderer()
          ..sprite = GameSprite(
            texture: CoroutineExampleTexture.ship,
            pixelsPerUnit: 32,
          ),
      ],
    );

    // Dynamic lasers
    yield* _lasers;

    yield CanvasWidget(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          // Stop all instances of these routines
          stopAllCoroutines(bossSequence);
          stopAllCoroutines(fireLasers);

          // Clear current lasers and reset state
          setState(() {
            _lasers.clear();
            _bossTransform.position = const Offset(0, -8);
            _bossTransform.scale = const Offset(1, 1);
            startCoroutine(bossSequence);
          });
        },
        child: Container(
          color: Colors.transparent,
          padding: const EdgeInsets.only(top: 80),
          alignment: Alignment.topCenter,
          child: Text(
            _message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(blurRadius: 10, color: Colors.black),
                Shadow(blurRadius: 2, color: Colors.blueAccent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Laser extends StatefulGameWidget {
  final Offset startPos;
  final Color color;
  const Laser({super.key, required this.startPos, required this.color});

  @override
  GameState<Laser> createState() => _LaserState();
}

class _LaserState extends GameState<Laser> {
  @override
  void initState() {
    super.initState();
    // Laser starts at the boss wing
    addComponent(ObjectTransform()..position = widget.startPos);
    // Each laser has its own coroutine for movement!
    startCoroutine(move);
  }

  Stream move() async* {
    final trans = getComponent<ObjectTransform>();
    final world = getComponentInParent<_CoroutineWorldState>();

    while (trans.position.dy > -10) {
      trans.position += const Offset(0, -15.0) * game.ticker.deltaTime;
      yield null;
    }

    // Self-destruct
    world.removeLaser(widget);
  }

  @override
  Iterable<Widget> build(BuildContext context) sync* {
    yield GameWidget(
      components: () => [
        ObjectTransform()
          ..scale = const Offset(
            0.3,
            1.5,
          ), // Corrected: scale belongs to ObjectTransform
        SpriteRenderer()
          ..sprite = SpriteSheet.grid(
            texture: CoroutineExampleTexture.tilesPacked,
            rows: 10,
            columns: 12,
            ppu: 64.0,
          )[(0, 0)]
          ..color = widget.color,
      ],
    );
  }
}
