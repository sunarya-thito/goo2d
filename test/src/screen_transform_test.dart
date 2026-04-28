import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goo2d/goo2d.dart';

void main() {
  group('ScreenTransform', () {
    testWidgets('should render children in screen space even when camera is moved', (tester) async {
      bool hit = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Game(
            child: GameWidget(
              children: [
                // Camera object at 5000, 5000
                GameWidget(
                  name: 'CameraObject',
                  key: const GameTag('MainCamera'),
                  components: () => [
                    Camera()..orthographicSize = 1000.0,
                    ObjectTransform()..position = const Offset(5000, 5000),
                  ],
                ),
                // HUD object in screen space
                GameWidget(
                  name: 'HUDObject',
                  components: () => [
                    ScreenTransform(),
                  ],
                  children: [
                    GameWidget(
                      name: 'Button',
                      components: () => [
                        ObjectTransform(),
                      ],
                      children: [
                        // Use a native Flutter widget for hit testing
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => hit = true,
                          child: const SizedBox(
                            width: 100,
                            height: 100,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      // Tap at screen (50, 50). 
      // Camera is at (5000, 5000), so world space (5050, 5050) maps to screen (50, 50).
      // ScreenTransform should revert this, so tapping at (50, 50) hits the child.
      await tester.tapAt(const Offset(50, 50));
      expect(hit, isTrue, reason: 'HUD should be hit at screen coordinates regardless of camera position');
    });

    testWidgets('should handle nested ScreenTransforms by applying identity', (tester) async {
      bool hit = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Game(
            child: GameWidget(
              children: [
                GameWidget(
                  key: const GameTag('MainCamera'),
                  components: () => [
                    Camera()..orthographicSize = 1000.0,
                    ObjectTransform()..position = const Offset(5000, 5000),
                  ],
                ),
                GameWidget(
                  name: 'OuterHUD',
                  components: () => [ScreenTransform()],
                  children: [
                    GameWidget(
                      name: 'InnerHUD',
                      components: () => [ScreenTransform()],
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => hit = true,
                          child: const SizedBox(width: 100, height: 100),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tapAt(const Offset(50, 50));
      expect(hit, isTrue, reason: 'Nested ScreenTransform should still be hit at screen coordinates');
    });

    testWidgets('should respect BoxConstraints', (tester) async {
      Size? reportedSize;
      await tester.pumpWidget(
        MaterialApp(
          home: Game(
            child: GameWidget(
              name: 'Root',
              children: [
                GameWidget(
                  name: 'HUD',
                  components: () => [
                    ScreenTransform()
                      ..constraints = const BoxConstraints.tightFor(width: 200, height: 100),
                  ],
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        reportedSize = constraints.biggest;
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(reportedSize, const Size(200, 100), reason: 'ScreenTransform should enforce its constraints on children when allowed by parent');
    });
  });
}
