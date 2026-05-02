import 'package:flutter/gestures.dart';
import 'package:goo2d/goo2d.dart';

mixin PointerReceiver implements EventListener {
  void onPointerDown(PointerDownEvent event) {}
  void onPointerUp(PointerUpEvent event) {}
  void onPointerMove(PointerMoveEvent event) {}
  void onPointerCancel(PointerCancelEvent event) {}
  void onPointerEnter(PointerEnterEvent event) {}
  void onPointerExit(PointerExitEvent event) {}
  void onPointerHover(PointerHoverEvent event) {}
}

class GamePointerDownEvent extends Event<PointerReceiver> {
  final PointerDownEvent event;
  const GamePointerDownEvent(this.event);

  @override
  void dispatch(PointerReceiver listener) {
    listener.onPointerDown(event);
  }
}

class GamePointerUpEvent extends Event<PointerReceiver> {
  final PointerUpEvent event;
  const GamePointerUpEvent(this.event);

  @override
  void dispatch(PointerReceiver listener) {
    listener.onPointerUp(event);
  }
}

class GamePointerMoveEvent extends Event<PointerReceiver> {
  final PointerMoveEvent event;
  const GamePointerMoveEvent(this.event);

  @override
  void dispatch(PointerReceiver listener) {
    listener.onPointerMove(event);
  }
}

class GamePointerCancelEvent extends Event<PointerReceiver> {
  final PointerCancelEvent event;
  const GamePointerCancelEvent(this.event);

  @override
  void dispatch(PointerReceiver listener) {
    listener.onPointerCancel(event);
  }
}

class GamePointerEnterEvent extends Event<PointerReceiver> {
  final PointerEnterEvent event;
  const GamePointerEnterEvent(this.event);

  @override
  void dispatch(PointerReceiver listener) {
    listener.onPointerEnter(event);
  }
}

class GamePointerExitEvent extends Event<PointerReceiver> {
  final PointerExitEvent event;
  const GamePointerExitEvent(this.event);

  @override
  void dispatch(PointerReceiver listener) {
    listener.onPointerExit(event);
  }
}

class GamePointerHoverEvent extends Event<PointerReceiver> {
  final PointerHoverEvent event;
  const GamePointerHoverEvent(this.event);

  @override
  void dispatch(PointerReceiver listener) {
    listener.onPointerHover(event);
  }
}
