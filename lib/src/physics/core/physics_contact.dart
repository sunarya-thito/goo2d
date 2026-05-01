import 'package:flutter/painting.dart';

/// Geometric details of a collision intersection.
/// 
/// [ContactManifold] stores the normal, penetration depth, and exact 
/// point of contact between two [PhysicsShape]s.
/// 
/// ```dart
/// final manifold = ContactManifold(normal: Offset(0,1), depth: 0.5, contactPoint: Offset(10,10));
/// ```
class ContactManifold {
  /// The unit vector pointing from shape A to shape B.
  /// 
  /// Defines the direction of the separation force required to resolve 
  /// the collision.
  final Offset normal;

  /// The amount of overlap between the two shapes.
  /// 
  /// Used for positional correction to push the shapes apart.
  final double depth;

  /// The world-space position where the collision occurred.
  /// 
  /// Useful for positioning impact particles or sound sources.
  final Offset contactPoint;

  /// Creates a [ContactManifold] with specific intersection data.
  /// 
  /// * [normal]: The collision normal vector.
  /// * [depth]: The penetration distance.
  /// * [contactPoint]: The world-space hit point.
  ContactManifold({
    required this.normal,
    required this.depth,
    required this.contactPoint,
  });
}

/// Represents a persistent interaction between two colliding shapes.
/// 
/// [PhysicsContact] tracks the [ContactManifold] and the accumulated 
/// impulse applied during the last resolution step.
/// 
/// ```dart
/// final contact = PhysicsContact(shapeAId: 1, shapeBId: 2, manifold: manifold);
/// ```
class PhysicsContact {
  /// The ID of the first shape in the contact pair.
  /// 
  /// Always corresponds to the body that the [manifold] normal points away from.
  final int shapeAId;

  /// The ID of the second shape in the contact pair.
  /// 
  /// Corresponds to the body being pushed along the [manifold] normal.
  final int shapeBId;

  /// The detailed geometry of the intersection.
  /// 
  /// Used by the solver to calculate resolution impulses.
  final ContactManifold manifold;

  /// The total impulse applied during the last resolution.
  /// 
  /// Can be used to determine the intensity of the collision for gameplay logic.
  final double impulse;

  /// Creates a [PhysicsContact] between two shapes.
  /// 
  /// * [shapeAId]: ID of the first shape.
  /// * [shapeBId]: ID of the second shape.
  /// * [manifold]: Geometric collision details.
  /// * [impulse]: Initial or accumulated impulse.
  PhysicsContact({
    required this.shapeAId,
    required this.shapeBId,
    required this.manifold,
    this.impulse = 0.0,
  });
}

/// The result of a single simulation step in the [PhysicsWorld].
/// 
/// [StepResult] contains the list of all [PhysicsContact]s that were 
/// processed during the integration.
/// 
/// ```dart
/// final result = world.step(1/60);
/// print(result.contacts.length);
/// ```
class StepResult {
  /// The list of active contacts resolved in this step.
  /// 
  /// Provides insight into which objects are currently touching.
  final List<PhysicsContact> contacts;

  /// Creates a [StepResult] with the provided [contacts].
  /// 
  /// * [contacts]: The list of collisions processed.
  StepResult({required this.contacts});
}
