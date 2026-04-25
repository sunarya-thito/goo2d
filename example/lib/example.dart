import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:goo2d/goo2d.dart';

void main() {
  runApp(
    const MaterialApp(
      home: Scaffold(
        body: GameScene(
          child: MyGameObject(),
        ),
      ),
    ),
  );
}

class MyGameObject extends StatefulGameWidget {
  const MyGameObject({super.key});

  @override
  MyGameObjectState createState() => MyGameObjectState();
}

class MyGameObjectState extends GameState<MyGameObject> with PointerReceiver {
  bool test = false;

  @override
  void initState() {
    super.initState();
    addComponent(
      ObjectTransform()..position = const Offset(50, 50),
      MyTestComponent(),
      BoxCollisionTrigger()..rect = const Rect.fromLTWH(0, 0, 50, 50),
      RectangleRenderer(),
    );
  }

  @override
  void onPointerDown(PointerDownEvent event) {
    print('Pointer down!');
    getComponent<ObjectTransform>().localPosition += Offset(10, 10);
    setState(() {
      test = !test;
    });
  }

  @override
  Iterable<Widget> build(BuildContext context) sync* {
    // Demonstrate that this GameState provides access to BuildContext
    final size = MediaQuery.of(context).size;
    print('Screen size from GameState context: $size');
    if (test) {
      yield GameWidget(
        components: () => [
          ObjectTransform()..position = const Offset(100, 100),
          BoxCollisionTrigger()..rect = const Rect.fromLTWH(0, 0, 50, 50),
          RectangleRenderer()..color = Colors.green,
        ],
      );
    }
  }
}

class MyTestComponent extends Behavior with LifecycleListener {
  @override
  void onMounted() {
    print('Component added to: ${gameObject.runtimeType}');
    final state = gameObject.tryGetComponent<MyGameObjectState>();
    if (state != null) {
      print(
        'Successfully accessed GameState property: ${state.test}',
      );
    }
  }
}
