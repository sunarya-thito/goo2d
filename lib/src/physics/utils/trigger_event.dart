import 'package:goo2d/goo2d.dart';

/// Event dispatched when a collider enters or exits a trigger volume.
/// 
/// Triggers do not resolve physically but generate these events to 
/// detect region occupancy. This is primarily used by the [PhysicsSystem] 
/// to notify [TriggerListener]s.
/// 
/// ```dart
/// // Internal usage by PhysicsSystem
/// game.events.dispatch(TriggerEvent(trigger, other, CollisionState.enter));
/// ```
class TriggerEvent extends Event<TriggerListener> {
  /// The trigger collider that detected the overlap.
  /// 
  /// This is the collider with [Collider.isTrigger] set to true.
  final Collider trigger;
  
  /// The other collider that entered the trigger.
  /// 
  /// This can be either a solid or another trigger collider.
  final Collider other;
  
  /// The current state of the overlap.
  /// 
  /// Determines whether the enter, stay, or exit callback is triggered.
  final CollisionState state;

  /// Creates a [TriggerEvent].
  /// 
  /// * [trigger]: The detecting volume.
  /// * [other]: The overlapping object.
  /// * [state]: Lifecycle phase of the overlap.
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
