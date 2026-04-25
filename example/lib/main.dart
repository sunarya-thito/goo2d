import 'package:example/test_asset.dart';
import 'package:flutter/material.dart';
import 'package:goo2d/goo2d.dart';
import 'package:vector_math/vector_math_64.dart' show Vector2;

void main() {
  GameAsset.loadAll(MyAssets.values).listen((event) {
    print('${event.assetLoaded} / ${event.assetCount}');
  });
  runApp(
    MaterialApp(
      home: Scaffold(
        body: ExampleApp(),
      ),
    ),
  );
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

final parentTag = GameTag('parent');
final childTag = GameTag('child');

class _ExampleAppState extends State<ExampleApp> {
  @override
  Widget build(BuildContext context) {
    return GameScene(
      child: Stack(
        children: [
          // The Game World
          GameWidget(
            key: parentTag,
            components: () => [
              ObjectTransform()..localPosition = Offset(0, 0),
            ],
            children: [
              // Main Camera
              GameWidget(
                key: GameTag('MainCamera'),
                components: () => [
                  ObjectTransform(),
                  Camera()
                    ..orthographicSize = 5.0
                    ..backgroundColor = Colors.black,
                  CameraFollow()..targetTag = childTag,
                ],
              ),
              // A red box in the world
              GameWidget(
                components: () => [
                  ObjectTransform()..localPosition = Offset(2, 2),
                  BoxCollisionTrigger()..rect = Rect.fromLTWH(-0.5, -0.5, 1, 1),
                  RectangleRenderer()..color = Colors.red,
                ],
              ),
              // The Player (green box)
              GameWidget(
                key: childTag,
                components: () => [
                  ObjectTransform()..localPosition = Offset(0, 0),
                  BoxCollisionTrigger()..rect = Rect.fromLTWH(-0.5, -0.5, 1, 1),
                  RectangleRenderer()..color = Colors.green,
                  CustomPointerHandler(),
                  PlayerController(),
                ],
              ),
            ],
          ),
          // UI Layer (outside GameScene or separate Camera)
          Positioned(
            top: 20,
            left: 20,
            child: Text(
              'Move with WASD\nCamera follows player',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class CameraFollow extends Behavior with Tickable {
  late GameTag targetTag;
  double smoothness = 5.0;

  @override
  void onUpdate(double dt) {
    final target = targetTag.gameObject?.getComponent<ObjectTransform>();
    if (target == null) return;

    final transform = gameObject.getComponent<ObjectTransform>();
    final targetPos = target.localPosition;

    // Smoothly interpolate camera position to target position
    final diff = targetPos - transform.localPosition;
    transform.localPosition += diff * smoothness * dt;
  }
}

class PlayerController extends Behavior with Tickable, LifecycleListener {
  late final InputAction moveAction;
  late final InputAction jumpAction;

  @override
  void onMounted() {
    moveAction = InputAction(
      name: 'Move',
      bindings: [
        Vector2CompositeBinding(
          up: Keyboard.w,
          down: Keyboard.s,
          left: Keyboard.a,
          right: Keyboard.d,
        ),
      ],
    )..enable();

    jumpAction = InputAction(
      name: 'Jump',
      bindings: [InputBinding(control: Keyboard.space)],
    )..enable();

    jumpAction.started += (context) {
      print('${context.action.name} started!');
    };

    jumpAction.canceled += (context) {
      print('${context.action.name} canceled!');
    };
  }

  @override
  void onUpdate(double dt) {
    final transform = gameObject.getComponent<ObjectTransform>();
    final move = moveAction.readValue<Vector2>();

    transform.localPosition += Offset(move.x, move.y) * 5 * dt;
  }
}

class RectangleRenderer extends Behavior with Renderable {
  Color color = Colors.red;

  @override
  void render(Canvas canvas) {
    final collider = gameObject.tryGetComponent<CollisionTrigger>();
    if (collider == null) return;
    final paint = Paint()..color = color;
    canvas.drawRect(collider.bounds, paint);
  }
}

class CustomPointerHandler extends Behavior with PointerReceiver {
  final List<Color> _cycleColors = [Colors.red, Colors.green, Colors.blue];
  int _colorIndex = 0;

  @override
  void onPointerUp(PointerUpEvent event) {
    gameObject.getComponent<RectangleRenderer>().color =
        _cycleColors[_colorIndex];
    _colorIndex = (_colorIndex + 1) % _cycleColors.length;
  }
}
