import 'dart:ui' as ui;
import 'package:goo2d/src/sprite.dart';
import 'package:goo2d/src/sprite_fit.dart';

/// Defines the geometric strategy for rendering a sprite.
/// 
/// [SpriteMesh] determines how a [GameSprite]'s texture rectangle is 
/// mapped to a destination area on the canvas. Subclasses can 
/// implement simple quads, 9-slice tiling, or complex custom meshes.
/// 
/// ```dart
/// class MyMesh extends SpriteMesh {
///   @override
///   void render(ui.Canvas canvas, GameSprite sprite, ui.Size size, ui.Paint paint) {
///     // Custom rendering logic
///   }
/// }
/// ```
abstract class SpriteMesh {
  /// Base constructor for all sprite meshes.
  /// 
  /// This constructor initializes the mesh instance used for defining 
  /// the geometric strategy of sprite rendering.
  const SpriteMesh();

  /// Renders the [sprite] onto the [canvas].
  /// 
  /// Uses the specified [destinationSize] and [paint] settings to map 
  /// the texture rectangle to the screen.
  ///
  /// * [canvas]: The target rendering surface.
  /// * [sprite]: The sprite metadata containing texture and source rect.
  /// * [destinationSize]: The pixel dimensions to fill on the canvas.
  /// * [paint]: The painting settings (color, filter, etc.).
  void render(
    ui.Canvas canvas,
    GameSprite sprite,
    ui.Size destinationSize,
    ui.Paint paint,
  );
}

/// A simple rectangular mesh that draws a single quad.
/// 
/// [SimpleMesh] is the default mesh for all sprites. It uses a [SpriteFit] 
/// strategy (like Stretch or Fixed) to map the source rect to the 
/// destination bounds.
/// 
/// ```dart
/// const mesh = SimpleMesh(fit: StretchFit());
/// ```
class SimpleMesh extends SpriteMesh {
  /// The fitting strategy used to map the texture.
  /// 
  /// Determines how pixels are scaled or tiled within the destination.
  final SpriteFit fit;

  /// Creates a [SimpleMesh] with an optional fitting strategy.
  /// 
  /// Defaults to [FixedFit] if no strategy is provided. It provides a 
  /// basic quad-based rendering approach.
  ///
  /// * [fit]: The scaling strategy to use for the single quad.
  const SimpleMesh({this.fit = const SpriteFit.fixed()});

  @override
  void render(
    ui.Canvas canvas,
    GameSprite sprite,
    ui.Size destinationSize,
    ui.Paint paint,
  ) {
    fit.draw(
      canvas,
      sprite.texture.image,
      sprite.rect,
      ui.Rect.fromLTWH(0, 0, destinationSize.width, destinationSize.height),
      paint,
    );
  }
}

/// A mesh that divides the sprite into a grid for advanced scaling (e.g., 9-slicing).
/// 
/// [GridMesh] allows for "non-uniform scaling" where certain parts of 
/// a sprite (like corners) remain fixed in size while other parts 
/// (like the center or edges) stretch or tile. This is essential 
/// for high-quality UI elements.
/// 
/// ```dart
/// const mesh = GridMesh.nineSlice(left: 10, top: 10, right: 10, bottom: 10);
/// ```
class GridMesh extends SpriteMesh {
  /// Horizontal border positions in pixels relative to the left edge.
  /// 
  /// Defines the split points for the columns in the grid.
  final List<double> xBorders;

  /// Vertical border positions in pixels relative to the top edge.
  /// 
  /// Defines the split points for the rows in the grid.
  final List<double> yBorders;

  /// A function that returns the [SpriteFit] strategy for a specific cell.
  /// 
  /// Allows for dynamic fitting strategies based on the grid position.
  final SpriteFit Function(int row, int col) fitProvider;

  /// Creates a [GridMesh] with explicit borders and a fit provider.
  /// 
  /// This constructor initializes the grid with specified split points 
  /// and fitting logic for advanced sprite deformation.
  ///
  /// * [xBorders]: Horizontal split positions in pixels.
  /// * [yBorders]: Vertical split positions in pixels.
  /// * [fitProvider]: The logic to select fitting for each grid cell.
  const GridMesh({
    required this.xBorders,
    required this.yBorders,
    required this.fitProvider,
  });

  /// Convenient constructor for 9-slice (3x3) rendering.
  /// 
  /// Borders [left, top, right, bottom] are defined in pixels. This 
  /// allows for high-quality scaling of UI panels and buttons.
  ///
  /// * [left]: Pixel offset from the left edge.
  /// * [top]: Pixel offset from the top edge.
  /// * [right]: Pixel offset from the right edge.
  /// * [bottom]: Pixel offset from the bottom edge.
  /// * [centerFit]: Scaling strategy for the middle cell.
  /// * [edgeFit]: Scaling strategy for the top/bottom/left/right cells.
  /// * [cornerFit]: Scaling strategy for the four corner cells.
  factory GridMesh.nineSlice({
    required double left,
    required double top,
    required double right,
    required double bottom,
    SpriteFit centerFit = const StretchFit(),
    SpriteFit edgeFit = const StretchFit(),
    SpriteFit cornerFit = const FixedFit(),
  }) {
    return GridMesh(
      xBorders: [left, right],
      yBorders: [top, bottom],
      fitProvider: (row, col) {
        final isRowEdge = row == 0 || row == 2;
        final isColEdge = col == 0 || col == 2;
        if (isRowEdge && isColEdge) return cornerFit;
        if (isRowEdge || isColEdge) return edgeFit;
        return centerFit;
      },
    );
  }

  /// Convenient constructor for 25-slice (5x5) rendering.
  /// 
  /// Used for complex UI elements that have multiple distinct scaling zones. 
  /// This provides even more control over corner and edge preservation.
  ///
  /// * [leftOuter]: Outer left border pixel offset.
  /// * [leftInner]: Inner left border pixel offset.
  /// * [topOuter]: Outer top border pixel offset.
  /// * [topInner]: Inner top border pixel offset.
  /// * [rightOuter]: Outer right border pixel offset.
  /// * [rightInner]: Inner right border pixel offset.
  /// * [bottomOuter]: Outer bottom border pixel offset.
  /// * [bottomInner]: Inner bottom border pixel offset.
  /// * [centerFit]: Scaling strategy for the middle cell.
  /// * [edgeCenterFit]: Scaling strategy for the edge-adjacent cells.
  /// * [edgeFit]: Scaling strategy for the outer edge cells.
  /// * [cornerFit]: Scaling strategy for the four corner cells.
  factory GridMesh.twentyFiveSlice({
    required double leftOuter,
    required double leftInner,
    required double topOuter,
    required double topInner,
    required double rightOuter,
    required double rightInner,
    required double bottomOuter,
    required double bottomInner,
    SpriteFit centerFit = const StretchFit(),
    SpriteFit edgeCenterFit = const StretchFit(),
    SpriteFit edgeFit = const StretchFit(),
    SpriteFit cornerFit = const FixedFit(),
  }) {
    return GridMesh(
      xBorders: [leftOuter, leftInner, rightInner, rightOuter],
      yBorders: [topOuter, topInner, bottomInner, bottomOuter],
      fitProvider: (row, col) {
        final distRow = (row - 2).abs(); // 0 at center, 2 at outer
        final distCol = (col - 2).abs();
        final maxDist = distRow > distCol ? distRow : distCol;

        if (maxDist == 0) return centerFit;
        if (maxDist == 1) return edgeCenterFit;
        return (distRow == 2 && distCol == 2) ? cornerFit : edgeFit;
      },
    );
  }

  @override
  void render(
    ui.Canvas canvas,
    GameSprite sprite,
    ui.Size destinationSize,
    ui.Paint paint,
  ) {
    final src = sprite.rect;

    final List<double> xSrc = _computeSourceLines(xBorders, src.width);
    final List<double> ySrc = _computeSourceLines(yBorders, src.height);

    final List<double> xDst = _computeDestLines(xSrc, destinationSize.width);
    final List<double> yDst = _computeDestLines(ySrc, destinationSize.height);

    final int rows = ySrc.length - 1;
    final int cols = xSrc.length - 1;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final cellSrc = ui.Rect.fromLTWH(
          src.left + xSrc[col],
          src.top + ySrc[row],
          xSrc[col + 1] - xSrc[col],
          ySrc[row + 1] - ySrc[row],
        );
        final cellDst = ui.Rect.fromLTWH(
          xDst[col],
          yDst[row],
          xDst[col + 1] - xDst[col],
          yDst[row + 1] - yDst[row],
        );

        if (cellSrc.width <= 0 ||
            cellSrc.height <= 0 ||
            cellDst.width <= 0 ||
            cellDst.height <= 0) {
          continue;
        }

        fitProvider(
          row,
          col,
        ).draw(canvas, sprite.texture.image, cellSrc, cellDst, paint);
      }
    }
  }

  /// Calculates the pixel coordinates of the grid lines in source space.
  /// 
  /// Transforms the relative borders into absolute pixel offsets within the 
  /// source rectangle. It handles mirroring for symmetric grid definitions.
  /// 
  /// * [borders]: The relative border offsets in pixels.
  /// * [total]: The total width or height of the source area.
  List<double> _computeSourceLines(List<double> borders, double total) {
    final int half = borders.length ~/ 2;
    final List<double> lines = [0.0];

    double current = 0.0;
    for (int i = 0; i < half; i++) {
      current += borders[i];
      lines.add(current);
    }

    final List<double> rightLines = [];
    current = total;
    for (int i = borders.length - 1; i >= half; i--) {
      current -= borders[i];
      rightLines.add(current);
    }

    lines.addAll(rightLines.reversed);
    lines.add(total);
    return lines;
  }

  /// Calculates the pixel coordinates of the grid lines in destination space.
  /// 
  /// Maps the source grid lines to the destination dimensions while 
  /// preserving fixed-size borders and distributing middle sections.
  /// 
  /// * [srcLines]: The previously calculated source pixel coordinates.
  /// * [destTotal]: The total width or height of the destination area.
  List<double> _computeDestLines(List<double> srcLines, double destTotal) {
    final count = srcLines.length;
    final List<double> dst = List.filled(count, 0.0);
    final int half = (count - 1) ~/ 2;

    // Start side fixed
    dst[0] = 0.0;
    for (int i = 1; i <= half; i++) {
      dst[i] = dst[i - 1] + (srcLines[i] - srcLines[i - 1]);
    }

    // End side fixed
    dst[count - 1] = destTotal;
    for (int i = count - 2; i >= count - 1 - (count - 1 - half) + 1; i--) {
      dst[i] = dst[i + 1] - (srcLines[i + 1] - srcLines[i]);
    }

    // Middle segments distribution (proportional if multiple, but usually just one)
    final srcMiddleTotal = srcLines[count - 1 - half] - srcLines[half];
    final dstMiddleTotal = dst[count - 1 - half] - dst[half];

    if (srcMiddleTotal > 0 && dstMiddleTotal > 0) {
      for (int i = half + 1; i < count - 1 - half; i++) {
        final ratio = (srcLines[i] - srcLines[i - 1]) / srcMiddleTotal;
        dst[i] = dst[i - 1] + (dstMiddleTotal * ratio);
      }
    } else {
      for (int i = half + 1; i < count - 1 - half; i++) {
        dst[i] = dst[i - 1];
      }
    }

    return dst;
  }
}
