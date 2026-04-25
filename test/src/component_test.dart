import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goo2d/goo2d.dart';

class CompA extends Component {}
class CompB extends Component {}
class CompC extends Component {}

class MyGameState extends GameState<MyGameWidget> {
  @override
  Iterable<Widget> build(BuildContext context) => const [];
}

class MyGameWidget extends StatefulGameWidget {
  const MyGameWidget({super.key});
  @override
  GameState createState() => MyGameState();
}

void main() {
  AutomatedTestWidgetsFlutterBinding.ensureInitialized();

  group('Component', () {
    testWidgets('should find components by type', (tester) async {
      final a = CompA();
      final b = CompB();
      
      await tester.pumpWidget(
        Game(
          child: GameWidget(
            components: () => [a, b],
          ),
        ),
      );
      final gameObject = tester.element(find.byType(GameWidget)) as GameObject;

      expect(gameObject.getComponent<CompA>(), equals(a));
      expect(gameObject.getComponent<CompB>(), equals(b));
      expect(gameObject.tryGetComponent<CompC>(), isNull);
      expect(() => gameObject.getComponent<CompC>(), throwsStateError);
    });

    testWidgets('should find multiple components of the same type', (tester) async {
      final a1 = CompA();
      final a2 = CompA();
      
      await tester.pumpWidget(
        Game(
          child: GameWidget(
            components: () => [a1, a2],
          ),
        ),
      );
      final gameObject = tester.element(find.byType(GameWidget)) as GameObject;

      final comps = gameObject.getComponents<CompA>();
      expect(comps.length, equals(2));
      expect(comps, contains(a1));
      expect(comps, contains(a2));
    });

    testWidgets('should find components in children', (tester) async {
      final a = CompA();
      
      await tester.pumpWidget(
        Game(
          child: GameWidget(
            children: [
              GameWidget(
                components: () => [a],
              ),
            ],
          ),
        ),
      );
      final parentObject = tester.element(find.byType(GameWidget).first) as GameObject;

      expect(parentObject.getComponentsInChildren<CompA>(), contains(a));
    });

    testWidgets('should find components in parents', (tester) async {
      final a = CompA();
      
      await tester.pumpWidget(
        Game(
          child: GameWidget(
            components: () => [a],
            children: [
              const GameWidget(),
            ],
          ),
        ),
      );
      final childObject = tester.element(find.byType(GameWidget).last) as GameObject;

      expect(childObject.getComponentInParent<CompA>(), equals(a));
    });

    testWidgets('should access stateObject correctly', (tester) async {
      final comp = CompA();
      await tester.pumpWidget(
        const Game(
          child: MyGameWidget(),
        ),
      );
      final gameObject = tester.element(find.byType(MyGameWidget)) as GameObject;
      gameObject.addComponent(comp);

      final state = comp.stateObject<MyGameState>();
      expect(state, isA<MyGameState>());
    });

    testWidgets('should allow adding components from within a component', (tester) async {
      final b = CompB();
      final a = CompA();
      
      await tester.pumpWidget(
        Game(
          child: GameWidget(
            components: () => [a],
          ),
        ),
      );
      
      a.addComponent(b);
      expect(a.gameObject.getComponent<CompB>(), equals(b));
    });
  });
}
