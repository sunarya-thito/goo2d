import 'dart:ui';

abstract class SpritePivot {
  const SpritePivot();
  const factory SpritePivot.relative(double x, double y) = NormalizedPivot;
  const factory SpritePivot.fixed(double x, double y) = PixelPivot;
  Offset compute(Size size);
}

class NormalizedPivot extends SpritePivot {
  final double x;
  final double y;
  const NormalizedPivot(this.x, this.y);

  @override
  Offset compute(Size size) => Offset(size.width * x, size.height * y);
  static const center = NormalizedPivot(0.5, 0.5);
  static const topLeft = NormalizedPivot(0.0, 0.0);
  static const topRight = NormalizedPivot(1.0, 0.0);
  static const bottomLeft = NormalizedPivot(0.0, 1.0);
  static const bottomRight = NormalizedPivot(1.0, 1.0);
  static const topCenter = NormalizedPivot(0.5, 0.0);
  static const bottomCenter = NormalizedPivot(0.5, 1.0);
  static const leftCenter = NormalizedPivot(0.0, 0.5);
  static const rightCenter = NormalizedPivot(1.0, 0.5);
}

class PixelPivot extends SpritePivot {
  final double x;
  final double y;
  const PixelPivot(this.x, this.y);

  @override
  Offset compute(Size size) => Offset(x, y);
}
