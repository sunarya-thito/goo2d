import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goo2d/goo2d.dart';
import 'package:goo2d/src/game.dart'; // To get GameProvider

void main() {
  group('Collider', () {
    testWidgets('BoxCollider worldBounds should account for offset and transform', (tester) async {
      BoxCollider? collider;
      
      await tester.pumpWidget(
        GameProvider(
          game: GameEngine(),
          child: GameWidget(
            children: [
              GameWidget(
                key: const GameTag('test'),
                components: () => [
                  ObjectTransform()..position = const Offset(100, 100),
                  collider = BoxCollider()..size = const Size(50, 50)..offset = const Offset(10, 20),
                ],
              ),
            ],
          ),
        ),
      );

      final bounds = collider!.worldBounds;
      expect(bounds.left, 85);
      expect(bounds.top, 95);
      expect(bounds.right, 135);
      expect(bounds.bottom, 145);
    });

    testWidgets('CircleCollider containsPoint should work in world space', (tester) async {
      CircleCollider? collider;

      await tester.pumpWidget(
        GameProvider(
          game: GameEngine(),
          child: GameWidget(
            children: [
              GameWidget(
                components: () => [
                  ObjectTransform()..position = const Offset(100, 100)..scale = const Offset(2, 2),
                  collider = CircleCollider()..radius = 25..offset = const Offset(10, 0),
                ],
              ),
            ],
          ),
        ),
      );

      expect(collider!.containsPoint(const Offset(120, 100)), isTrue);
      expect(collider!.containsPoint(const Offset(170, 100)), isTrue);
      expect(collider!.containsPoint(const Offset(171, 100)), isFalse);
    });

    testWidgets('CapsuleCollider worldBounds should handle vertical orientation', (tester) async {
      CapsuleCollider? collider;

      await tester.pumpWidget(
        GameProvider(
          game: GameEngine(),
          child: GameWidget(
            children: [
              GameWidget(
                components: () => [
                  ObjectTransform()..position = const Offset(0, 0),
                  collider = CapsuleCollider()
                    ..radius = 10
                    ..height = 40
                    ..direction = CapsuleDirection.vertical,
                ],
              ),
            ],
          ),
        ),
      );

      final bounds = collider!.worldBounds;
      expect(bounds.left, -10);
      expect(bounds.top, -20);
      expect(bounds.right, 10);
      expect(bounds.bottom, 20);
    });
  });
}
