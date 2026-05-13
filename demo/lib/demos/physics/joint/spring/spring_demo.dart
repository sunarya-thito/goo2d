import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:goo2d/goo2d.dart';
import 'package:goo2d_demo/shared/drag_behavior.dart';

class SpringDemo extends StatefulGameWidget {
  const SpringDemo({super.key});

  @override
  GameState<SpringDemo> createState() => _SpringDemoState();
}

class _SpringDemoState extends GameState<SpringDemo> {
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
          BoxCollider.new.withInitialValues((c) => c.size = Vector2(22, 1)),
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

    // Ceiling anchor marker (visual only)
    yield GameObjectWidget(
      children: [
        ComponentWidget(
          ObjectTransform.new.withInitialValues(
            (t) => t.position = Vector2(0, 7),
          ),
        ),
        ComponentWidget(
          _BoxRenderer.new.withInitialValues(
            (r) => r
              ..color = const Color(0xFFDDDDDD)
              ..width = 2.0
              ..height = 0.3,
          ),
        ),
      ],
    );

    // Spring mass: world-anchored SpringJoint to ceiling at (0, 7)
    // Starts at (0, 2) → 5-unit spring → will oscillate
    yield GameObjectWidget(
      children: [
        ComponentWidget(
          ObjectTransform.new.withInitialValues(
            (t) => t.position = Vector2(0, 6),
          ),
        ),
        ComponentWidget(
          Rigidbody.new.withInitialValues(
            (r) => r
              ..bodyType = RigidbodyType.dynamic
              ..linearDamping = 0.05,
          ),
        ),
        ComponentWidget(
          BoxCollider.new.withInitialValues((c) => c.size = Vector2(0.9, 0.9)),
        ),
        ComponentWidget(
          SpringJoint.new.withInitialValues(
            (j) => j
              ..autoConfigureConnectedAnchor = false
              ..connectedAnchor = Vector2(0, 7)
              ..autoConfigureDistance = false
              ..distance = 5.0
              ..dampingRatio = 0.15
              ..frequency = 2.5,
          ),
        ),
        ComponentWidget(DragBehavior.new),
        ComponentWidget(
          _BoxRenderer.new.withInitialValues(
            (r) => r
              ..color = const Color(0xFF44CC88)
              ..width = 0.9
              ..height = 0.9,
          ),
        ),
      ],
    );
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
