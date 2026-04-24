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
