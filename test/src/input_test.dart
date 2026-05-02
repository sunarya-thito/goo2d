import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goo2d/goo2d.dart';
import 'package:goo2d/src/ticker.dart';

void main() {
  AutomatedTestWidgetsFlutterBinding.ensureInitialized();

  group('Input', () {
    testWidgets('InputAction should transition phases for button type', (tester) async {
      final control = ButtonControl(GameEngine()); // Temporary for registration
      final action = InputAction()
        ..name = 'test'
        ..type = InputActionType.button
        ..bindings = [SimpleInputBinding(control: control)];

      await tester.pumpWidget(
        Game(
          child: GameObjectWidget(
            children: [ComponentWidget(() => action)],
          ),
        ),
      );
      await tester.pump();

      final game = (tester.element(find.byType(GameObjectWidget)) as GameObject).game;
      
      // Update control with the real game instance from the widget tree
      final realControl = ButtonControl(game);
      action.bindings.clear();
      action.bindings.add(SimpleInputBinding(control: realControl));

      action.enable();
      expect(action.phase, equals(InputActionPhase.waiting));

      realControl.press();
      game.input.update();

      expect(action.phase, equals(InputActionPhase.performed));
      expect(action.wasPressedThisFrame, isTrue);
      expect(action.wasPerformedThisFrame, isTrue);

      realControl.release();
      game.input.update();

      expect(action.phase, equals(InputActionPhase.waiting));
      expect(action.wasCompletedThisFrame, isTrue);
    });

    testWidgets('InputAction should transition phases for value type', (tester) async {
      final action = InputAction()
        ..name = 'test'
        ..type = InputActionType.value;

      await tester.pumpWidget(
        Game(
          child: GameObjectWidget(
            children: [ComponentWidget(() => action)],
          ),
        ),
      );
      await tester.pump();

      final game = (tester.element(find.byType(GameObjectWidget)) as GameObject).game;
      final control = ButtonControl(game);
      action.bindings.add(SimpleInputBinding(control: control));

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

    testWidgets('CompositeBinding should calculate direction correctly', (tester) async {
      await tester.pumpWidget(Game(child: const SizedBox()));
      final game = (tester.widget(find.byType(GameLoop)) as GameLoop).game;

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

    testWidgets('InputAction events should be triggered', (tester) async {
      final action = InputAction()
        ..name = 'test';

      await tester.pumpWidget(
        Game(
          child: GameObjectWidget(
            children: [ComponentWidget(() => action)],
          ),
        ),
      );
      await tester.pump();

      final game = (tester.element(find.byType(GameObjectWidget)) as GameObject).game;
      final control = ButtonControl(game);
      action.bindings.add(SimpleInputBinding(control: control));
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

    testWidgets('InputAction should handle dynamic enable/disable registration', (tester) async {
      final action = InputAction()
        ..name = 'test';
      action.enabled = false;

      await tester.pumpWidget(
        Game(
          child: GameObjectWidget(
            children: [ComponentWidget(() => action)],
          ),
        ),
      );
      await tester.pump();

      final game = (tester.element(find.byType(GameObjectWidget)) as GameObject).game;
      final control = ButtonControl(game);
      action.bindings.add(SimpleInputBinding(control: control));

      // Should NOT be registered yet
      control.press();
      game.input.update();
      expect(action.phase, equals(InputActionPhase.waiting));

      // Enable while mounted
      action.enabled = true;
      game.input.update(); // Process phase
      expect(action.phase, equals(InputActionPhase.performed));

      // Disable while mounted
      action.enabled = false;
      expect(action.phase, equals(InputActionPhase.waiting));
      
      control.release();
      game.input.update();
      // Should not transition since unregistered
      expect(action.phase, equals(InputActionPhase.waiting));
    });
  });
}
