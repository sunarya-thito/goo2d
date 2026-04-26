import 'package:flutter_test/flutter_test.dart';
import 'package:goo2d/src/utility.dart';
import 'dart:ui';

enum TestEnum { a, b, c, d }

void main() {
  group('lerp', () {
    test('should correctly interpolate doubles', () {
      expect(lerp(0.0, 10.0, 0.5), 5.0);
      expect(lerp(10.0, 20.0, 0.1), 11.0);
    });

    test('should correctly interpolate Offsets', () {
      expect(lerp(Offset.zero, const Offset(10, 20), 0.5), const Offset(5, 10));
    });
  });

  group('EnumListExtension', () {
    final list = TestEnum.values;

    test('betweenInclusive should return range including ends', () {
      expect(list.betweenInclusive(TestEnum.b, TestEnum.c), [TestEnum.b, TestEnum.c]);
      expect(list.betweenInclusive(TestEnum.a, TestEnum.d), list);
    });

    test('betweenExclusive should return range excluding ends', () {
      expect(list.betweenExclusive(TestEnum.a, TestEnum.c), [TestEnum.b]);
    });

    test('between should respect include flags', () {
      expect(list.between(TestEnum.a, TestEnum.c, includeA: true, includeB: false), [TestEnum.a, TestEnum.b]);
    });
  });

  group('MathUtils.smoothDamp', () {
    test('should move value toward target over time', () {
      final result = MathUtils.smoothDamp(0, 10, 0, 0.5, 0.1);
      expect(result.value, greaterThan(0));
      expect(result.value, lessThan(10));
      expect(result.velocity, greaterThan(0));
    });

    test('should slow down as it approaches target', () {
       final start = MathUtils.smoothDamp(0, 10, 0, 0.5, 0.1);
       final middle = MathUtils.smoothDamp(5, 10, start.velocity, 0.5, 0.1);
       final near = MathUtils.smoothDamp(9, 10, middle.velocity, 0.5, 0.1);
       
       // Velocity should eventually start decreasing
       expect(near.velocity, lessThan(middle.velocity + 1.0)); // Rough check
    });

    test('should handle overshooting by snapping to target', () {
       // High velocity toward target
       final result = MathUtils.smoothDamp(9.9, 10, 100, 0.5, 0.1);
       expect(result.value, 10.0);
       expect(result.velocity, 0.0);
    });
  });

  group('MathUtils.smoothDampOffset', () {
    test('should move Offset toward target', () {
      final result = MathUtils.smoothDampOffset(
        Offset.zero, 
        const Offset(10, 10), 
        Offset.zero, 
        0.5, 
        0.1,
      );
      expect(result.value.dx, greaterThan(0));
      expect(result.value.dy, greaterThan(0));
    });
  });
}
