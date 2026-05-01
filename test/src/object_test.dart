import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goo2d/goo2d.dart';

class MockComponent extends Component with LifecycleListener {
  bool mountedCalled = false;
  bool unmountedCalled = false;

  @override
  void onMounted() {
    mountedCalled = true;
  }

  @override
  void onUnmounted() {
    unmountedCalled = true;
  }
}

class TestEvent extends Event<TestEventListener> {
  bool dispatched = false;
  @override
  void dispatch(TestEventListener listener) {
    dispatched = true;
    listener.onTestEvent();
  }
}

mixin TestEventListener implements EventListener {
  void onTestEvent();
}

class EventComponent extends Component with TestEventListener {
  bool eventReceived = false;
  @override
  void onTestEvent() {
    eventReceived = true;
  }
}

void main() {
  AutomatedTestWidgetsFlutterBinding.ensureInitialized();

  group('GameObject', () {
    testWidgets('should add and remove components correctly', (tester) async {
      final component = MockComponent();
      late GameObject gameObject;

      await tester.pumpWidget(
        Game(
          child: GameWidget(key: GlobalKey(), components: [() => component]),
        ),
      );
      await tester.pump();

      final element = tester.element(find.byType(GameWidget)) as GameElement;
      gameObject = element;

      expect(gameObject.components, contains(component));
      expect(component.mountedCalled, isTrue);

      gameObject.removeComponent(component);
      expect(gameObject.components, isNot(contains(component)));
      expect(component.unmountedCalled, isTrue);
    });

    testWidgets('should broadcast events to components', (tester) async {
      final eventComponent = EventComponent();

      await tester.pumpWidget(
        Game(child: GameWidget(components: [() => eventComponent])),
      );
      await tester.pump();

      final gameObject = tester.element(find.byType(GameWidget)) as GameObject;
      final event = TestEvent();

      gameObject.broadcastEvent(event);

      expect(event.dispatched, isTrue);
      expect(eventComponent.eventReceived, isTrue);
    });

    testWidgets('should broadcast events to children', (tester) async {
      final parentEventComponent = EventComponent();
      final childEventComponent = EventComponent();

      await tester.pumpWidget(
        Game(
          child: GameWidget(
            components: [() => parentEventComponent],
            children: [
              GameWidget(components: [() => childEventComponent]),
            ],
          ),
        ),
      );
      await tester.pump();

      final parentObject =
          tester.element(
                find.byWidgetPredicate(
                  (w) => w is GameWidget && w.children.isNotEmpty,
                ),
              )
              as GameObject;

      parentObject.broadcastEvent(TestEvent());

      expect(parentEventComponent.eventReceived, isTrue);
      expect(childEventComponent.eventReceived, isTrue);
    });

    testWidgets('should retrieve components correctly', (tester) async {
      final component = MockComponent();

      await tester.pumpWidget(
        Game(child: GameWidget(components: [() => component])),
      );
      await tester.pump();

      final gameObject = tester.element(find.byType(GameWidget)) as GameObject;

      expect(gameObject.getComponent<MockComponent>(), equals(component));
      expect(gameObject.tryGetComponent<MockComponent>(), equals(component));
      expect(gameObject.getComponents<MockComponent>(), contains(component));
    });

    testWidgets('should throw error when getComponent fails', (tester) async {
      await tester.pumpWidget(Game(child: const GameWidget(components: [])));
      await tester.pump();

      final gameObject = tester.element(find.byType(GameWidget)) as GameObject;

      expect(() => gameObject.getComponent<MockComponent>(), throwsStateError);
    });
  });
}
