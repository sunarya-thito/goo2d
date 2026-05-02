import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:goo2d/goo2d.dart';
import 'dart:typed_data';

class MockSource implements AssetSource {
  @override
  String get name => 'mock';
  @override
  Future<Uint8List> loadBytes() async => Uint8List(0);
}

class MockTexture extends GameTexture {
  final int _width;
  final int _height;

  @override
  int get width => _width;
  @override
  int get height => _height;

  MockTexture(this._width, this._height) : super(MockSource());

  @override
  Future<void> load() async {}

  @override
  void unload() {}

  @override
  ui.Image get image => throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final texture = MockTexture(256, 128);

  group('GameSprite', () {
    test('should have default rect of full texture when not specified', () {
      final s = GameSprite(texture: texture);
      expect(s.rect, const ui.Rect.fromLTWH(0, 0, 256, 128));
    });

    test('should calculate bounds correctly based on PPU', () {
      final sprite = GameSprite(
        texture: texture,
        rect: const ui.Rect.fromLTWH(0, 0, 100, 100),
        pixelsPerUnit: 100,
        pivot: NormalizedPivot.center,
      );

      // Pivot is at (50, 50). PPU is 100.
      // Bounds should be (-0.5, -0.5, 1, 1)
      expect(sprite.bounds, const ui.Rect.fromLTWH(-0.5, -0.5, 1, 1));
    });
  });

  group('SpriteSheet', () {
    group('GridSpriteSheet', () {
      final sheet = SpriteSheet.grid(
        texture: texture,
        rows: 2,
        columns: 4,
      );

      test('should calculate tile rects correctly', () {
        // Texture is 256x128. 4 columns, 2 rows.
        // Each tile is 64x64.
        final sprite00 = sheet[(0, 0)];
        expect(sprite00.rect, const ui.Rect.fromLTWH(0, 0, 64, 64));

        final sprite31 = sheet[(3, 1)];
        expect(sprite31.rect, const ui.Rect.fromLTWH(192, 64, 64, 64));
      });

      test('should throw ArgumentError for out of bounds coordinates', () {
        expect(() => sheet[(-1, 0)], throwsArgumentError);
        expect(() => sheet[(4, 0)], throwsArgumentError);
        expect(() => sheet[(0, 2)], throwsArgumentError);
      });

      test('should support spacing between tiles', () {
        final spacedSheet = SpriteSheet.grid(
          texture: texture,
          rows: 2,
          columns: 2,
          spacing: const ui.Offset(10, 10),
        );

        // Texture 256x128. 2x2 grid with 10px gap.
        // (256 - 10) / 2 = 123 width
        // (128 - 10) / 2 = 59 height

        final sprite00 = spacedSheet[(0, 0)];
        expect(sprite00.rect, const ui.Rect.fromLTWH(0, 0, 123, 59));

        final sprite11 = spacedSheet[(1, 1)];
        // Origin = 1 * (123 + 10) = 133
        // Origin Y = 1 * (59 + 10) = 69
        expect(sprite11.rect, const ui.Rect.fromLTWH(133, 69, 123, 59));
      });
    });

    group('TaggedSpriteSheet', () {
      final sheet = SpriteSheet<String>.tagged(
        texture: texture,
        entries: [
          const SheetEntry(key: 'player', rect: ui.Rect.fromLTWH(0, 0, 32, 32)),
          const SheetEntry(key: 'enemy', rect: ui.Rect.fromLTWH(32, 0, 32, 32)),
        ],
      );

      test('should find sprites by tag', () {
        expect(sheet['player'].rect, const ui.Rect.fromLTWH(0, 0, 32, 32));
        expect(sheet['enemy'].rect, const ui.Rect.fromLTWH(32, 0, 32, 32));
      });

      test('should throw ArgumentError for missing tags', () {
        expect(() => sheet['boss'], throwsArgumentError);
      });
    });

    test('split() should maintain backward compatibility', () {
      final sprites = SpriteSheet.split(texture, rows: 2, columns: 2);
      expect(sprites.length, 4);
      expect(sprites[0].rect, const ui.Rect.fromLTWH(0, 0, 128, 64));
      expect(sprites[3].rect, const ui.Rect.fromLTWH(128, 64, 128, 64));
    });
  });
}
