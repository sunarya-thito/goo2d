import 'package:goo2d/goo2d.dart';

class TriggerEvent extends Event<TriggerListener> {
  final Collider trigger;
  final Collider other;
  final CollisionState state;
  const TriggerEvent(this.trigger, this.other, this.state);

  @override
  void dispatch(TriggerListener listener) {
    switch (state) {
      case CollisionState.enter:
        listener.onTriggerEnter(other);
      case CollisionState.stay:
        listener.onTriggerStay(other);
      case CollisionState.exit:
        listener.onTriggerExit(other);
    }
  }
}
