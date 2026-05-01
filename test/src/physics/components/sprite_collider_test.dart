import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/painting.dart';
import 'package:goo2d/goo2d.dart';
import 'package:goo2d/src/asset.dart';

class MockTexture extends GameTexture {
  final int w;
  final int h;
  final Uint32List pixels;
  final ui.Image? dummyImage;

  MockTexture(this.w, this.h, this.pixels, {this.dummyImage}) : super(AssetSource.local('mock')) {
    if (dummyImage != null) {
      // We can't set _loadedImage directly as it's private in GameTexture
      // But we can override the getter if we change GameTexture
    }
  }

  @override
  int get width => w;
  @override
  int get height => h;
  @override
  bool get isLoaded => true;
  @override
  Future<void> load() async {}
  @override
  Uint32List getPixels32() => pixels;
  
  @override
  ui.Image get image => dummyImage!;
}

void main() {
  AutomatedTestWidgetsFlutterBinding.ensureInitialized();

  group('SpriteCollider', () {
    test('SpriteCollider generation from pixels', () async {
      // Create a 10x10 texture with a 4x4 solid box in the middle
      // AABBGGRR (Little Endian) -> 0xFF000000 for solid black
      final pixels = Uint32List(10 * 10);
      for (int y = 3; y < 7; y++) {
        for (int x = 3; x < 7; x++) {
          pixels[y * 10 + x] = 0xFF000000;
        }
      }

      final texture = MockTexture(10, 10, pixels);
      final sprite = GameSprite(
        texture: texture,
        rect: const Rect.fromLTWH(0, 0, 10, 10),
        pixelsPerUnit: 1.0,
      );

      final vertices = await SpriteCollider.bake(
        sprite,
        alphaThreshold: 0.1,
        tolerance: 0.1,
      );

      // The tracer should find the 4 corners of the 4x4 box.
      // Box is from (3,3) to (6,6) (inclusive of pixels).
      // So vertices should be around (3,3), (6,3), (6,6), (3,6).
      expect(vertices.length, 4);
      
      // Pivot is at center (5,5) for a 10x10 sprite.
      // Offset from pivot: (3-5, 3-5) = (-2, -2)
      expect(vertices, contains(const Offset(-2, -2)));
      expect(vertices, contains(const Offset(1, -2))); // (6-5, 3-5) = (1, -2)
      expect(vertices, contains(const Offset(1, 1)));  // (6-5, 6-5) = (1, 1)
      expect(vertices, contains(const Offset(-2, 1))); // (3-5, 6-5) = (-2, 1)
    });

    testWidgets('SpriteCollider automatic generation', (tester) async {
      final ui.Image dummyImage = await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        ui.Canvas(recorder).drawPoints(ui.PointMode.points, [Offset.zero], Paint());
        return recorder.endRecording().toImage(1, 1);
      }) as ui.Image;

      final pixels = Uint32List(10 * 10);
      for (int y = 3; y < 7; y++) {
        for (int x = 3; x < 7; x++) {
          pixels[y * 10 + x] = 0xFF000000;
        }
      }
      final texture = MockTexture(10, 10, pixels, dummyImage: dummyImage);
      final sprite = GameSprite(texture: texture);
      
      final renderer = SpriteRenderer()..sprite = sprite;
      final collider = SpriteCollider()..autoGenerate = true;

      await tester.pumpWidget(
        Game(
          child: GameObjectWidget(
            children: [
              GameObjectWidget(
                children: [
                  ComponentWidget(() => ObjectTransform()),
                  ComponentWidget(() => renderer),
                  ComponentWidget(() => collider),
                ],
              ),
            ],
          ),
        ),
      );

      // Wait for the async generation to complete
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
      
      expect(collider.vertices, isNotEmpty);
      expect(collider.vertices.length, 4);
    });
  });
}
