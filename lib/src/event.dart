import 'package:goo2d/goo2d.dart';

mixin EventListener on Component {}

abstract class Event<T extends EventListener> {
  const Event();
  void dispatch(T listener);

  void dispatchTo(GameObject object) {
    for (final listener in object.components.whereType<T>()) {
      if (listener is Behavior && !(listener as Behavior).enabled) {
        continue;
      }
      dispatch(listener);
    }
  }
}
