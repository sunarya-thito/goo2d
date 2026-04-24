import 'package:flutter/material.dart';
import 'package:goo2d/goo2d.dart';
import 'package:vector_math/vector_math_64.dart' show Vector2;

void main() {
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
      child: GameWidget(
        key: parentTag,
        components: () => [
          ObjectTransform()..localPosition = Offset(100, 100),
          BoxCollider()..rect = Rect.fromLTWH(0, 0, 100, 100),
          RectangleRenderer()..color = Colors.red,
        ],
        children: [
          GameWidget(
            key: childTag,
            components: () => [
              ObjectTransform()..localPosition = Offset(50, 50),
              BoxCollider()..rect = Rect.fromLTWH(0, 0, 100, 100),
              RectangleRenderer()..color = Colors.green,
              CustomPointerHandler(),
              PlayerController(),
            ],
          ),
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              color: Colors.blue,
              width: 50,
              height: 50,
            ),
          ),
        ],
      ),
    );
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
    
    transform.localPosition += Offset(move.x, move.y) * 200 * dt;
  }
}

class RectangleRenderer extends Behavior with Renderable {
  Color color = Colors.red;

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = color;
    canvas.drawRect(gameObject.getComponent<Collider>().bounds, paint);
  }
}

class CustomPointerHandler extends Behavior with PointerReceiver {
  final List<Color> _cycleColors = [Colors.red, Colors.green, Colors.blue];
  int _colorIndex = 0;

  @override
  void onPointerUp(PointerUpEvent event) {
    parentTag.gameObject!.getComponent<RectangleRenderer>().color =
        _cycleColors[_colorIndex];
    _colorIndex = (_colorIndex + 1) % _cycleColors.length;
  }
}
