import 'package:goo2d/goo2d.dart';

class CollisionEvent extends Event<CollisionListener> {
  final Collision collision;
  final CollisionState state;
  const CollisionEvent(this.collision, this.state);

  @override
  void dispatch(CollisionListener listener) {
    switch (state) {
      case CollisionState.enter:
        listener.onCollisionEnter(collision);
      case CollisionState.stay:
        listener.onCollisionStay(collision);
      case CollisionState.exit:
        listener.onCollisionExit(collision);
    }
  }
}
