import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goo2d/goo2d.dart';

void main() {
  group('CanvasWidget', () {
    testWidgets('should render and exist in the tree', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Game(
            child: CanvasWidget(
              child: Container(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CanvasWidget), findsOneWidget);
    });

    testWidgets('should render children in screen space even when camera is moved', (tester) async {
      bool hit = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Game(
            // Root GameWidget acts as a multi-child container with identity transform
            child: GameWidget(
              children: [
                // Camera object at 5000, 5000
                GameWidget(
                  components: () => [
                    Camera()..orthographicSize = 1000.0,
                    ObjectTransform()..position = const Offset(5000, 5000),
                  ],
                ),
                // HUD object in screen space
                CanvasWidget(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => hit = true,
                    child: const SizedBox(
                      width: 100,
                      height: 100,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      // Tap at screen (50, 50). 
      // RenderWorld transforms (50, 50) -> (5050, 5050) in world space.
      // Root GameWidget (Identity) passes (5050, 5050) to CanvasWidget.
      // CanvasWidget inverts the camera matrix, which maps (5050, 5050) back to (50, 50).
      // Hit is successful!
      await tester.tapAt(const Offset(50, 50));
      expect(hit, isTrue, reason: 'HUD should be hit at screen coordinates regardless of camera position');
    });

    testWidgets('should fall back to identity transform when camera is missing', (tester) async {
      bool hit = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Game(
            child: CanvasWidget(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => hit = true,
                child: const SizedBox(
                  width: 100,
                  height: 100,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tapAt(const Offset(50, 50));
      expect(hit, isTrue, reason: 'HUD should be hit even if no camera exists (identity fallback)');
    });
  });
}
