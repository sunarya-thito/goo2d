import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goo2d/goo2d.dart';

void main() {
  AutomatedTestWidgetsFlutterBinding.ensureInitialized();

  group('Collider Components', () {
    testWidgets('BoxCollider bounds', (tester) async {
      final collider = BoxCollider()..size = const Size(100, 50);

      await tester.pumpWidget(
        Game(
          child: GameObjectWidget(
            children: [
              ComponentWidget(
                () => ObjectTransform()..position = const Offset(200, 100),
              ),
              ComponentWidget(() => collider),
            ],
          ),
        ),
      );

      // (200, 100) center with (100, 50) size -> LTRB (150, 75, 250, 125)
      expect(collider.worldBounds, const Rect.fromLTRB(150, 75, 250, 125));
    });

    testWidgets('CircleCollider bounds', (tester) async {
      final collider = CircleCollider()..radius = 50.0;

      await tester.pumpWidget(
        Game(
          child: GameObjectWidget(
            children: [
              ComponentWidget(
                () => ObjectTransform()..position = const Offset(200, 100),
              ),
              ComponentWidget(() => collider),
            ],
          ),
        ),
      );

      expect(collider.worldBounds, const Rect.fromLTRB(150, 50, 250, 150));
    });

    testWidgets('CapsuleCollider bounds (vertical)', (tester) async {
      final collider = CapsuleCollider()
        ..radius = 10.0
        ..height = 40.0
        ..direction = CapsuleDirection.vertical;

      await tester.pumpWidget(
        Game(
          child: GameObjectWidget(
            children: [
              ComponentWidget(
                () => ObjectTransform()..position = const Offset(100, 100),
              ),
              ComponentWidget(() => collider),
            ],
          ),
        ),
      );

      // Centers at (100, 90) and (100, 110) with radius 10.
      // Bounds: L=90, T=80, R=110, B=120
      expect(collider.worldBounds, const Rect.fromLTRB(90, 80, 110, 120));
    });

    testWidgets('PolygonCollider bounds', (tester) async {
      final collider = PolygonCollider()
        ..vertices = [
          const Offset(-10, -10),
          const Offset(10, -10),
          const Offset(10, 10),
          const Offset(-10, 10),
        ];

      await tester.pumpWidget(
        Game(
          child: GameObjectWidget(
            children: [
              ComponentWidget(
                () => ObjectTransform()..position = const Offset(100, 100),
              ),
              ComponentWidget(() => collider),
            ],
          ),
        ),
      );

      expect(collider.worldBounds, const Rect.fromLTRB(90, 90, 110, 110));
    });

    testWidgets('CompositeCollider bounds', (tester) async {
      final composite = CompositeCollider();
      composite.shapes.add(
        BoxGeometry()
          ..size = const Size(20, 20)
          ..offset = const Offset(-20, 0),
      );
      composite.shapes.add(
        CircleGeometry()
          ..radius = 10.0
          ..offset = const Offset(20, 0),
      );

      await tester.pumpWidget(
        Game(
          child: GameObjectWidget(
            children: [
              ComponentWidget(
                () => ObjectTransform()..position = const Offset(100, 100),
              ),
              ComponentWidget(() => composite),
            ],
          ),
        ),
      );

      // Box at (80, 100) size (20, 20) -> LTRB (70, 90, 90, 110)
      // Circle at (120, 100) radius 10 -> LTRB (110, 90, 130, 110)
      // Total bounds: LTRB (70, 90, 130, 110)
      expect(composite.worldBounds, const Rect.fromLTRB(70, 90, 130, 110));
    });

    testWidgets('Collider registration with PhysicsSystem', (tester) async {
      final collider = BoxCollider();

      await tester.pumpWidget(
        Game(
          child: GameObjectWidget(
            children: [ComponentWidget(() => collider)],
          ),
        ),
      );

      final engine = GameEngine.of(
        tester.element(find.byType(GameObjectWidget)),
      );
      expect(engine.physics?.activeColliders, contains(collider));
    });
  });
}
