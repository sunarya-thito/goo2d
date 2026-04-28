import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:goo2d/goo2d.dart';

void main() {
  if (!const bool.fromEnvironment('INTEGRATION_TEST')) {
    return;
  }
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Goo2D Lookup Scaling Benchmarks (Extreme)', () {
    // Scaling up to 100,000 objects
    final lookupCounts = [100, 1000, 10000, 50000, 100000];
    
    for (final n in lookupCounts) {
      testWidgets('Lookup.getComponentsInChildren ($n objects)', (tester) async {
        final rootTag = GameTag('root_obj_$n');
        await tester.pumpWidget(MaterialApp(
          home: Game(child: LookupStressScene(count: n, rootTag: rootTag)),
        ));
        await tester.pump();
        final rootObject = rootTag.gameObject!;
        
        await binding.traceAction(() async {
          final _ = rootObject.getComponentsInChildren<BoxCollider>();
        }, reportKey: 'lookup_downward_$n');
      });
    }

    // Scaling up to 500 layers deep
    final pathDepths = [10, 50, 100, 250, 500]; 
    for (final d in pathDepths) {
      testWidgets('Lookup.findChildPath (Depth $d)', (tester) async {
        final rootTag = GameTag('path_root_$d');
        await tester.pumpWidget(MaterialApp(
          home: Game(child: PathStressScene(depth: d, rootTag: rootTag)),
        ));
        await tester.pump();
        final rootObject = rootTag.gameObject!;
        final path = List.generate(d, (i) => 'child_$i').join('/');

        await binding.traceAction(() async {
          final _ = rootObject.findChild(path);
        }, reportKey: 'lookup_path_$d');
      });
    }
  });
}

class LookupStressScene extends StatelessWidget {
  final int count;
  final GameTag rootTag;
  const LookupStressScene({super.key, required this.count, required this.rootTag});

  @override
  Widget build(BuildContext context) {
    return GameWidget(
      key: rootTag,
      name: 'root',
      children: [_buildWideTree(count)],
    );
  }

  // Use a wider tree to avoid hitting Flutter element depth limits while reaching high N
  Widget _buildWideTree(int total) {
    return GameWidget(
      name: 'container',
      children: List.generate(total, (i) => GameWidget(
        name: 'obj_$i',
        components: () => i % 100 == 0 ? [BoxCollider()] : [],
      )),
    );
  }
}

class PathStressScene extends StatelessWidget {
  final int depth;
  final GameTag rootTag;
  const PathStressScene({super.key, required this.depth, required this.rootTag});

  @override
  Widget build(BuildContext context) {
    return GameWidget(key: rootTag, name: 'root', children: [_buildPathIterative(depth)]);
  }

  Widget _buildPathIterative(int n) {
    Widget current = const SizedBox.shrink();
    for (int i = n - 1; i >= 0; i--) {
      current = GameWidget(name: 'child_$i', children: [current]);
    }
    return current;
  }
}
