import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:goo2d/src/physics/polygon_generator.dart';

void main() {
  group('SpritePolygonGenerator', () {
    test('should generate a square for a solid block of pixels', () {
      final width = 10;
      final height = 10;
      final pixels = Uint32List(width * height);
      
      // Fill a 4x4 square in the middle with solid alpha
      // In LE Uint32, alpha 0xFF is 0xFF000000 (if RGB are 0)
      for (int y = 3; y < 7; y++) {
        for (int x = 3; x < 7; x++) {
          pixels[y * width + x] = 0xFF000000;
        }
      }

      final vertices = SpritePolygonGenerator.generate(
        pixels: pixels,
        width: width,
        height: height,
        tolerance: 0.1, // Very low tolerance to see raw shape
      );

      // Moore-neighbor tracing on a 4x4 block should return the boundary pixels.
      // After simplification, it should be the 4 corners.
      expect(vertices.length, 4);
      
      // Corners of (3,3) to (6,6)
      expect(vertices, contains(const Offset(3, 3)));
      expect(vertices, contains(const Offset(6, 3)));
      expect(vertices, contains(const Offset(6, 6)));
      expect(vertices, contains(const Offset(3, 6)));
    });

    test('should respect alphaThreshold', () {
      final width = 10;
      final height = 10;
      final pixels = Uint32List(width * height);
      
      // Pixel with low alpha
      pixels[5 * width + 5] = 0x10000000; // Alpha = 16

      final vertices = SpritePolygonGenerator.generate(
        pixels: pixels,
        width: width,
        height: height,
        alphaThreshold: 0.2, // Requires alpha >= 51
      );

      expect(vertices, isEmpty);

      final vertices2 = SpritePolygonGenerator.generate(
        pixels: pixels,
        width: width,
        height: height,
        alphaThreshold: 0.05, // Requires alpha >= 12
      );

      expect(vertices2, isNotEmpty);
    });
  });
}
