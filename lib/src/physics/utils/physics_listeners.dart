import 'package:goo2d/goo2d.dart';

/// Interface for components that want to listen for physical collisions.
/// 
/// To receive these events, the [GameObject] must have at least one [Collider] 
/// and be registered with the [PhysicsSystem].
mixin CollisionListener implements EventListener {
  /// Called when a collision begins.
  /// 
  /// * [collision]: Impact details and contact point.
  void onCollisionEnter(Collision collision) {}
  
  /// Called every frame while the collision continues.
  /// 
  /// * [collision]: Sustained contact details.
  void onCollisionStay(Collision collision) {}
  
  /// Called when the collision ends.
  /// 
  /// * [collision]: Final contact state before separation.
  void onCollisionExit(Collision collision) {}
}

/// Interface for components that want to listen for trigger volume overlaps.
/// 
/// Triggers are ideal for zone detection, power-ups, or area-of-effect logic.
mixin TriggerListener implements EventListener {
  /// Called when another collider enters the trigger.
  /// 
  /// * [other]: The collider that entered the zone.
  void onTriggerEnter(Collider other) {}
  
  /// Called every frame while the other collider remains inside.
  /// 
  /// * [other]: The collider currently inside the zone.
  void onTriggerStay(Collider other) {}
  
  /// Called when the other collider exits the trigger.
  /// 
  /// * [other]: The collider that just left the zone.
  void onTriggerExit(Collider other) {}
}
