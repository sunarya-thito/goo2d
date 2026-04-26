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
  final ui.Image _image;

  @override
  int get width => _width;
  @override
  int get height => _height;

  MockTexture(this._width, this._height, this._image) : super(MockSource());

  @override
  Future<void> load() async {}
  @override
  void unload() {}
  @override
  ui.Image get image => _image;
}

class FakeCanvas extends Fake implements ui.Canvas {
  @override
  void save() {}
  @override
  void restore() {}
  @override
  void translate(double dx, double dy) {}
  @override
  void scale(double sx, [double? sy]) {}
}

class RecordingFit extends SpriteFit {
  final List<ui.Rect> srcRects = [];
  final List<ui.Rect> dstRects = [];

  @override
  void draw(
    ui.Canvas canvas,
    ui.Image image,
    ui.Rect src,
    ui.Rect dst,
    ui.Paint paint,
  ) {
    srcRects.add(src);
    dstRects.add(dst);
  }
}

Future<ui.Image> createTestImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawColor(const ui.Color(0xFFFF0000), ui.BlendMode.src);
  final picture = recorder.endRecording();
  return await picture.toImage(10, 10);
}

void main() {
  group('SpriteMesh', () {
    late ui.Image image;
    late MockTexture texture;
    late GameSprite sprite;
    final canvas = FakeCanvas();

    setUpAll(() async {
      image = await createTestImage();
      texture = MockTexture(100, 100, image);
      sprite = GameSprite(
        texture: texture,
        rect: const ui.Rect.fromLTWH(0, 0, 100, 100),
      );
    });

    testWidgets('SimpleMesh should draw full sprite to destination', (
      tester,
    ) async {
      final recorder = RecordingFit();
      final mesh = SimpleMesh(fit: recorder);
      mesh.render(canvas, sprite, const ui.Size(200, 200), ui.Paint());
      expect(recorder.srcRects.single, const ui.Rect.fromLTWH(0, 0, 100, 100));
      expect(recorder.dstRects.single, const ui.Rect.fromLTWH(0, 0, 200, 200));
    });

    testWidgets(
      'GridMesh (9-Slice) should partition rects correctly for 3x3 grid',
      (tester) async {
        final recorder = RecordingFit();
        final mesh = GridMesh.nineSlice(
          left: 10,
          top: 10,
          right: 10,
          bottom: 10,
          centerFit: recorder,
          edgeFit: recorder,
          cornerFit: recorder,
        );

        mesh.render(canvas, sprite, const ui.Size(300, 300), ui.Paint());

        expect(recorder.srcRects.length, 9);
        expect(recorder.srcRects[0], const ui.Rect.fromLTWH(0, 0, 10, 10));
        expect(recorder.dstRects[0], const ui.Rect.fromLTWH(0, 0, 10, 10));
        expect(recorder.srcRects[4], const ui.Rect.fromLTWH(10, 10, 80, 80));
        expect(recorder.dstRects[4], const ui.Rect.fromLTWH(10, 10, 280, 280));
      },
    );
  });
}
