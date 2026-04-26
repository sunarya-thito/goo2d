import 'dart:ui' as ui;
import 'package:flutter/widgets.dart'
    show BoxFit, applyBoxFit, FittedSizes, Alignment;
import 'package:vector_math/vector_math_64.dart';

abstract class SpriteFit {
  static const SpriteFit stretch = StretchFit();
  static const SpriteFit tile = TileFit();
  const factory SpriteFit.fixed({Alignment alignment}) = FixedFit;
  const factory SpriteFit.cover({Alignment alignment}) = CoverFit;
  const factory SpriteFit.contain({Alignment alignment}) = ContainFit;
  const SpriteFit();

  void draw(
    ui.Canvas canvas,
    ui.Image image,
    ui.Rect src,
    ui.Rect dst,
    ui.Paint paint,
  );
}

class StretchFit extends SpriteFit {
  const StretchFit();

  @override
  void draw(
    ui.Canvas canvas,
    ui.Image image,
    ui.Rect src,
    ui.Rect dst,
    ui.Paint paint,
  ) {
    canvas.drawImageRect(image, src, dst, paint);
  }
}

class TileFit extends SpriteFit {
  const TileFit();

  /// Computes the transformation matrix required to tile the 'src' rect into 'dst'.
  static Matrix4 computeMatrix(ui.Rect src, ui.Rect dst) {
    final double sx = dst.width / src.width;
    final double sy = dst.height / src.height;
    final matrix = Matrix4.identity();
    matrix.translateByDouble(
      dst.left - src.left * sx,
      dst.top - src.top * sy,
      0.0,
      1.0,
    );
    matrix.scaleByDouble(sx, sy, 1.0, 1.0);
    return matrix;
  }

  @override
  void draw(
    ui.Canvas canvas,
    ui.Image image,
    ui.Rect src,
    ui.Rect dst,
    ui.Paint paint,
  ) {
    final originalShader = paint.shader;

    // ImageShader tiles the entire image.
    // To tile only a sub-rect 'src' into 'dst', we must use the matrix:
    final matrix = computeMatrix(src, dst);

    paint.shader = ui.ImageShader(
      image,
      ui.TileMode.repeated,
      ui.TileMode.repeated,
      matrix.storage,
    );

    canvas.drawRect(dst, paint);
    paint.shader = originalShader;
  }
}

class FixedFit extends SpriteFit {
  final Alignment alignment;
  const FixedFit({this.alignment = Alignment.center});

  @override
  void draw(
    ui.Canvas canvas,
    ui.Image image,
    ui.Rect src,
    ui.Rect dst,
    ui.Paint paint,
  ) {
    // Draws at src size, aligned in dst
    final rect = alignment.inscribe(src.size, dst);
    canvas.drawImageRect(image, src, rect, paint);
  }
}

class CoverFit extends SpriteFit {
  final Alignment alignment;
  const CoverFit({this.alignment = Alignment.center});

  @override
  void draw(
    ui.Canvas canvas,
    ui.Image image,
    ui.Rect src,
    ui.Rect dst,
    ui.Paint paint,
  ) {
    final FittedSizes sizes = applyBoxFit(BoxFit.cover, src.size, dst.size);
    final ui.Rect destinationRect = alignment.inscribe(sizes.destination, dst);
    final ui.Rect sourceRect = alignment.inscribe(sizes.source, src);
    canvas.drawImageRect(image, sourceRect, destinationRect, paint);
  }
}

class ContainFit extends SpriteFit {
  final Alignment alignment;
  const ContainFit({this.alignment = Alignment.center});

  @override
  void draw(
    ui.Canvas canvas,
    ui.Image image,
    ui.Rect src,
    ui.Rect dst,
    ui.Paint paint,
  ) {
    final FittedSizes sizes = applyBoxFit(BoxFit.contain, src.size, dst.size);
    final ui.Rect destinationRect = alignment.inscribe(sizes.destination, dst);
    canvas.drawImageRect(image, src, destinationRect, paint);
  }
}
