import 'package:flutter_test/flutter_test.dart';
import 'package:goo2d/src/physics/worker/engine/collision/contact_tracker.dart';
import 'package:goo2d/src/physics/worker/engine/collision/narrowphase.dart';
import 'package:goo2d/src/physics/worker/engine/collision/shape_intersect.dart';
import 'package:vector_math/vector_math_64.dart';

NarrowphaseContact _contact(int cA, int cB, int bA, int bB) {
  return NarrowphaseContact(
    colliderA: cA,
    colliderB: cB,
    bodyA: bA,
    bodyB: bB,
    manifold: ContactManifold(Vector2(1, 0), [ContactVertex(Vector2.zero(), 0.1)]),
  );
}

void main() {
  late ContactTracker tracker;

  setUp(() {
    tracker = ContactTracker();
  });

  group('collision events', () {
    test('first frame contact is enter', () {
      tracker.update([_contact(0, 1, 10, 11)], (_) => false);
      expect(tracker.enterEvents, hasLength(1));
      expect(tracker.stayEvents, isEmpty);
      expect(tracker.exitEvents, isEmpty);
    });

    test('sustained contact becomes stay', () {
      tracker.update([_contact(0, 1, 10, 11)], (_) => false);
      tracker.update([_contact(0, 1, 10, 11)], (_) => false);
      expect(tracker.enterEvents, isEmpty);
      expect(tracker.stayEvents, hasLength(1));
      expect(tracker.exitEvents, isEmpty);
    });

    test('removed contact becomes exit', () {
      tracker.update([_contact(0, 1, 10, 11)], (_) => false);
      tracker.update([], (_) => false);
      expect(tracker.enterEvents, isEmpty);
      expect(tracker.stayEvents, isEmpty);
      expect(tracker.exitEvents, hasLength(1));
    });

    test('exit event has correct collider IDs', () {
      tracker.update([_contact(5, 7, 10, 11)], (_) => false);
      tracker.update([], (_) => false);
      final exit = tracker.exitEvents[0];
      expect(exit.colliderA, 5);
      expect(exit.colliderB, 7);
    });

    test('multiple contacts tracked independently', () {
      tracker.update([
        _contact(0, 1, 10, 11),
        _contact(2, 3, 12, 13),
      ], (_) => false);
      expect(tracker.enterEvents, hasLength(2));

      // Keep one, remove one
      tracker.update([_contact(0, 1, 10, 11)], (_) => false);
      expect(tracker.stayEvents, hasLength(1));
      expect(tracker.exitEvents, hasLength(1));
      expect(tracker.exitEvents[0].colliderA, 2);
    });
  });

  group('trigger events', () {
    test('trigger contact fires triggerEnter', () {
      tracker.update([_contact(0, 1, 10, 11)], (h) => h == 0);
      expect(tracker.triggerEnterEvents, hasLength(1));
      expect(tracker.enterEvents, isEmpty);
    });

    test('sustained trigger becomes triggerStay', () {
      tracker.update([_contact(0, 1, 10, 11)], (h) => h == 0);
      tracker.update([_contact(0, 1, 10, 11)], (h) => h == 0);
      expect(tracker.triggerStayEvents, hasLength(1));
      expect(tracker.triggerEnterEvents, isEmpty);
    });

    test('removed trigger becomes triggerExit', () {
      tracker.update([_contact(0, 1, 10, 11)], (h) => h == 0);
      tracker.update([], (h) => h == 0);
      expect(tracker.triggerExitEvents, hasLength(1));
      expect(tracker.triggerStayEvents, isEmpty);
    });
  });

  group('pair normalization', () {
    test('contact(A,B) same as contact(B,A)', () {
      tracker.update([_contact(1, 0, 10, 11)], (_) => false);
      // Same pair reversed → should be stay, not new enter
      tracker.update([_contact(0, 1, 10, 11)], (_) => false);
      expect(tracker.stayEvents, hasLength(1));
      expect(tracker.enterEvents, isEmpty);
    });
  });

  group('empty frames', () {
    test('no contacts → no events', () {
      tracker.update([], (_) => false);
      expect(tracker.enterEvents, isEmpty);
      expect(tracker.stayEvents, isEmpty);
      expect(tracker.exitEvents, isEmpty);
      expect(tracker.triggerEnterEvents, isEmpty);
    });

    test('multiple empty frames are clean', () {
      tracker.update([], (_) => false);
      tracker.update([], (_) => false);
      tracker.update([], (_) => false);
      expect(tracker.exitEvents, isEmpty);
    });
  });
}
