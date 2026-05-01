import 'package:goo2d/goo2d.dart';

/// Event dispatched when a collision occurs between two solid colliders.
/// 
/// This is an internal event used by the [PhysicsSystem] to notify 
/// [GameObject] components about physical interactions. It encapsulates 
/// the [Collision] data and the lifecycle [CollisionState].
/// 
/// ```dart
/// // Internal usage by PhysicsSystem
/// game.events.dispatch(CollisionEvent(data, CollisionState.enter));
/// ```
class CollisionEvent extends Event<CollisionListener> {
  /// The detailed collision data.
  /// 
  /// Includes point of contact, normal, and impulse.
  final Collision collision;
  
  /// The current state of the collision (enter, stay, or exit).
  /// 
  /// Determines which method of the [CollisionListener] will be called.
  final CollisionState state;

  /// Creates a [CollisionEvent].
  /// 
  /// * [collision]: Detailed impact data.
  /// * [state]: Lifecycle phase of the contact.
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
