import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goo2d/goo2d.dart';

class MockScreenReceiver extends Component with ScreenCollidable, OuterScreenCollidable {
  int enterCount = 0;
  int exitCount = 0;
  int outerEnterCount = 0;
  int outerExitCount = 0;

  @override
  void onEnterScreen() => enterCount++;
  @override
  void onExitScreen() => exitCount++;
  @override
  void onOuterScreenEnter() => outerEnterCount++;
  @override
  void onOuterScreenExit() => outerExitCount++;
}

void main() {
  AutomatedTestWidgetsFlutterBinding.ensureInitialized();

  group('Screen', () {
    testWidgets('should detect onEnterScreen and onExitScreen based on camera view', (tester) async {
      final receiver = MockScreenReceiver();
      final collider = BoxCollider()..size = const Size(2, 2);
      final transform = ObjectTransform()..localPosition = const Offset(100, 0);

      await tester.pumpWidget(
        Game(
          child: Column(
            children: [
              Expanded(
                child: GameWidget(
                  key: const GameTag('MainCamera'),
                  components: () => [Camera(), ObjectTransform()],
                ),
              ),
              Expanded(
                child: GameWidget(
                  components: () => [receiver, collider, transform],
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      final game = (tester.element(find.byType(GameWidget).first) as GameObject).game;

      // Initial state: outside
      game.screen.update(const Size(800, 600));
      expect(receiver.enterCount, equals(0));
      
      // Move into center
      transform.localPosition = Offset.zero;
      game.screen.update(const Size(800, 600));
      expect(receiver.enterCount, equals(1));
      
      // Move out
      transform.localPosition = const Offset(20, 0);
      game.screen.update(const Size(800, 600));
      expect(receiver.exitCount, equals(1));
    });

    testWidgets('should detect OuterScreen events when partially exiting', (tester) async {
      final receiver = MockScreenReceiver();
      final collider = BoxCollider()..size = const Size(4, 4);
      final transform = ObjectTransform()..localPosition = Offset.zero;

      await tester.pumpWidget(
        Game(
          child: Column(
            children: [
              Expanded(
                child: GameWidget(
                  key: const GameTag('MainCamera'),
                  components: () => [Camera(), ObjectTransform()],
                ),
              ),
              Expanded(
                child: GameWidget(
                  components: () => [receiver, collider, transform],
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      final game = (tester.element(find.byType(GameWidget).first) as GameObject).game;

      // Starts fully inside
      game.screen.update(const Size(800, 600));
      receiver.outerExitCount = 0; 
      expect(receiver.outerEnterCount, equals(0));

      // Move so it's partially outside
      transform.localPosition = const Offset(12, 0); 
      game.screen.update(const Size(800, 600));
      expect(receiver.outerEnterCount, equals(1));

      // Move back fully inside
      transform.localPosition = Offset.zero;
      game.screen.update(const Size(800, 600));
      expect(receiver.outerExitCount, equals(1));
    });

    testWidgets('should fallback to screen space if no camera is enabled', (tester) async {
      final receiver = MockScreenReceiver();
      final collider = BoxCollider()..size = const Size(10, 10)..offset = const Offset(5, 5);
      final transform = ObjectTransform()..localPosition = const Offset(-20, -20);

      await tester.pumpWidget(
        Game(
          child: GameWidget(
            components: () => [receiver, collider, transform],
          ),
        ),
      );
      await tester.pump();

      final game = (tester.element(find.byType(GameWidget).first) as GameObject).game;
      expect(game.physics.activeColliders.length, equals(1));

      game.screen.update(const Size(800, 600));
      expect(receiver.enterCount, equals(0));

      transform.localPosition = const Offset(10, 10);
      game.screen.update(const Size(800, 600));
      expect(receiver.enterCount, equals(1));
    });
  });
}
