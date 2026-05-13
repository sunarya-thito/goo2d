import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:goo2d/goo2d.dart';
import 'package:goo2d_demo/shared/drag_behavior.dart';

class ShapesDemo extends StatefulGameWidget {
  const ShapesDemo({super.key});

  @override
  GameState<ShapesDemo> createState() => _ShapesDemoState();
}

class _ShapesDemoState extends GameState<ShapesDemo> {
  @override
  Iterable<Widget> build(BuildContext context) sync* {
    // Camera
    yield GameObjectWidget(
      children: [
        ComponentWidget(ObjectTransform.new),
        ComponentWidget(
          Camera.new.withInitialValues(
            (c) => c
              ..orthographicSize = 10.0
              ..backgroundColor = const Color(0xFF1A1A2E)
              ..clearFlags = CameraClearFlags.solidColor,
          ),
        ),
      ],
    );

    // Ground
    yield GameObjectWidget(
      children: [
        ComponentWidget(
          ObjectTransform.new.withInitialValues(
            (t) => t.position = Vector2(0, -8),
          ),
        ),
        ComponentWidget(
          Rigidbody.new.withInitialValues(
            (r) => r.bodyType = RigidbodyType.static,
          ),
        ),
        ComponentWidget(
          BoxCollider.new.withInitialValues(
            (c) => c.size = Vector2(22, 1),
          ),
        ),
        ComponentWidget(
          _BoxRenderer.new.withInitialValues(
            (r) => r
              ..color = const Color(0xFF3A3A5A)
              ..width = 22
              ..height = 1,
          ),
        ),
      ],
    );

    // Left wall
    yield GameObjectWidget(
      children: [
        ComponentWidget(
          ObjectTransform.new.withInitialValues(
            (t) => t.position = Vector2(-10, 0),
          ),
        ),
        ComponentWidget(
          Rigidbody.new.withInitialValues(
            (r) => r.bodyType = RigidbodyType.static,
          ),
        ),
        ComponentWidget(
          BoxCollider.new.withInitialValues(
            (c) => c.size = Vector2(1, 22),
          ),
        ),
      ],
    );

    // Right wall
    yield GameObjectWidget(
      children: [
        ComponentWidget(
          ObjectTransform.new.withInitialValues(
            (t) => t.position = Vector2(10, 0),
          ),
        ),
        ComponentWidget(
          Rigidbody.new.withInitialValues(
            (r) => r.bodyType = RigidbodyType.static,
          ),
        ),
        ComponentWidget(
          BoxCollider.new.withInitialValues(
            (c) => c.size = Vector2(1, 22),
          ),
        ),
      ],
    );

    // Circles — staggered so they don't all land at once
    const circleData = [
      (-4.0, 5.0),
      (0.0, 8.0),
      (4.0, 6.0),
    ];
    for (final (x, y) in circleData) {
      yield GameObjectWidget(
        children: [
          ComponentWidget(
            ObjectTransform.new.withInitialValues(
              (t) => t.position = Vector2(x, y),
            ),
          ),
          ComponentWidget(
            Rigidbody.new.withInitialValues(
              (r) => r.bodyType = RigidbodyType.dynamic,
            ),
          ),
          ComponentWidget(
            CircleCollider.new.withInitialValues(
              (c) => c.radius = 0.5,
            ),
          ),
          ComponentWidget(DragBehavior.new),
          ComponentWidget(
            _CircleRenderer.new.withInitialValues(
              (r) => r
                ..color = const Color(0xFFFF5555)
                ..radius = 0.5,
            ),
          ),
        ],
      );
    }

    // Boxes
    const boxData = [
      (-2.5, 5.0),
      (1.5, 7.5),
      (3.5, 5.5),
    ];
    for (final (x, y) in boxData) {
      yield GameObjectWidget(
        children: [
          ComponentWidget(
            ObjectTransform.new.withInitialValues(
              (t) => t.position = Vector2(x, y),
            ),
          ),
          ComponentWidget(
            Rigidbody.new.withInitialValues(
              (r) => r.bodyType = RigidbodyType.dynamic,
            ),
          ),
          ComponentWidget(
            BoxCollider.new.withInitialValues(
              (c) => c.size = Vector2(0.9, 0.9),
            ),
          ),
          ComponentWidget(DragBehavior.new),
          ComponentWidget(
            _BoxRenderer.new.withInitialValues(
              (r) => r
                ..color = const Color(0xFF44BB44)
                ..width = 0.9
                ..height = 0.9,
            ),
          ),
        ],
      );
    }

    // Capsules
    const capsuleData = [
      (-1.0, 7.0),
      (2.5, 6.0),
    ];
    for (final (x, y) in capsuleData) {
      yield GameObjectWidget(
        children: [
          ComponentWidget(
            ObjectTransform.new.withInitialValues(
              (t) => t.position = Vector2(x, y),
            ),
          ),
          ComponentWidget(
            Rigidbody.new.withInitialValues(
              (r) => r.bodyType = RigidbodyType.dynamic,
            ),
          ),
          ComponentWidget(
            CapsuleCollider.new.withInitialValues(
              (c) => c
                ..size = Vector2(0.5, 1.1)
                ..direction = CapsuleDirection.vertical,
            ),
          ),
          ComponentWidget(DragBehavior.new),
          ComponentWidget(
            _CapsuleRenderer.new.withInitialValues(
              (r) => r
                ..color = const Color(0xFFFF9944)
                ..width = 0.5
                ..height = 1.1,
            ),
          ),
        ],
      );
    }
  }
}

class _BoxRenderer extends Behavior with Renderable {
  Color color = Colors.white;
  double width = 1.0;
  double height = 1.0;

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      ui.Rect.fromCenter(center: Offset.zero, width: width, height: height),
      Paint()..color = color,
    );
    canvas.drawLine(
      Offset.zero,
      Offset(0, height / 2),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 0.06,
    );
  }
}

class _CircleRenderer extends Behavior with Renderable {
  Color color = Colors.white;
  double radius = 0.5;

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset.zero, radius, Paint()..color = color);
    canvas.drawLine(
      Offset.zero,
      Offset(0, radius),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 0.06,
    );
  }
}

class _CapsuleRenderer extends Behavior with Renderable {
  Color color = Colors.white;
  double width = 0.5;
  double height = 1.0;

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        ui.Rect.fromCenter(center: Offset.zero, width: width, height: height),
        Radius.circular(width / 2),
      ),
      Paint()..color = color,
    );
    canvas.drawLine(
      Offset.zero,
      Offset(0, height / 2),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 0.06,
    );
  }
}
