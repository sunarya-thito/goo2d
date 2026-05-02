import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goo2d/goo2d.dart';

void main() {
  AutomatedTestWidgetsFlutterBinding.ensureInitialized();

  group('Input Binding Refactor', () {
    testWidgets('should support Keyboard.key pattern (late binding)', (
      tester,
    ) async {
      final action = InputAction()
        ..name = 'test'
        ..bindings = [Keyboard.space];

      await tester.pumpWidget(
        Game(
          child: GameObjectWidget(
            children: [ComponentWidget(() => action)],
          ),
        ),
      );
      await tester.pump();

      final game =
          (tester.element(find.byType(GameObjectWidget)) as GameObject).game;

      // Initially not pressed
      expect(action.inProgress, isFalse);

      // Simulate press
      await simulateKeyDownEvent(LogicalKeyboardKey.space);
      game.input.update();

      expect(
        action.inProgress,
        isTrue,
        reason: 'Action should be in progress after key down',
      );
      expect(action.wasPressedThisFrame, isTrue);

      // Simulate release
      await simulateKeyUpEvent(LogicalKeyboardKey.space);
      game.input.update();

      expect(
        action.inProgress,
        isFalse,
        reason: 'Action should not be in progress after key up',
      );
      expect(action.wasCanceledThisFrame, isTrue);
    });

    testWidgets('should support late-bound composite bindings', (tester) async {
      final moveAction = InputAction()
        ..name = 'move'
        ..type = InputActionType.value
        ..bindings = [
          InputBinding.composite(
            up: Keyboard.keyW,
            down: Keyboard.keyS,
            left: Keyboard.keyA,
            right: Keyboard.keyD,
          ),
        ];

      await tester.pumpWidget(
        Game(
          child: GameObjectWidget(
            children: [ComponentWidget(() => moveAction)],
          ),
        ),
      );
      await tester.pump();

      final game =
          (tester.element(find.byType(GameObjectWidget)) as GameObject).game;

      // Press W
      await simulateKeyDownEvent(LogicalKeyboardKey.keyW);
      game.input.update();

      final val = moveAction.readValue<Offset>();
      expect(val.dy, equals(1.0));
      expect(val.dx, equals(0.0));

      // Press D (simultaneous)
      await simulateKeyDownEvent(LogicalKeyboardKey.keyD);
      game.input.update();

      final val2 = moveAction.readValue<Offset>();
      expect(val2.dy, equals(1.0));
      expect(val2.dx, equals(1.0));
    });

    testWidgets('should maintain backward compatibility with InputControl', (
      tester,
    ) async {
      final action = InputAction()..name = 'legacy';

      await tester.pumpWidget(
        Game(
          child: GameObjectWidget(
            children: [ComponentWidget(() => action)],
          ),
        ),
      );
      await tester.pump();
      final game =
          (tester.element(find.byType(GameObjectWidget)) as GameObject).game;

      // Manually add binding after mount to test binding update
      action.bindings = [Keyboard.space];

      await simulateKeyDownEvent(LogicalKeyboardKey.space);
      game.input.update();

      expect(action.inProgress, isTrue, reason: 'Legacy binding should work');
    });
  });
}
