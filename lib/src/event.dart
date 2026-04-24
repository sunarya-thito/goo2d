import 'package:goo2d/goo2d.dart';

mixin EventListener on Component {}

abstract class Event<T extends EventListener> {
  const Event();
  void dispatch(T listener);

  void dispatchTo(GameObject object) {
    if (object is T && object.active) {
      dispatch(object as T);
    }
    for (final listener in object.components.whereType<T>()) {
      if (listener is Behavior && !(listener as Behavior).enabled) {
        continue;
      }
      dispatch(listener);
    }
  }
}
