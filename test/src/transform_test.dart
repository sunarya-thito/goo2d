import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goo2d/goo2d.dart';
import 'package:goo2d/src/component.dart';

void main() {
  AutomatedTestWidgetsFlutterBinding.ensureInitialized();

  group('ObjectTransform', () {
    testWidgets('should have identity matrix by default', (tester) async {
      final transform = internalCreateComponent(ObjectTransform.new) as ObjectTransform;
      await tester.pumpWidget(
        Game(child: GameWidget(components: [() => transform])),
      );
      await tester.pump();

      expect(transform.localMatrix, equals(Matrix4.identity()));
      expect(transform.worldMatrix, equals(Matrix4.identity()));
      expect(transform.localPosition, equals(Offset.zero));
      expect(transform.localAngle, equals(0.0));
      expect(transform.localScale, equals(const Offset(1, 1)));
    });

    testWidgets(
      'should calculate localMatrix correctly when properties are set',
      (tester) async {
        final transform = internalCreateComponent(ObjectTransform.new) as ObjectTransform;
        await tester.pumpWidget(
          Game(child: GameWidget(components: [() => transform])),
        );
        await tester.pump();

        transform.localPosition = const Offset(10, 20);
        transform.localAngle = math.pi / 2; // 90 degrees
        transform.localScale = const Offset(2, 3);

        final expected = Matrix4.identity()
          ..translateByDouble(10.0, 20.0, 0.0, 1.0)
          ..rotateZ(math.pi / 2)
          ..scaleByDouble(2.0, 3.0, 1.0, 1.0);

        // Compare matrix elements roughly for precision
        for (int i = 0; i < 16; i++) {
          expect(
            transform.localMatrix.storage[i],
            closeTo(expected.storage[i], 0.0001),
          );
        }
      },
    );

    testWidgets('should propagate worldMatrix through hierarchy', (
      tester,
    ) async {
      final parentTransform = internalCreateComponent(ObjectTransform.new) as ObjectTransform;
      final childTransform = internalCreateComponent(ObjectTransform.new) as ObjectTransform;

      await tester.pumpWidget(
        Game(
          child: GameWidget(
            components: [() => parentTransform],
            children: [
              GameWidget(components: [() => childTransform]),
            ],
          ),
        ),
      );
      await tester.pump();

      parentTransform.localPosition = const Offset(100, 100);
      childTransform.localPosition = const Offset(50, 50);

      expect(parentTransform.worldMatrix.getTranslation().x, equals(100));
      expect(parentTransform.worldMatrix.getTranslation().y, equals(100));

      // Child world position should be parent (100,100) + child local (50,50) = (150,150)
      expect(childTransform.worldMatrix.getTranslation().x, equals(150));
      expect(childTransform.worldMatrix.getTranslation().y, equals(150));
      expect(childTransform.position, equals(const Offset(150, 150)));
    });

    testWidgets('should increment version and dirty cache on change', (
      tester,
    ) async {
      final parentTransform = internalCreateComponent(ObjectTransform.new) as ObjectTransform;
      final childTransform = internalCreateComponent(ObjectTransform.new) as ObjectTransform;

      await tester.pumpWidget(
        Game(
          child: GameWidget(
            components: [() => parentTransform],
            children: [
              GameWidget(components: [() => childTransform]),
            ],
          ),
        ),
      );
      await tester.pump();

      final initialParentVersion = parentTransform.version;
      final initialChildVersion = childTransform.version;

      // Access worldMatrix to cache it
      var _ = childTransform.worldMatrix;

      parentTransform.localPosition = const Offset(1, 1);

      expect(parentTransform.version, greaterThan(initialParentVersion));
      expect(childTransform.version, greaterThan(initialChildVersion));

      // World position should update
      expect(childTransform.position, equals(const Offset(1, 1)));
    });

    testWidgets('should handle deep nesting (10 levels)', (tester) async {
      final transforms = List.generate(10, (_) => internalCreateComponent(ObjectTransform.new) as ObjectTransform);

      Widget buildHierarchy(int index) {
        if (index >= transforms.length) return const SizedBox();
        return GameWidget(
          components: [() => transforms[index]],
          children: [buildHierarchy(index + 1)],
        );
      }

      await tester.pumpWidget(Game(child: buildHierarchy(0)));
      await tester.pump();

      for (var t in transforms) {
        t.localPosition = const Offset(10, 0);
      }

      // 10 levels of (10, 0) should result in (100, 0) world position for the last child
      expect(transforms.last.position.dx, closeTo(100.0, 0.0001));
    });
    testWidgets('should correctly convert localToWorld and worldToLocal', (
      tester,
    ) async {
      final transform = internalCreateComponent(ObjectTransform.new) as ObjectTransform;
      await tester.pumpWidget(
        Game(child: GameWidget(components: [() => transform])),
      );
      await tester.pump();

      transform.localPosition = const Offset(100, 100);
      transform.localAngle = math.pi / 4; // 45 degrees

      final localPoint = const Offset(10, 10);
      final worldPoint = transform.localToWorld(localPoint);

      // Revert back
      final convertedBack = transform.worldToLocal(worldPoint);
      expect(convertedBack.dx, closeTo(localPoint.dx, 0.0001));
      expect(convertedBack.dy, closeTo(localPoint.dy, 0.0001));
    });

    testWidgets('should set world-space position correctly with parent', (
      tester,
    ) async {
      final parentTransform = internalCreateComponent(ObjectTransform.new) as ObjectTransform;
      final childTransform = internalCreateComponent(ObjectTransform.new) as ObjectTransform;

      await tester.pumpWidget(
        Game(
          child: GameWidget(
            components: [() => parentTransform],
            children: [
              GameWidget(components: [() => childTransform]),
            ],
          ),
        ),
      );
      await tester.pump();

      parentTransform.localPosition = const Offset(100, 100);
      parentTransform.localAngle = math.pi / 2; // Parent rotated 90 deg

      // We want the child to be at world position (100, 200)
      childTransform.position = const Offset(100, 200);

      expect(childTransform.position.dx, closeTo(100.0, 0.0001));
      expect(childTransform.position.dy, closeTo(200.0, 0.0001));

      // In parent space (rotated 90 deg), (100, 200) relative to (100, 100)
      // Vector (0, 100) in world.
      // Parent's X axis is (0, 1) in world. Parent's Y axis is (-1, 0) in world.
      // So world vector (0, 100) is 100 units along parent's X axis.
      // localPosition should be (100, 0).
      expect(childTransform.localPosition.dx, closeTo(100.0, 0.0001));
      expect(childTransform.localPosition.dy, closeTo(0.0, 0.0001));
    });
  });
}
