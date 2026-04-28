import 'package:flutter/painting.dart';
import 'package:goo2d/goo2d.dart';

/// Defines the physical properties of a collider.
class PhysicsMaterial {
  final double bounciness;
  final double friction;

  const PhysicsMaterial({
    this.bounciness = 0.0,
    this.friction = 0.4,
  });

  static const defaultMaterial = PhysicsMaterial();
}

class RaycastHit {
  final Collider collider;
  final Offset point;
  final Offset normal;
  final double distance;
  final double fraction;

  RaycastHit({
    required this.collider,
    required this.point,
    required this.normal,
    required this.distance,
    required this.fraction,
  });
}

/// Information about a collision between two colliders.
class Collision {
  final Collider collider;
  final Collider otherCollider;
  final GameObject gameObject;
  final Rigidbody? rigidbody;
  final Offset contactPoint;
  final Offset normal;
  final double impulse;

  const Collision({
    required this.collider,
    required this.otherCollider,
    required this.gameObject,
    this.rigidbody,
    required this.contactPoint,
    required this.normal,
    required this.impulse,
  });
}

/// Event dispatched when a collision occurs.
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

enum CollisionState { enter, stay, exit }

/// Interface for components that want to listen for collisions.
mixin CollisionListener implements EventListener {
  void onCollisionEnter(Collision collision) {}
  void onCollisionStay(Collision collision) {}
  void onCollisionExit(Collision collision) {}
}

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

/// Interface for components that want to listen for trigger overlaps.
mixin TriggerListener implements EventListener {
  void onTriggerEnter(Collider other) {}
  void onTriggerStay(Collider other) {}
  void onTriggerExit(Collider other) {}
}
