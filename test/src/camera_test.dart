import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goo2d/goo2d.dart';

void main() {
  AutomatedTestWidgetsFlutterBinding.ensureInitialized();

  group('Camera', () {
    testWidgets('should resolve Camera.main by tag', (tester) async {
      final cam1 = Camera()..depth = 1;
      final cam2 = Camera()..depth = 0;

      await tester.pumpWidget(
        Game(
          child: Column(
            children: [
              Expanded(
                child: GameWidget(
                  key: const GameTag('MainCamera'),
                  components: () => [ObjectTransform(), cam1],
                ),
              ),
              Expanded(
                child: GameWidget(
                  components: () => [ObjectTransform(), cam2],
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      final game = (tester.element(find.byType(GameWidget).first) as GameObject).game;
      
      expect(game.cameras.main, same(cam1));
      expect(game.cameras.allCameras.length, equals(2));
      expect(game.cameras.allCameras.first, same(cam2)); // cam2 has lower depth
    });

    testWidgets('should calculate worldToScreenPoint correctly', (tester) async {
      final cam = Camera()..orthographicSize = 5; // 10 units high
      await tester.pumpWidget(
        Game(
          child: GameWidget(
            key: const GameTag('MainCamera'),
            components: () => [cam, ObjectTransform()],
          ),
        ),
      );
      await tester.pump();

      // With 800x600 viewport, 10 units high means 1 unit = 60 pixels
      // (0,0) world should be (400, 300) screen
      final screenPoint = cam.worldToScreenPoint(Offset.zero, const Size(800, 600));
      expect(screenPoint.dx, closeTo(400, 0.001));
      expect(screenPoint.dy, closeTo(300, 0.001));

      // (5, 5) world should be top-right? No, Y is down in screen.
      // (5, 5) world -> X: 400 + 5*60 = 700. Y: 300 - 5*60 = 0.
      final screenPoint2 = cam.worldToScreenPoint(const Offset(5, 5), const Size(800, 600));
      expect(screenPoint2.dx, closeTo(700, 0.001));
      expect(screenPoint2.dy, closeTo(0, 0.001));
    });

    testWidgets('should calculate screenToWorldPoint correctly', (tester) async {
      final cam = Camera()..orthographicSize = 5;
      await tester.pumpWidget(
        Game(
          child: GameWidget(
            key: const GameTag('MainCamera'),
            components: () => [cam, ObjectTransform()],
          ),
        ),
      );
      await tester.pump();

      final worldPoint = cam.screenToWorldPoint(const Offset(700, 0), const Size(800, 600));
      expect(worldPoint.dx, closeTo(5, 0.001));
      expect(worldPoint.dy, closeTo(5, 0.001));
    });

    testWidgets('should respect camera transform (camera movement)', (tester) async {
      final cam = Camera()..orthographicSize = 5;
      final camTransform = ObjectTransform()..localPosition = const Offset(10, 0);
      
      await tester.pumpWidget(
        Game(
          child: GameWidget(
            key: const GameTag('MainCamera'),
            components: () => [cam, camTransform],
          ),
        ),
      );
      await tester.pump();

      // World (10, 0) is now at camera center (400, 300)
      final screenPoint = cam.worldToScreenPoint(const Offset(10, 0), const Size(800, 600));
      expect(screenPoint.dx, closeTo(400, 0.001));
      expect(screenPoint.dy, closeTo(300, 0.001));
    });
  });
}
