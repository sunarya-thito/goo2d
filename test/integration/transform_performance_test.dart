import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:goo2d/goo2d.dart';

void main() {
  if (!const bool.fromEnvironment('INTEGRATION_TEST')) {
    return;
  }
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Goo2D Transform Scaling Benchmarks (Profiler)', () {
    final depths = [5, 10, 25, 50, 75, 100, 125, 150]; 
    for (final d in depths) {
      testWidgets('Transform.worldMatrixDeep (Depth $d)', (tester) async {
        final rootTag = GameTag('root_obj_$d');
        final leafTag = GameTag('leaf_obj_$d');
        
        await tester.pumpWidget(MaterialApp(
          home: Game(child: WorldMatrixStressScene(depth: d, rootTag: rootTag, leafTag: leafTag)),
        ));
        await tester.pump();

        final rootObject = rootTag.gameObject!;
        final leafObject = leafTag.gameObject!;
        final rootTransform = rootObject.getComponent<ObjectTransform>();
        final leafTransform = leafObject.getComponent<ObjectTransform>();

        await binding.traceAction(() async {
          rootTransform.localPosition = Offset(rootTransform.localPosition.dx + 0.1, 0);
          final _ = leafTransform.worldMatrix;
        }, reportKey: 'transform_depth_$d');
      });
    }
  });
}

class WorldMatrixStressScene extends StatelessWidget {
  final int depth;
  final GameTag rootTag;
  final GameTag leafTag;
  const WorldMatrixStressScene({super.key, required this.depth, required this.rootTag, required this.leafTag});

  @override
  Widget build(BuildContext context) {
    return _buildDepth(depth, 0);
  }

  Widget _buildDepth(int max, int current) {
    final bool isRoot = current == 0;
    final bool isLeaf = current == max;
    return GameWidget(
      key: isRoot ? rootTag : (isLeaf ? leafTag : null),
      name: isRoot ? 'root' : (isLeaf ? 'leaf' : 'd_$current'),
      components: () => [ObjectTransform()],
      children: [if (!isLeaf) _buildDepth(max, current + 1)],
    );
  }
}
