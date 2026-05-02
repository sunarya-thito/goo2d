import 'package:flutter_test/flutter_test.dart';
import 'package:goo2d/goo2d.dart';

void main() {
  AutomatedTestWidgetsFlutterBinding.ensureInitialized();

  group('Joint Components', () {
    testWidgets('DistanceJoint registration', (tester) async {
      final rb1 = Rigidbody();
      final rb2 = Rigidbody();
      final joint = DistanceJoint()
        ..connectedBody = rb2
        ..distance = 50.0;
      
      await tester.pumpWidget(
        Game(
          child: GameObjectWidget(
            children: [
              GameObjectWidget(
                name: 'Obj1',
                children: [
                  ComponentWidget(() => ObjectTransform()),
                  ComponentWidget(() => rb1),
                  ComponentWidget(() => joint),
                ],
              ),
              GameObjectWidget(
                name: 'Obj2',
                children: [
                  ComponentWidget(() => ObjectTransform()),
                  ComponentWidget(() => rb2),
                ],
              ),
            ],
          ),
        ),
      );

      final engine = GameEngine.of(tester.element(find.byType(GameObjectWidget).first));
      expect(engine.physics?.activeJoints, contains(joint));
    });

    testWidgets('HingeJoint registration', (tester) async {
      final rb1 = Rigidbody();
      final joint = HingeJoint()
        ..anchor = const Offset(10, 10);
      
      await tester.pumpWidget(
        Game(
          child: GameObjectWidget(
            children: [
              GameObjectWidget(
                children: [
                  ComponentWidget(() => ObjectTransform()),
                  ComponentWidget(() => rb1),
                  ComponentWidget(() => joint),
                ],
              ),
            ],
          ),
        ),
      );

      final engine = GameEngine.of(tester.element(find.byType(GameObjectWidget).first));
      expect(engine.physics?.activeJoints, contains(joint));
    });
  });
}
