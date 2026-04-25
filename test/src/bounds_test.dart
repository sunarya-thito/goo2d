import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goo2d/goo2d.dart';

void main() {
  group('ObjectSize', () {
    test('should store size', () {
      final sizeComp = ObjectSize()..size = const Size(100, 200);
      expect(sizeComp.size.width, equals(100));
      expect(sizeComp.size.height, equals(200));
    });

    test('should default to infinite size', () {
      final sizeComp = ObjectSize();
      expect(sizeComp.size, equals(Size.infinite));
    });
  });
}
