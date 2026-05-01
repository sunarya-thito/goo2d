import 'package:flutter/painting.dart';

/// Standardized contact data returned by all bridges.
/// 
/// This structure encapsulates the mathematical results of a collision resolution
/// between two [PhysicsShape]s. It is used by the engine to trigger collision 
/// events and play sound effects or spawn particles at the contact point.
/// 
/// ```dart
/// void onCollision(PhysicsContactData contact) {
///   print('Hit at ${contact.contactPoint}');
/// }
/// ```
class PhysicsContactData {
  /// The ID of the first shape in the contact.
  /// 
  /// Usually corresponds to the [PhysicsShape.id] of the body that was 
  /// processed first in the collision pair.
  final int shapeAId;
  
  /// The ID of the second shape in the contact.
  /// 
  /// Usually corresponds to the [PhysicsShape.id] of the body that was 
  /// processed second in the collision pair.
  final int shapeBId;
  
  /// The world-space point of contact.
  /// 
  /// This is the exact position where the two shapes touched or overlapped.
  final Offset contactPoint;
  
  /// The contact normal vector.
  /// 
  /// A normalized vector pointing from [shapeAId] towards [shapeBId] that 
  /// defines the direction of the impact.
  final Offset normal;
  
  /// The penetration depth of the collision.
  /// 
  /// Measured in world units; represents how far the shapes overlapped 
  /// before resolution.
  final double depth;
  
  /// The impulse applied to resolve the collision.
  /// 
  /// This scalar value represents the change in momentum applied along 
  /// the [normal] to separate the bodies.
  final double impulse;

  /// Creates a [PhysicsContactData] object.
  /// 
  /// * [shapeAId]: ID of the first shape.
  /// * [shapeBId]: ID of the second shape.
  /// * [contactPoint]: World-space position of the hit.
  /// * [normal]: Normalized impact direction.
  /// * [depth]: Overlap distance.
  /// * [impulse]: Magnitude of the resolution force.
  PhysicsContactData({
    required this.shapeAId,
    required this.shapeBId,
    required this.contactPoint,
    required this.normal,
    required this.depth,
    required this.impulse,
  });
}

/// Result of a single physics simulation step.
/// 
/// This record is produced by a [PhysicsBridge] after every [PhysicsBridge.step] 
/// and contains all state updates required to synchronize the game engine 
/// with the simulation.
/// 
/// ```dart
/// void handleStep(PhysicsStepResult result) {
///   for (final contact in result.contacts) {
///     // Handle collisions
///   }
/// }
/// ```
class PhysicsStepResult {
  /// A list of all contacts detected during the step.
  /// 
  /// Includes both resolved physical collisions and trigger overlaps.
  final List<PhysicsContactData> contacts;
  
  /// A map of body IDs to their updated physical state.
  /// 
  /// Only contains bodies that moved or changed state during this step.
  final Map<int, PhysicsBodyState> dynamicBodies;

  /// Creates a [PhysicsStepResult].
  /// 
  /// * [contacts]: List of collision records.
  /// * [dynamicBodies]: Map of updated body states.
  PhysicsStepResult({
    required this.contacts,
    required this.dynamicBodies,
  });
}

/// The runtime state of a physics body.
/// 
/// Represents a snapshot of a [PhysicsBody]'s transform and velocities in 
/// the simulation. This is used to update [GameObject] transforms.
/// 
/// ```dart
/// final state = result.dynamicBodies[id]!;
/// gameObject.position = state.position;
/// ```
class PhysicsBodyState {
  /// The world-space position.
  /// 
  /// Calculated by the integrator during the simulation step.
  final Offset position;
  
  /// The rotation in radians.
  /// 
  /// Calculated by the angular integrator during the simulation step.
  final double rotation;
  
  /// The linear velocity.
  /// 
  /// Represents the change in [position] over time (units/sec).
  final Offset velocity;
  
  /// The angular velocity.
  /// 
  /// Represents the change in [rotation] over time (rad/sec).
  final double angularVelocity;

  /// Creates a [PhysicsBodyState].
  /// 
  /// * [position]: New world position.
  /// * [rotation]: New rotation in radians.
  /// * [velocity]: New linear velocity.
  /// * [angularVelocity]: New angular velocity.
  PhysicsBodyState({
    required this.position,
    required this.rotation,
    required this.velocity,
    required this.angularVelocity,
  });
}

/// Data used to synchronize transform changes from the engine back 
/// to the physics simulation.
/// 
/// When a [GameObject] is moved manually via code or animation, this 
/// structure carries that "teleportation" data to the [PhysicsWorld] so 
/// that collisions can be correctly calculated.
/// 
/// ```dart
/// bridge.step(dt, { id: PhysicsTransformSync(pos, rot) });
/// ```
class PhysicsTransformSync {
  /// The current engine position.
  /// 
  /// This will overwrite the body's internal position in the simulation.
  final Offset position;
  
  /// The current engine rotation.
  /// 
  /// This will overwrite the body's internal rotation in the simulation.
  final double rotation;
  
  /// Creates a [PhysicsTransformSync].
  /// 
  /// * [position]: The target position for the body.
  /// * [rotation]: The target rotation for the body.
  PhysicsTransformSync(this.position, this.rotation);
}

/// Raw hit data returned from the physics simulation for a raycast.
/// 
/// Contains detailed information about where and what a raycast hit 
/// in the [PhysicsWorld].
/// 
/// ```dart
/// void handleHit(PhysicsRaycastHitData hit) {
///   print('Hit shape ${hit.shapeId} at ${hit.point}');
/// }
/// ```
class PhysicsRaycastHitData {
  /// The ID of the [PhysicsShape] that was hit.
  /// 
  /// This ID can be used to retrieve the [GameObject] associated with the 
  /// collider or to apply impulses to its parent [PhysicsBody].
  final int shapeId;
  
  /// The world-space intersection point.
  /// 
  /// This is the exact position on the shape's boundary where the ray 
  /// first encountered a solid pixel or geometry.
  final Offset point;
  
  /// The surface normal vector at the point of impact.
  /// 
  /// This vector points directly away from the surface and can be used 
  /// to calculate reflection vectors or to orient decals.
  final Offset normal;
  
  /// The distance from the origin to the hit point.
  /// 
  /// Measured in world units along the ray's trajectory. This is 
  /// always less than or equal to the [maxDistance] specified in the request.
  final double distance;
  
  /// The normalized fraction (0.0 to 1.0) along the ray's maximum length.
  /// 
  /// A value of 0.0 means the hit occurred at the origin, while 1.0 
  /// means it occurred at exactly [maxDistance].
  final double fraction;

  /// Creates a [PhysicsRaycastHitData] snapshot.
  /// 
  /// Encapsulates the results of a raycast intersection for transmission 
  /// between the simulation and the engine.
  /// 
  /// * [shapeId]: ID of the hit shape.
  /// * [point]: Intersection position.
  /// * [normal]: Surface normal.
  /// * [distance]: Length of ray until hit.
  /// * [fraction]: Percentage of maxDistance until hit.
  PhysicsRaycastHitData({
    required this.shapeId,
    required this.point,
    required this.normal,
    required this.distance,
    required this.fraction,
  });
}
