import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goo2d/goo2d.dart';

class FakeCanvas extends Fake implements ui.Canvas {
  ui.Rect? lastSrc;
  ui.Rect? lastDst;
  ui.Paint? lastPaint;

  @override
  void drawImageRect(ui.Image image, ui.Rect src, ui.Rect dst, ui.Paint paint) {
    lastSrc = src;
    lastDst = dst;
    lastPaint = paint;
  }

  @override
  void drawRect(ui.Rect rect, ui.Paint paint) {
    lastDst = rect;
    lastPaint = paint;
  }

  @override
  void save() {}
  @override
  void restore() {}
}

Future<ui.Image> createTestImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawColor(const ui.Color(0xFFFF0000), ui.BlendMode.src);
  final picture = recorder.endRecording();
  return await picture.toImage(10, 10);
}

void main() {
  group('SpriteFit', () {
    late ui.Image image;
    final canvas = FakeCanvas();
    final paint = ui.Paint();

    setUpAll(() async {
      image = await createTestImage();
    });

    testWidgets('StretchFit should draw exactly from src to dst', (tester) async {
      const fit = StretchFit();
      const src = ui.Rect.fromLTWH(0, 0, 10, 10);
      const dst = ui.Rect.fromLTWH(0, 0, 100, 100);
      fit.draw(canvas, image, src, dst, paint);
      expect(canvas.lastSrc, src);
      expect(canvas.lastDst, dst);
    });

    testWidgets('FixedFit should respect alignment (topLeft)', (tester) async {
      const fit = FixedFit(alignment: Alignment.topLeft);
      const src = ui.Rect.fromLTWH(0, 0, 50, 50);
      const dst = ui.Rect.fromLTWH(0, 0, 100, 100);
      
      fit.draw(canvas, image, src, dst, paint);
      
      expect(canvas.lastSrc, src);
      // TopLeft of 50x50 in 100x100 is LTWH(0, 0, 50, 50)
      expect(canvas.lastDst, const ui.Rect.fromLTWH(0, 0, 50, 50));
    });

    testWidgets('CoverFit should scale and crop to fill destination', (tester) async {
      const fit = CoverFit();
      const src = ui.Rect.fromLTWH(0, 0, 200, 100);
      const dst = ui.Rect.fromLTWH(0, 0, 100, 100);
      fit.draw(canvas, image, src, dst, paint);
      expect(canvas.lastSrc, const ui.Rect.fromLTWH(50, 0, 100, 100));
      expect(canvas.lastDst, const ui.Rect.fromLTWH(0, 0, 100, 100));
    });

    testWidgets('ContainFit should respect alignment (bottomRight)', (tester) async {
      const fit = ContainFit(alignment: Alignment.bottomRight);
      const src = ui.Rect.fromLTWH(0, 0, 200, 100); // 2:1
      const dst = ui.Rect.fromLTWH(0, 0, 100, 100); // 1:1
      
      fit.draw(canvas, image, src, dst, paint);
      
      // For BoxFit.contain (2:1 src into 1:1 dst):
      // Destination is 100x50. With bottomRight, it should be at (0, 50, 100, 50)
      expect(canvas.lastSrc, src);
      expect(canvas.lastDst, const ui.Rect.fromLTWH(0, 50, 100, 50));
    });

    test('TileFit should compute correct transformation matrix', () {
      // Source is 32x32 at origin. Destination is 128x128 at origin.
      // Scaling should be 4x.
      const src = ui.Rect.fromLTWH(0, 0, 32, 32);
      const dst = ui.Rect.fromLTWH(0, 0, 128, 128);
      
      final matrix = TileFit.computeMatrix(src, dst);
      
      // Check scale (index 0 and 5 in column-major Matrix4)
      expect(matrix.storage[0], 4.0);
      expect(matrix.storage[5], 4.0);
      // Check translation (index 12 and 13)
      expect(matrix.storage[12], 0.0);
      expect(matrix.storage[13], 0.0);
    });

    test('TileFit should handle offset source and destination', () {
      const src = ui.Rect.fromLTWH(10, 10, 10, 10);
      const dst = ui.Rect.fromLTWH(100, 100, 100, 100);
      
      final matrix = TileFit.computeMatrix(src, dst);
      
      // Scale is 10x
      expect(matrix.storage[0], 10.0);
      expect(matrix.storage[5], 10.0);
      // Translation logic: dst.left - src.left * sx = 100 - 10 * 10 = 0
      expect(matrix.storage[12], 0.0);
      expect(matrix.storage[13], 0.0);
    });
  });
}
