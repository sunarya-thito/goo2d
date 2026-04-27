import 'dart:ui';

import 'package:goo2d/goo2d.dart';

mixin Renderable implements EventListener {
  void render(Canvas canvas);
}

class RenderEvent extends Event<Renderable> {
  final Canvas canvas;

  const RenderEvent(this.canvas);

  @override
  void dispatch(Renderable listener) {
    listener.render(canvas);
  }
}

/// Bitmask for rendering layers.
class RenderLayer {
  static const int none = 0;
  static const int defaultLayer = 1 << 0;
  static const int world = 1 << 0;
  static const int ui = 1 << 1;
  static const int all = 0xFFFFFFFF;

  RenderLayer._();
}
