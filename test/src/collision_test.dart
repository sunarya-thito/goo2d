import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goo2d/goo2d.dart';

class MockCollidable extends Component with Collidable {
  int collisionCount = 0;
  CollisionTrigger? lastOther;

  @override
  void onCollision(CollisionEvent collision) {
    collisionCount++;
    lastOther = collision.other;
  }
}

void main() {
  AutomatedTestWidgetsFlutterBinding.ensureInitialized();

  group('Collision', () {
    testWidgets('should detect collision between overlapping BoxColliders', (tester) async {
      final comp1 = MockCollidable();
      final box1 = BoxCollisionTrigger()..rect = const Rect.fromLTWH(0, 0, 100, 100);
      
      final comp2 = MockCollidable();
      final box2 = BoxCollisionTrigger()..rect = const Rect.fromLTWH(50, 50, 100, 100);

      await tester.pumpWidget(
        Game(
          child: GameWidget(
            children: [
              GameWidget(components: () => [comp1, box1, ObjectTransform()]),
              GameWidget(components: () => [comp2, box2, ObjectTransform()]),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(comp1.collisionCount, equals(1));
      expect(comp1.lastOther, equals(box2));
    });

    testWidgets('should respect layer masks', (tester) async {
      final comp1 = MockCollidable();
      final box1 = BoxCollisionTrigger()
        ..rect = const Rect.fromLTWH(0, 0, 100, 100)
        ..layerMask = 0x1;

      final comp2 = MockCollidable();
      final box2 = BoxCollisionTrigger()
        ..rect = const Rect.fromLTWH(50, 50, 100, 100)
        ..layerMask = 0x2; // No overlap with 0x1

      await tester.pumpWidget(
        Game(
          child: GameWidget(
            children: [
              GameWidget(components: () => [comp1, box1, ObjectTransform()]),
              GameWidget(components: () => [comp2, box2, ObjectTransform()]),
            ],
          ),
        ),
      );
      await tester.pump();


      expect(comp1.collisionCount, equals(0));
    });

    testWidgets('should detect collisions with world-space transforms', (tester) async {
      final comp1 = MockCollidable();
      final box1 = BoxCollisionTrigger()..rect = const Rect.fromLTWH(0, 0, 100, 100);
      final trans1 = ObjectTransform(); 
      
      final comp2 = MockCollidable();
      final box2 = BoxCollisionTrigger()..rect = const Rect.fromLTWH(0, 0, 100, 100);
      final trans2 = ObjectTransform()..localPosition = const Offset(150, 0); // No overlap initially

      await tester.pumpWidget(
        Game(
          child: GameWidget(
            children: [
              GameWidget(components: () => [comp1, box1, trans1]),
              GameWidget(components: () => [comp2, box2, trans2]),
            ],
          ),
        ),
      );
      await tester.pump();
      expect(comp1.collisionCount, equals(0));

      // Move trans2 to overlap
      trans2.localPosition = const Offset(50, 0);
      await tester.pump();
      expect(comp1.collisionCount, equals(1));
    });

    testWidgets('OvalCollisionTrigger should collide based on ellipse, not just AABB', (tester) async {
      final comp1 = MockCollidable();
      final oval1 = OvalCollisionTrigger()
        ..radiusX = 50
        ..radiusY = 50
        ..center = Offset.zero; // AABB: (-50, -50, 100, 100)

      final comp2 = MockCollidable();
      final oval2 = OvalCollisionTrigger()
        ..radiusX = 50
        ..radiusY = 50
        ..center = const Offset(80, 80); // AABB: (30, 30, 100, 100). 

      await tester.pumpWidget(
        Game(
          child: GameWidget(
            children: [
              GameWidget(components: () => [comp1, oval1, ObjectTransform()]),
              GameWidget(components: () => [comp2, oval2, ObjectTransform()]),
            ],
          ),
        ),
      );
      await tester.pump();


      expect(comp1.collisionCount, equals(0));
    });
  });
}
