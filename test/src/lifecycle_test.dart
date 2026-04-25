import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goo2d/goo2d.dart';

class TestLifecycleComponent extends Component with LifecycleListener {
  int mountedCount = 0;
  int unmountedCount = 0;

  @override
  void onMounted() {
    mountedCount++;
  }

  @override
  void onUnmounted() {
    unmountedCount++;
  }
}

void main() {
  AutomatedTestWidgetsFlutterBinding.ensureInitialized();

  group('Lifecycle', () {
    testWidgets('should call onMounted when added to mounted GameObject', (tester) async {
      await tester.pumpWidget(
        const Game(
          child: GameWidget(),
        ),
      );
      await tester.pump();
      final gameObject = tester.element(find.byType(GameWidget)) as GameObject;

      final component = TestLifecycleComponent();
      gameObject.addComponent(component);

      expect(component.mountedCount, equals(1));
      expect(component.unmountedCount, equals(0));
    });

    testWidgets('should call onMounted when GameObject is mounted with component', (tester) async {
      final component = TestLifecycleComponent();
      
      await tester.pumpWidget(
        Game(
          child: GameWidget(
            components: () => [component],
          ),
        ),
      );
      await tester.pump();

      expect(component.mountedCount, equals(1));
    });

    testWidgets('should call onUnmounted when component is removed', (tester) async {
      final component = TestLifecycleComponent();
      
      await tester.pumpWidget(
        Game(
          child: GameWidget(
            components: () => [component],
          ),
        ),
      );
      await tester.pump();
      final gameObject = tester.element(find.byType(GameWidget)) as GameObject;

      gameObject.removeComponent(component);
      expect(component.unmountedCount, equals(1));
    });

    testWidgets('should call onUnmounted when GameObject is unmounted', (tester) async {
      final component = TestLifecycleComponent();
      
      await tester.pumpWidget(
        Game(
          child: GameWidget(
            components: () => [component],
          ),
        ),
      );
      await tester.pump();

      // Unmount the whole scene
      await tester.pumpWidget(const Game(child: SizedBox()));
      await tester.pump();
      
      expect(component.unmountedCount, equals(1));
    });

    testWidgets('should propagate lifecycle events to children', (tester) async {
      final parentComponent = TestLifecycleComponent();
      final childComponent = TestLifecycleComponent();

      await tester.pumpWidget(
        Game(
          child: GameWidget(
            components: () => [parentComponent],
            children: [
              GameWidget(
                components: () => [childComponent],
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(parentComponent.mountedCount, equals(1));
      expect(childComponent.mountedCount, equals(1));

      // Unmount parent
      await tester.pumpWidget(const Game(child: SizedBox()));
      await tester.pump();

      expect(parentComponent.unmountedCount, equals(1));
      expect(childComponent.unmountedCount, equals(1));
    });

    testWidgets('should handle add/remove/add sequence correctly', (tester) async {
      final component = TestLifecycleComponent();
      
      await tester.pumpWidget(
        const Game(
          child: GameWidget(),
        ),
      );
      await tester.pump();
      final gameObject = tester.element(find.byType(GameWidget)) as GameObject;

      gameObject.addComponent(component);
      expect(component.mountedCount, equals(1));

      gameObject.removeComponent(component);
      expect(component.unmountedCount, equals(1));

      gameObject.addComponent(component);
      expect(component.mountedCount, equals(2));
    });
  });
}
