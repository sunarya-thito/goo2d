import 'package:flutter_test/flutter_test.dart';
import 'package:goo2d/goo2d.dart';

void main() {
  AutomatedTestWidgetsFlutterBinding.ensureInitialized();

  group('Input', () {
    late GameEngine game;

    setUp(() {
      game = GameEngine();
      game.initialize();
    });

    tearDown(() {
      game.dispose();
    });

    test('InputAction should transition phases for button type', () {
      final control = ButtonControl(game);
      final action = InputAction(
        game: game,
        name: 'test',
        type: InputActionType.button,
        bindings: [SimpleInputBinding(control: control)],
      );

      action.enable();
      expect(action.phase, equals(InputActionPhase.waiting));

      control.press();
      game.input.update();

      expect(action.phase, equals(InputActionPhase.performed));
      expect(action.wasPressedThisFrame, isTrue);
      expect(action.wasPerformedThisFrame, isTrue);

      control.release();
      game.input.update();

      expect(action.phase, equals(InputActionPhase.waiting));
      expect(action.wasCompletedThisFrame, isTrue);
    });

    test('InputAction should transition phases for value type', () {
      final control = ButtonControl(game);
      final action = InputAction(
        game: game,
        name: 'test',
        type: InputActionType.value,
        bindings: [SimpleInputBinding(control: control)],
      );

      action.enable();

      control.press();
      game.input.update();
      expect(action.phase, equals(InputActionPhase.started));

      game.input.update();
      expect(action.phase, equals(InputActionPhase.performed));

      control.release();
      game.input.update();
      expect(action.phase, equals(InputActionPhase.waiting));
    });

    test('CompositeBinding should calculate direction correctly', () {
      final up = ButtonControl(game);
      final down = ButtonControl(game);
      final left = ButtonControl(game);
      final right = ButtonControl(game);
 
      final binding = CompositeBinding(
        up: up,
        down: down,
        left: left,
        right: right,
      );
 
      expect(binding.read(), equals(Offset.zero));
 
      up.press();
      right.press();
      expect(binding.read(), equals(const Offset(1, 1)));
 
      up.release();
      expect(binding.read(), equals(const Offset(1, 0)));
    });

    test('InputAction events should be triggered', () {
      final control = ButtonControl(game);
      final action = InputAction(
        game: game,
        name: 'test',
        bindings: [SimpleInputBinding(control: control)],
      );
      action.enable();

      int startedCount = 0;
      int performedCount = 0;
      int canceledCount = 0;

      action.started += (_) => startedCount++;
      action.performed += (_) => performedCount++;
      action.canceled += (_) => canceledCount++;

      control.press();
      game.input.update();
      expect(startedCount, equals(1));
      expect(performedCount, equals(1));

      control.release();
      game.input.update();
      expect(canceledCount, equals(1));
    });

    test('InputAction should return default value when disabled', () {
      final control = ButtonControl(game);
      final action = InputAction(
        game: game,
        name: 'test',
        bindings: [SimpleInputBinding(control: control)],
      );

      control.press();
      expect(action.readValue<bool>(), isFalse);

      action.enable();
      expect(action.readValue<bool>(), isTrue);
    });
  });
}
