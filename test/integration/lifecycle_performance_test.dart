import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:goo2d/goo2d.dart';
import 'package:goo2d/src/component.dart';

void main() {
  if (!const bool.fromEnvironment('INTEGRATION_TEST')) {
    return;
  }
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Goo2D Lifecycle Benchmarks (Extreme)', () {
    // Component mutation stress
    final componentCounts = [100, 500, 1000, 2500, 5000];
    for (final n in componentCounts) {
      testWidgets('Lifecycle.ComponentMutation ($n)', (tester) async {
        final rootTag = GameTag('root_$n');
        await tester.pumpWidget(MaterialApp(home: Game(child: GameWidget(key: rootTag, name: 'root'))));
        await tester.pump();
        final rootObject = rootTag.gameObject!;
        final colliders = List.generate(n, (_) => internalCreateComponent(BoxCollider.new) as BoxCollider);

        await binding.traceAction(() async {
          for (final c in colliders) {
            rootObject.addComponent(() => c);
          }
          for (final c in colliders) {
            rootObject.removeComponent(c);
          }
        }, reportKey: 'lifecycle_components_$n');
      });
    }

    // Widget tree reconciliation stress
    final rebuildCounts = [100, 500, 1000, 2500];
    for (final n in rebuildCounts) {
      testWidgets('Lifecycle.WidgetTreeRebuild ($n objects)', (tester) async {
        await tester.pumpWidget(MaterialApp(home: Game(child: const GameWidget(name: 'scene_a'))));
        await tester.pump();

        await binding.traceAction(() async {
          await tester.pumpWidget(MaterialApp(
            home: Game(
              child: GameWidget(
                name: 'scene_b',
                children: List.generate(n, (i) => GameWidget(
                  name: 'obj_$i',
                  components: [ObjectTransform.new, BoxCollider.new],
                )),
              ),
            ),
          ));
          await tester.pump();
        }, reportKey: 'lifecycle_rebuild_$n');
      });
    }
  });
}
