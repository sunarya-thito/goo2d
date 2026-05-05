import 'package:goo2d/goo2d.dart';

/// Mixin for components that receive physics collision and trigger callbacks.
///
/// Attach to a [Component] on the same [GameObject] as a [Collider].
/// Callbacks mirror Unity's `OnCollisionEnter2D` / `OnTriggerEnter2D` family.
///
/// ```dart
/// class Player extends Behavior with CollisionListener {
///   @override
///   Future<void> onCollisionEnter(Collision collision) async {
///     print('Hit ${collision.gameObject}');
///   }
/// }
/// ```
mixin CollisionListener on EventListener {
  Future<void> onCollisionEnter(Collision collision) async {}
  Future<void> onCollisionStay(Collision collision) async {}
  Future<void> onCollisionExit(Collision collision) async {}
  Future<void> onTriggerEnter(Collider other) async {}
  Future<void> onTriggerStay(Collider other) async {}
  Future<void> onTriggerExit(Collider other) async {}
}

class CollisionEnterEvent extends AsyncEvent<CollisionListener> {
  final Collision collision;
  CollisionEnterEvent(this.collision);
  @override
  Future<void> dispatch(CollisionListener listener) =>
      listener.onCollisionEnter(collision);
}

class CollisionStayEvent extends AsyncEvent<CollisionListener> {
  final Collision collision;
  CollisionStayEvent(this.collision);
  @override
  Future<void> dispatch(CollisionListener listener) =>
      listener.onCollisionStay(collision);
}

class CollisionExitEvent extends AsyncEvent<CollisionListener> {
  final Collision collision;
  CollisionExitEvent(this.collision);
  @override
  Future<void> dispatch(CollisionListener listener) =>
      listener.onCollisionExit(collision);
}

class TriggerEnterEvent extends AsyncEvent<CollisionListener> {
  final Collider other;
  TriggerEnterEvent(this.other);
  @override
  Future<void> dispatch(CollisionListener listener) =>
      listener.onTriggerEnter(other);
}

class TriggerStayEvent extends AsyncEvent<CollisionListener> {
  final Collider other;
  TriggerStayEvent(this.other);
  @override
  Future<void> dispatch(CollisionListener listener) =>
      listener.onTriggerStay(other);
}

class TriggerExitEvent extends AsyncEvent<CollisionListener> {
  final Collider other;
  TriggerExitEvent(this.other);
  @override
  Future<void> dispatch(CollisionListener listener) =>
      listener.onTriggerExit(other);
}
