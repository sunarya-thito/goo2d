import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/src/physics/worker/engine/collision/ray_intersect.dart';

void main() {
  group('rayVsCircle', () {
    test('direct hit on circle center', () {
      final hit = rayVsCircle(
        Vector2(0, 0), Vector2(1, 0), 100,
        Vector2(5, 0), 1,
      );
      expect(hit, isNotNull);
      expect(hit!.fraction, closeTo(4, 1e-6));
      expect(hit.point.x, closeTo(4, 1e-6));
      expect(hit.point.y, closeTo(0, 1e-6));
      expect(hit.normal.x, closeTo(-1, 1e-6));
    });

    test('miss above circle', () {
      final hit = rayVsCircle(
        Vector2(0, 5), Vector2(1, 0), 100,
        Vector2(5, 0), 1,
      );
      expect(hit, isNull);
    });

    test('tangent hit on circle', () {
      final hit = rayVsCircle(
        Vector2(0, 1), Vector2(1, 0), 100,
        Vector2(5, 0), 1,
      );
      // Tangent → just barely touches
      expect(hit, isNotNull);
      expect(hit!.fraction, closeTo(5, 0.1));
    });

    test('ray origin inside circle', () {
      final hit = rayVsCircle(
        Vector2(5, 0), Vector2(1, 0), 100,
        Vector2(5, 0), 2,
      );
      expect(hit, isNotNull);
      // Should hit the exit point
      expect(hit!.point.x, closeTo(7, 1e-6));
    });

    test('beyond maxFraction returns null', () {
      final hit = rayVsCircle(
        Vector2(0, 0), Vector2(1, 0), 3,
        Vector2(5, 0), 1,
      );
      expect(hit, isNull);
    });

    test('vertical ray hits circle', () {
      final hit = rayVsCircle(
        Vector2(0, -10), Vector2(0, 1), 100,
        Vector2(0, 0), 2,
      );
      expect(hit, isNotNull);
      expect(hit!.point.y, closeTo(-2, 1e-6));
    });
  });

  group('rayVsSegment', () {
    test('ray crosses segment', () {
      final hit = rayVsSegment(
        Vector2(0, 0), Vector2(1, 0), 100,
        Vector2(5, -5), Vector2(5, 5),
      );
      expect(hit, isNotNull);
      expect(hit!.fraction, closeTo(5, 1e-6));
      expect(hit.point.x, closeTo(5, 1e-6));
    });

    test('parallel ray misses', () {
      final hit = rayVsSegment(
        Vector2(0, 0), Vector2(1, 0), 100,
        Vector2(0, 5), Vector2(10, 5),
      );
      expect(hit, isNull);
    });

    test('ray going away from segment misses', () {
      final hit = rayVsSegment(
        Vector2(0, 0), Vector2(-1, 0), 100,
        Vector2(5, -5), Vector2(5, 5),
      );
      expect(hit, isNull);
    });

    test('beyond segment endpoints misses', () {
      final hit = rayVsSegment(
        Vector2(0, 10), Vector2(1, 0), 100,
        Vector2(5, -5), Vector2(5, 5),
      );
      expect(hit, isNull);
    });

    test('normal faces toward ray origin', () {
      final hit = rayVsSegment(
        Vector2(0, 0), Vector2(1, 0), 100,
        Vector2(5, -5), Vector2(5, 5),
      );
      expect(hit, isNotNull);
      expect(hit!.normal.dot(Vector2(1, 0)), lessThan(0));
    });
  });

  group('rayVsBox', () {
    test('axis-aligned box, horizontal ray', () {
      final hit = rayVsBox(
        Vector2(0, 0), Vector2(1, 0), 100,
        Vector2(10, 0), Vector2(2, 2), 0,
      );
      expect(hit, isNotNull);
      expect(hit!.point.x, closeTo(8, 1e-6));
    });

    test('rotated box 45 degrees', () {
      final hit = rayVsBox(
        Vector2(0, 0), Vector2(1, 0), 100,
        Vector2(10, 0), Vector2(2, 2), math.pi / 4,
      );
      expect(hit, isNotNull);
      // Rotated diamond shape — hit point should be before center
      expect(hit!.point.x, lessThan(10));
      expect(hit.fraction, greaterThan(0));
    });

    test('miss above box', () {
      final hit = rayVsBox(
        Vector2(0, 10), Vector2(1, 0), 100,
        Vector2(10, 0), Vector2(2, 2), 0,
      );
      expect(hit, isNull);
    });

    test('beyond maxFraction', () {
      final hit = rayVsBox(
        Vector2(0, 0), Vector2(1, 0), 5,
        Vector2(10, 0), Vector2(2, 2), 0,
      );
      expect(hit, isNull);
    });
  });

  group('rayVsPolygon', () {
    test('ray hits triangle', () {
      final verts = [
        Vector2(0, -2),
        Vector2(2, 2),
        Vector2(-2, 2),
      ];
      final hit = rayVsPolygon(
        Vector2(-10, 0), Vector2(1, 0), 100,
        Vector2(0, 0), verts, 0,
      );
      expect(hit, isNotNull);
      expect(hit!.fraction, greaterThan(0));
    });

    test('ray misses polygon', () {
      final verts = [
        Vector2(0, -2),
        Vector2(2, 2),
        Vector2(-2, 2),
      ];
      final hit = rayVsPolygon(
        Vector2(-10, 10), Vector2(1, 0), 100,
        Vector2(0, 0), verts, 0,
      );
      expect(hit, isNull);
    });
  });

  group('rayVsCapsule', () {
    test('ray hits vertical capsule', () {
      final hit = rayVsCapsule(
        Vector2(-10, 0), Vector2(1, 0), 100,
        Vector2(0, 0), Vector2(2, 4), 0, 0,
      );
      expect(hit, isNotNull);
      expect(hit!.point.x, lessThan(0));
    });

    test('ray misses capsule', () {
      final hit = rayVsCapsule(
        Vector2(-10, 20), Vector2(1, 0), 100,
        Vector2(0, 0), Vector2(2, 4), 0, 0,
      );
      expect(hit, isNull);
    });
  });
}
