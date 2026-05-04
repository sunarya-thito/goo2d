import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/src/physics/worker/engine/collision/aabb.dart';

void main() {
  group('AABB', () {
    test('basic construction', () {
      final aabb = AABB(1, 2, 3, 4);
      expect(aabb.minX, 1);
      expect(aabb.minY, 2);
      expect(aabb.maxX, 3);
      expect(aabb.maxY, 4);
    });

    test('width and height', () {
      final aabb = AABB(0, 0, 10, 5);
      expect(aabb.width, 10);
      expect(aabb.height, 5);
    });

    test('center and halfExtents', () {
      final aabb = AABB(-2, -3, 4, 5);
      expect(aabb.center.x, closeTo(1, 1e-10));
      expect(aabb.center.y, closeTo(1, 1e-10));
      expect(aabb.halfExtents.x, closeTo(3, 1e-10));
      expect(aabb.halfExtents.y, closeTo(4, 1e-10));
    });

    group('overlaps', () {
      test('returns true for overlapping AABBs', () {
        final a = AABB(0, 0, 10, 10);
        final b = AABB(5, 5, 15, 15);
        expect(a.overlaps(b), isTrue);
        expect(b.overlaps(a), isTrue);
      });

      test('returns true for touching edges', () {
        final a = AABB(0, 0, 10, 10);
        final b = AABB(10, 0, 20, 10);
        expect(a.overlaps(b), isTrue);
      });

      test('returns false for separated AABBs', () {
        final a = AABB(0, 0, 5, 5);
        final b = AABB(6, 6, 10, 10);
        expect(a.overlaps(b), isFalse);
      });

      test('returns false for separated on X only', () {
        final a = AABB(0, 0, 5, 10);
        final b = AABB(6, 0, 10, 10);
        expect(a.overlaps(b), isFalse);
      });

      test('returns false for separated on Y only', () {
        final a = AABB(0, 0, 10, 5);
        final b = AABB(0, 6, 10, 10);
        expect(a.overlaps(b), isFalse);
      });

      test('one inside another returns true', () {
        final outer = AABB(0, 0, 100, 100);
        final inner = AABB(40, 40, 60, 60);
        expect(outer.overlaps(inner), isTrue);
        expect(inner.overlaps(outer), isTrue);
      });
    });

    group('containsPoint', () {
      test('point inside', () {
        final aabb = AABB(0, 0, 10, 10);
        expect(aabb.containsPoint(Vector2(5, 5)), isTrue);
      });

      test('point on edge', () {
        final aabb = AABB(0, 0, 10, 10);
        expect(aabb.containsPoint(Vector2(0, 5)), isTrue);
        expect(aabb.containsPoint(Vector2(10, 5)), isTrue);
      });

      test('point outside', () {
        final aabb = AABB(0, 0, 10, 10);
        expect(aabb.containsPoint(Vector2(11, 5)), isFalse);
        expect(aabb.containsPoint(Vector2(-1, 5)), isFalse);
      });
    });

    group('encapsulate', () {
      test('grows to include point outside', () {
        final aabb = AABB(0, 0, 10, 10);
        aabb.encapsulate(15, 20);
        expect(aabb.maxX, 15);
        expect(aabb.maxY, 20);
      });

      test('shrinks nothing for point inside', () {
        final aabb = AABB(0, 0, 10, 10);
        aabb.encapsulate(5, 5);
        expect(aabb.minX, 0);
        expect(aabb.maxX, 10);
      });

      test('grows negative direction', () {
        final aabb = AABB(0, 0, 10, 10);
        aabb.encapsulate(-5, -3);
        expect(aabb.minX, -5);
        expect(aabb.minY, -3);
      });
    });

    group('expand', () {
      test('uniform expansion', () {
        final aabb = AABB(5, 5, 10, 10);
        aabb.expand(2);
        expect(aabb.minX, 3);
        expect(aabb.minY, 3);
        expect(aabb.maxX, 12);
        expect(aabb.maxY, 12);
      });
    });

    group('merge', () {
      test('merges two overlapping AABBs', () {
        final a = AABB(0, 0, 10, 10);
        final b = AABB(5, 5, 20, 15);
        a.merge(b);
        expect(a.minX, 0);
        expect(a.minY, 0);
        expect(a.maxX, 20);
        expect(a.maxY, 15);
      });
    });

    group('raycast', () {
      test('horizontal ray hits AABB', () {
        final aabb = AABB(5, -1, 10, 1);
        final t = aabb.raycast(Vector2(0, 0), Vector2(1, 0), 100);
        expect(t, closeTo(5, 1e-6));
      });

      test('ray from inside starts at 0', () {
        final aabb = AABB(-5, -5, 5, 5);
        final t = aabb.raycast(Vector2(0, 0), Vector2(1, 0), 100);
        expect(t, closeTo(0, 1e-6));
      });

      test('ray misses AABB', () {
        final aabb = AABB(5, 5, 10, 10);
        final t = aabb.raycast(Vector2(0, 0), Vector2(1, 0), 100);
        expect(t, -1);
      });

      test('ray past maxFraction misses', () {
        final aabb = AABB(100, -1, 110, 1);
        final t = aabb.raycast(Vector2(0, 0), Vector2(1, 0), 10);
        expect(t, -1);
      });

      test('diagonal ray hits AABB', () {
        final aabb = AABB(4, 4, 6, 6);
        final dir = Vector2(1, 1)..normalize();
        final t = aabb.raycast(Vector2(0, 0), dir, 100);
        expect(t, greaterThanOrEqualTo(0));
        final hitPoint = Vector2(0, 0) + dir * t;
        expect(hitPoint.x, closeTo(4, 0.01));
        expect(hitPoint.y, closeTo(4, 0.01));
      });
    });
  });
}
