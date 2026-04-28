import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:goo2d/goo2d.dart';

void main() {
  if (!const bool.fromEnvironment('INTEGRATION_TEST')) {
    return;
  }
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Goo2D Physics Scaling Benchmarks (Extreme)', () {
    final vertexCounts = [4, 16, 64, 256, 512, 1024];
    
    for (final v in vertexCounts) {
      testWidgets('Physics.worldBounds (Vertices $v)', (tester) async {
        final polyTag = GameTag('poly_$v');
        await tester.pumpWidget(MaterialApp(
          home: Game(child: PhysicsStressScene(vertexCount: v, polyTag: polyTag)),
        ));
        await tester.pump();

        final polyObject = polyTag.gameObject!;
        final collider = polyObject.getComponent<PolygonCollider>();

        await binding.traceAction(() async {
          final _ = collider.worldBounds;
        }, reportKey: 'physics_bounds_$v');
      });

      testWidgets('Physics.containsPoint (Vertices $v)', (tester) async {
        final polyTag = GameTag('poly_$v');
        await tester.pumpWidget(MaterialApp(
          home: Game(child: PhysicsStressScene(vertexCount: v, polyTag: polyTag)),
        ));
        await tester.pump();

        final polyObject = polyTag.gameObject!;
        final collider = polyObject.getComponent<PolygonCollider>();
        const testPoint = Offset(50, 50);

        await binding.traceAction(() async {
          final _ = collider.containsPoint(testPoint);
        }, reportKey: 'physics_hit_$v');
      });
    }
  });
}

class PhysicsStressScene extends StatelessWidget {
  final int vertexCount;
  final GameTag polyTag;
  const PhysicsStressScene({super.key, required this.vertexCount, required this.polyTag});

  @override
  Widget build(BuildContext context) {
    final vertices = List.generate(vertexCount, (i) {
      final angle = i * (2 * 3.14159 / vertexCount);
      final r = i % 2 == 0 ? 100.0 : 50.0;
      return Offset(r * (i.isEven ? 1 : -1), r * (i.isOdd ? 1 : -1));
    });

    return GameWidget(
      key: polyTag,
      name: 'poly',
      components: () => [
        ObjectTransform(),
        PolygonCollider()..vertices = vertices,
      ],
    );
  }
}
