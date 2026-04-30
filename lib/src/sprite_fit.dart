import 'dart:ui' as ui;
import 'package:flutter/widgets.dart'
    show BoxFit, applyBoxFit, FittedSizes, Alignment;
import 'package:vector_math/vector_math_64.dart';

/// Strategy for fitting a sprite's texture into a target rectangle.
/// 
/// Different fit strategies determine how the sprite handles aspect ratio 
/// mismatches. This is similar to Flutter's [BoxFit] but optimized for 
/// direct [Canvas] drawing.
/// 
/// ```dart
/// const fit = StretchFit();
/// fit.draw(canvas, image, src, dst, paint);
/// ```
abstract class SpriteFit {
  /// Scales the sprite to fit the target rectangle exactly.
  /// 
  /// Ignores the original aspect ratio to fill the entire destination.
  static const SpriteFit stretch = StretchFit();

  /// Repeats the texture across the target rectangle.
  /// 
  /// Creates a tiled pattern using the source rectangle.
  static const SpriteFit tile = TileFit();

  /// Places the sprite at its intrinsic size.
  /// 
  /// Aligns the source pixels within the target without scaling. This 
  /// ensures no distortion or pixel artifacts from interpolation.
  /// 
  /// * [alignment]: How to position the sprite within the target.
  const factory SpriteFit.fixed({Alignment alignment}) = FixedFit;

  /// Fills the target while preserving aspect ratio.
  /// 
  /// Crops the source if necessary to fill the entire destination area. This 
  /// is useful for full-screen backgrounds where no black bars are desired.
  /// 
  /// * [alignment]: How to align the texture after cropping.
  const factory SpriteFit.cover({Alignment alignment}) = CoverFit;

  /// Scales to fit within the target while preserving aspect ratio.
  /// 
  /// Ensures the entire source is visible within the destination bounds. This 
  /// may result in empty space if the aspect ratios do not match.
  /// 
  /// * [alignment]: How to align the texture within the remaining space.
  const factory SpriteFit.contain({Alignment alignment}) = ContainFit;

  /// Constant constructor for subclasses.
  /// 
  /// Initializes the fitting strategy instance.
  const SpriteFit();

  /// Draws the [image] into the [canvas] using this fit strategy.
  /// 
  /// Performs the actual rendering logic for the specific strategy.
  ///
  /// * [canvas]: The target drawing surface.
  /// * [image]: The texture to draw.
  /// * [src]: The source rectangle within the image.
  /// * [dst]: The target rectangle on the canvas.
  /// * [paint]: The paint configuration to use.
  void draw(
    ui.Canvas canvas,
    ui.Image image,
    ui.Rect src,
    ui.Rect dst,
    ui.Paint paint,
  );
}

/// Fits the sprite by stretching it to the target dimensions.
/// 
/// Extends the [SpriteFit] strategy to fill the destination.
/// 
/// ```dart
/// const fit = StretchFit();
/// ```
class StretchFit extends SpriteFit {
  /// Creates a stretch fit strategy.
  /// 
  /// This constructor initializes the stretching logic that ignores aspect 
  /// ratios to fill the target rectangle completely.
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

/// Repeats the texture repeatedly to fill the target rectangle.
/// 
/// This strategy is useful for backgrounds or large areas that need a 
/// pattern. It links to [SpriteFit] for the base implementation.
/// 
/// ```dart
/// const fit = TileFit();
/// ```
class TileFit extends SpriteFit {
  /// Creates a tiling fit strategy.
  /// 
  /// This constructor initializes the tiling logic that repeats the texture 
  /// coordinates across the target area.
  const TileFit();

  /// Computes the transformation matrix required for tiling.
  /// 
  /// Calculates scaling and translation to align [src] to [dst].
  ///
  /// * [src]: The source region of the texture.
  /// * [dst]: The target region to fill.
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

/// Places the sprite at its intrinsic size.
/// 
/// The sprite is not scaled; it is simply aligned within the destination. 
/// Extends the [SpriteFit] strategy.
/// 
/// ```dart
/// const fit = FixedFit();
/// ```
class FixedFit extends SpriteFit {
  /// How to align the sprite within the target rectangle.
  /// 
  /// Determines the anchor point for positioning the fixed-size pixels.
  final Alignment alignment;

  /// Creates a fixed fit with the given [alignment].
  /// 
  /// This constructor initializes the alignment used for positioning the 
  /// sprite at its original pixel dimensions.
  ///
  /// * [alignment]: The alignment strategy within the target rectangle.
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

/// Fills the target while preserving aspect ratio, potentially cropping.
/// 
/// Ensures the entire destination is covered by the sprite. Links to 
/// [SpriteFit] for the base implementation.
/// 
/// ```dart
/// const fit = CoverFit();
/// ```
class CoverFit extends SpriteFit {
  /// How to align the texture after cropping.
  /// 
  /// Determines which part of the source remains visible in the destination.
  final Alignment alignment;

  /// Creates a cover fit with the given [alignment].
  /// 
  /// This constructor initializes the alignment used for cropping the 
  /// source texture to fill the destination area.
  ///
  /// * [alignment]: The alignment strategy used for cropping.
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

/// Fits within the target while preserving aspect ratio.
/// 
/// Ensures the entire source is visible within the destination bounds. 
/// Extends the [SpriteFit] strategy.
/// 
/// ```dart
/// const fit = ContainFit();
/// ```
class ContainFit extends SpriteFit {
  /// How to align the texture within the remaining space.
  /// 
  /// Determines the positioning when the source doesn't fill the target.
  final Alignment alignment;

  /// Creates a contain fit with the given [alignment].
  /// 
  /// This constructor initializes the alignment used for scaling the 
  /// sprite to fit inside the destination bounds.
  ///
  /// * [alignment]: The alignment strategy for positioning.
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
