import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:goo2d/goo2d.dart';

void main() {
  group('NormalizedPivot', () {
    test('center should compute (width/2, height/2)', () {
      const pivot = NormalizedPivot.center;
      const size = ui.Size(100, 200);
      expect(pivot.compute(size), const ui.Offset(50, 100));
    });

    test('topLeft should compute (0, 0)', () {
      const pivot = NormalizedPivot.topLeft;
      const size = ui.Size(100, 200);
      expect(pivot.compute(size), ui.Offset.zero);
    });

    test('bottomRight should compute (width, height)', () {
      const pivot = NormalizedPivot.bottomRight;
      const size = ui.Size(100, 200);
      expect(pivot.compute(size), const ui.Offset(100, 200));
    });

    test('custom normalized values should work', () {
      const pivot = NormalizedPivot(0.25, 0.75);
      const size = ui.Size(100, 100);
      expect(pivot.compute(size), const ui.Offset(25, 75));
    });
  });

  group('PixelPivot', () {
    test('should return absolute pixel values regardless of size', () {
      const pivot = PixelPivot(10, 20);
      expect(pivot.compute(const ui.Size(100, 100)), const ui.Offset(10, 20));
      expect(pivot.compute(const ui.Size(500, 500)), const ui.Offset(10, 20));
    });
  });
}
