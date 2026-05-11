import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:goo2d/goo2d.dart';

class HingeDemo extends StatefulGameWidget {
  const HingeDemo({super.key});

  @override
  GameState<HingeDemo> createState() => _HingeDemoState();
}

class _HingeDemoState extends GameState<HingeDemo> {
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

    // Pivot marker — visual only, no Collider so it doesn't block the bob
    yield GameObjectWidget(
      children: [
        ComponentWidget(
          ObjectTransform.new.withInitialValues(
            (t) => t.position = Vector2(0, 4),
          ),
        ),
        ComponentWidget(
          _CircleRenderer.new.withInitialValues(
            (r) => r
              ..color = const Color(0xFFDDDDDD)
              ..radius = 0.2,
          ),
        ),
      ],
    );

    // Bob: offset 3 units right of pivot — gravity will make it swing
    // HingeJoint uses connectedBody=null (world anchor) at world point (0, 4)
    yield GameObjectWidget(
      children: [
        ComponentWidget(
          ObjectTransform.new.withInitialValues(
            (t) => t.position = Vector2(3, 4),
          ),
        ),
        ComponentWidget(
          Rigidbody.new.withInitialValues(
            (r) => r
              ..bodyType = RigidbodyType.dynamic
              ..linearDamping = 0.05
              ..angularDamping = 0.05,
          ),
        ),
        ComponentWidget(
          BoxCollider.new.withInitialValues(
            (c) => c.size = Vector2(0.7, 0.7),
          ),
        ),
        ComponentWidget(
          HingeJoint.new.withInitialValues(
            (j) => j
              ..autoConfigureConnectedAnchor = false
              ..anchor = Vector2(-3, 0)  // offset from bob center → pin point
              ..connectedAnchor = Vector2(0, 4),
          ),
        ),
        ComponentWidget(
          _BoxRenderer.new.withInitialValues(
            (r) => r
              ..color = const Color(0xFF4488FF)
              ..width = 0.7
              ..height = 0.7,
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
  }
}

class _CircleRenderer extends Behavior with Renderable {
  Color color = Colors.white;
  double radius = 0.5;

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset.zero, radius, Paint()..color = color);
  }
}
