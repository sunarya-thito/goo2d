import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

class SpritePolygonGenerator {
  /// Generates a list of vertices that approximate the outline of the sprite's alpha channel.
  static List<Offset> generate({
    required Uint32List pixels,
    required int width,
    required int height,
    Rect? sourceRect,
    double alphaThreshold = 0.1,
    double tolerance = 1.0,
  }) {
    if (pixels.isEmpty || width == 0 || height == 0) return [];

    final rect = sourceRect ?? Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());
    final thresholdInt = (alphaThreshold * 255).round();

    // 1. Find an initial starting point within the rect
    Offset? start;
    outer:
    for (int y = rect.top.toInt(); y < rect.bottom.toInt(); y++) {
      for (int x = rect.left.toInt(); x < rect.right.toInt(); x++) {
        if (_getAlpha(pixels, width, x, y) >= thresholdInt) {
          start = Offset(x.toDouble(), y.toDouble());
          break outer;
        }
      }
    }

    if (start == null) return [];

    // 2. Trace the contour using Moore-Neighbor Tracing
    final contour = _traceMooreNeighbor(pixels, width, height, rect, start, thresholdInt);
    if (contour.isEmpty) return [];

    // 3. Simplify using Ramer-Douglas-Peucker
    final simplified = _simplifyRDP(contour, tolerance);
    
    // Remove the last point if it's the same as the first (closed loop)
    if (simplified.length > 1 && simplified.first == simplified.last) {
      simplified.removeLast();
    }
    
    return simplified;
  }

  static int _getAlpha(Uint32List pixels, int width, int x, int y) {
    final pixel = pixels[y * width + x];
    return (pixel >> 24) & 0xFF;
  }

  static List<Offset> _traceMooreNeighbor(
    Uint32List pixels,
    int width,
    int height,
    Rect rect,
    Offset start,
    int threshold,
  ) {
    final List<Offset> points = [];
    Offset current = start;
    
    final List<Offset> neighbors = [
      const Offset(-1, -1), const Offset(0, -1), const Offset(1, -1),
      const Offset(1, 0),   const Offset(1, 1),  const Offset(0, 1),
      const Offset(-1, 1),  const Offset(-1, 0),
    ];

    int dir = 7; 

    do {
      points.add(current);
      bool found = false;

      for (int i = 0; i < 8; i++) {
        final checkDir = (dir + i) % 8;
        final neighborPos = current + neighbors[checkDir];

        if (neighborPos.dx >= rect.left &&
            neighborPos.dx < rect.right &&
            neighborPos.dy >= rect.top &&
            neighborPos.dy < rect.bottom) {
          if (_getAlpha(pixels, width, neighborPos.dx.toInt(), neighborPos.dy.toInt()) >= threshold) {
            current = neighborPos;
            dir = (checkDir + 6) % 8; 
            found = true;
            break;
          }
        }
      }

      if (!found) break; 
      if (points.length > rect.width * rect.height) break; 

    } while (current != start);

    // Add start point at the end to close the loop for RDP
    points.add(start);

    return points;
  }

  static List<Offset> _simplifyRDP(List<Offset> points, double tolerance) {
    if (points.length < 3) return points;

    int index = -1;
    double maxDist = 0;

    for (int i = 1; i < points.length - 1; i++) {
      final dist = _perpendicularDistance(points[i], points[0], points.last);
      if (dist > maxDist) {
        index = i;
        maxDist = dist;
      }
    }

    if (maxDist > tolerance) {
      final left = _simplifyRDP(points.sublist(0, index + 1), tolerance);
      final right = _simplifyRDP(points.sublist(index), tolerance);
      return [...left.sublist(0, left.length - 1), ...right];
    } else {
      return [points.first, points.last];
    }
  }

  static double _perpendicularDistance(Offset p, Offset start, Offset end) {
    final area = ((end.dy - start.dy) * p.dx -
            (end.dx - start.dx) * p.dy +
            end.dx * start.dy -
            end.dy * start.dx)
        .abs();
    final bottom = sqrt(pow(end.dy - start.dy, 2) + pow(end.dx - start.dx, 2));
    if (bottom == 0) return (p - start).distance;
    return area / bottom;
  }
}
