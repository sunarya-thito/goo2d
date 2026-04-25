import 'package:flutter_test/flutter_test.dart';
import 'package:goo2d/goo2d.dart';

mixin TestListener on Component implements EventListener {
  int eventCount = 0;
  void onTestEvent();
}

class TestEvent extends Event<TestListener> {
  const TestEvent();
  @override
  void dispatch(TestListener listener) => listener.onTestEvent();
}

class TestComponent extends Component with TestListener {
  @override
  void onTestEvent() => eventCount++;
}

class TestBehavior extends Behavior with TestListener {
  @override
  void onTestEvent() => eventCount++;
}

void main() {
  AutomatedTestWidgetsFlutterBinding.ensureInitialized();

  group('Event', () {
    testWidgets('should dispatch event to component', (tester) async {
      final comp = TestComponent();
      await tester.pumpWidget(
        Game(
          child: GameWidget(
            components: () => [comp],
          ),
        ),
      );
      await tester.pump();
      final gameObject = tester.element(find.byType(GameWidget)) as GameObject;

      gameObject.broadcastEvent(const TestEvent());
      expect(comp.eventCount, equals(1));
    });

    testWidgets('should dispatch event to multiple components', (tester) async {
      final comp1 = TestComponent();
      final comp2 = TestComponent();
      await tester.pumpWidget(
        Game(
          child: GameWidget(
            components: () => [comp1, comp2],
          ),
        ),
      );
      await tester.pump();
      final gameObject = tester.element(find.byType(GameWidget)) as GameObject;

      gameObject.broadcastEvent(const TestEvent());
      expect(comp1.eventCount, equals(1));
      expect(comp2.eventCount, equals(1));
    });

    testWidgets('should respect Behavior.enabled', (tester) async {
      final behavior = TestBehavior()..enabled = false;
      await tester.pumpWidget(
        Game(
          child: GameWidget(
            components: () => [behavior],
          ),
        ),
      );
      await tester.pump();
      final gameObject = tester.element(find.byType(GameWidget)) as GameObject;

      gameObject.broadcastEvent(const TestEvent());
      expect(behavior.eventCount, equals(0));

      behavior.enabled = true;
      gameObject.broadcastEvent(const TestEvent());
      expect(behavior.eventCount, equals(1));
    });

    testWidgets('should broadcast to children', (tester) async {
      final parentComp = TestComponent();
      final childComp = TestComponent();

      await tester.pumpWidget(
        Game(
          child: GameWidget(
            components: () => [parentComp],
            children: [
              GameWidget(
                components: () => [childComp],
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      final parentObject = tester.element(find.byType(GameWidget).first) as GameObject;

      parentObject.broadcastEvent(const TestEvent());
      expect(parentComp.eventCount, equals(1));
      expect(childComp.eventCount, equals(1));
    });

    testWidgets('should only send to children with sendEvent', (tester) async {
      final parentComp = TestComponent();
      final childComp = TestComponent();

      await tester.pumpWidget(
        Game(
          child: GameWidget(
            components: () => [parentComp],
            children: [
              GameWidget(
                components: () => [childComp],
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      final parentObject = tester.element(find.byType(GameWidget).first) as GameObject;

      parentObject.sendEvent(const TestEvent());
      expect(parentComp.eventCount, equals(0));
      expect(childComp.eventCount, equals(1));
    });
  });
}
