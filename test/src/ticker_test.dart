import 'package:flutter_test/flutter_test.dart';
import 'package:goo2d/goo2d.dart';

class MockTickable extends Component with Tickable {
  int updateCount = 0;
  double lastDt = 0;

  @override
  void onUpdate(double dt) {
    updateCount++;
    lastDt = dt;
  }
}

class MockFixedTickable extends Component with FixedTickable {
  int fixedUpdateCount = 0;
  double lastDt = 0;

  @override
  void onFixedUpdate(double dt) {
    fixedUpdateCount++;
    lastDt = dt;
  }
}

void main() {
  AutomatedTestWidgetsFlutterBinding.ensureInitialized();

  group('GameTicker', () {
    testWidgets('should increment frameCount and update deltaTime', (
      tester,
    ) async {
      final tickable = MockTickable();

      await tester.pumpWidget(
        Game(child: GameWidget(components: () => [tickable])),
      );

      final game = (tester.element(find.byType(GameWidget)) as GameObject).game;
      final initialFrameCount = game.ticker.frameCount;

      // Pump one frame
      await tester.pump(const Duration(milliseconds: 16));

      expect(game.ticker.frameCount, equals(initialFrameCount + 1));
      expect(game.ticker.deltaTime, closeTo(0.016, 0.001));
      expect(tickable.updateCount, equals(1));
      expect(tickable.lastDt, equals(game.ticker.deltaTime));
    });

    testWidgets('should run multiple FixedUpdate ticks when delta is large', (
      tester,
    ) async {
      final fixedTickable = MockFixedTickable();

      await tester.pumpWidget(
        Game(child: GameWidget(components: () => [fixedTickable])),
      );
      await tester.pump();

      // Default fixedDeltaTime is 0.02 (20ms)
      await tester.pump(const Duration(milliseconds: 61));

      expect(fixedTickable.fixedUpdateCount, equals(3));
      expect(fixedTickable.lastDt, equals(0.02));
    });

    testWidgets('should respect custom fixedDeltaTime', (tester) async {
      final fixedTickable = MockFixedTickable();

      await tester.pumpWidget(
        Game(child: GameWidget(components: () => [fixedTickable])),
      );
      await tester.pump();

      final game = (tester.element(find.byType(GameWidget)) as GameObject).game;
      game.ticker.fixedDeltaTime = 0.01; // 10ms

      // Pump 25ms, should trigger 2 fixed updates
      await tester.pump(const Duration(milliseconds: 25));

      expect(fixedTickable.fixedUpdateCount, equals(2));

      // Pump another 10ms (total 35ms), should trigger 1 more (total 3)
      await tester.pump(const Duration(milliseconds: 10));
      expect(fixedTickable.fixedUpdateCount, equals(3));
    });

    testWidgets('should maintain accumulator between frames', (tester) async {
      final fixedTickable = MockFixedTickable();

      await tester.pumpWidget(
        Game(child: GameWidget(components: () => [fixedTickable])),
      );
      await tester.pump();

      final game = (tester.element(find.byType(GameWidget)) as GameObject).game;
      game.ticker.fixedDeltaTime = 0.02; // 20ms

      // Frame 1: 15ms. Accumulator: 15ms. FixedUpdate: 0.
      await tester.pump(const Duration(milliseconds: 15));
      expect(fixedTickable.fixedUpdateCount, equals(0));

      // Frame 2: 15ms. Accumulator: 15 + 15 = 30ms. FixedUpdate: 1 (20ms used, 10ms left).
      await tester.pump(const Duration(milliseconds: 15));
      expect(fixedTickable.fixedUpdateCount, equals(1));

      // Frame 3: 15ms. Accumulator: 10 + 15 = 25ms. FixedUpdate: 1 (total 2).
      await tester.pump(const Duration(milliseconds: 15));
      expect(fixedTickable.fixedUpdateCount, equals(2));
    });
  });
}
