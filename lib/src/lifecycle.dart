import 'package:goo2d/src/event.dart';

mixin LifecycleListener implements EventListener {
  void onMounted() {}
  void onUnmounted() {}
}

class MountedEvent extends Event<LifecycleListener> {
  const MountedEvent();

  @override
  void dispatch(LifecycleListener listener) {
    listener.onMounted();
  }
}

class UnmountedEvent extends Event<LifecycleListener> {
  const UnmountedEvent();

  @override
  void dispatch(LifecycleListener listener) {
    listener.onUnmounted();
  }
}

mixin HotReloadable implements EventListener {
  void onHotReload() {}
}

class HotReloadEvent extends Event<HotReloadable> {
  const HotReloadEvent();

  @override
  void dispatch(HotReloadable listener) {
    listener.onHotReload();
  }
}
