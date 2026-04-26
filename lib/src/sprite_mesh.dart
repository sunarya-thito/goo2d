import 'dart:ui' as ui;
import 'sprite.dart';

abstract class SpriteMesh {
  const SpriteMesh();

  void render(
    ui.Canvas canvas,
    GameSprite sprite,
    ui.Size destinationSize,
    ui.Paint paint,
  );
}

class SimpleMesh extends SpriteMesh {
  final SpriteFit fit;
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

class GridMesh extends SpriteMesh {
  final List<double> xBorders;
  final List<double> yBorders;
  final SpriteFit Function(int row, int col) fitProvider;

  const GridMesh({
    required this.xBorders,
    required this.yBorders,
    required this.fitProvider,
  });

  /// Convenient constructor for 9-slice (3x3).
  /// Borders are [left, top, right, bottom] in pixels.
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

  /// Convenient constructor for 25-slice (5x5).
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
