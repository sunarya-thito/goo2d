import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:goo2d/goo2d.dart';

class TriggerDemo extends StatefulGameWidget {
  const TriggerDemo({super.key});

  @override
  GameState<TriggerDemo> createState() => _TriggerDemoState();
}

class _TriggerDemoState extends GameState<TriggerDemo> {
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

    // Trigger zone — static body with isTrigger=true, visible outline
    yield GameObjectWidget(
      children: [
        ComponentWidget(
          ObjectTransform.new.withInitialValues(
            (t) => t.position = Vector2(0, -1),
          ),
        ),
        ComponentWidget(
          Rigidbody.new.withInitialValues(
            (r) => r.bodyType = RigidbodyType.static,
          ),
        ),
        ComponentWidget(
          BoxCollider.new.withInitialValues(
            (c) => c
              ..size = Vector2(8, 4)
              ..isTrigger = true,
          ),
        ),
        ComponentWidget(_TriggerZoneRenderer.new),
      ],
    );

    // Falling boxes — spread across the screen, staggered heights
    const boxData = [
      (-6.0, 9.0),
      (-3.5, 11.0),
      (-1.0, 9.5),
      (1.5, 11.5),
      (4.0, 9.0),
      (6.5, 10.5),
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
              (c) => c.size = Vector2(0.7, 0.7),
            ),
          ),
          // Combined trigger detector + renderer in one component
          ComponentWidget(_TriggerBox.new),
        ],
      );
    }
  }
}

class _TriggerZoneRenderer extends Behavior with Renderable {
  static const _zoneWidth = 8.0;
  static const _zoneHeight = 4.0;

  @override
  void render(Canvas canvas) {
    final rect = ui.Rect.fromCenter(
      center: Offset.zero,
      width: _zoneWidth,
      height: _zoneHeight,
    );
    canvas.drawRect(rect, Paint()..color = const Color(0x18FFFF44));
    canvas.drawRect(
      rect,
      Paint()
        ..color = const Color(0xAAFFFF44)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.06,
    );
  }
}

class _TriggerBox extends Behavior with LifecycleListener, CollisionListener, Renderable {
  bool _inTrigger = false;

  @override
  Future<void> onTriggerEnter(Collider other) async {
    _inTrigger = true;
  }

  @override
  Future<void> onTriggerExit(Collider other) async {
    _inTrigger = false;
  }

  @override
  void render(Canvas canvas) {
    final color = _inTrigger
        ? const Color(0xFFFF4444)
        : const Color(0xFFCCCCCC);
    canvas.drawRect(
      ui.Rect.fromCenter(
        center: Offset.zero,
        width: 0.7,
        height: 0.7,
      ),
      Paint()..color = color,
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
