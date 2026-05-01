import 'package:flutter/painting.dart';

/// Data returned from a physics raycast operation.
/// 
/// Contains information about where and how a ray intersected 
/// with a [PhysicsShape] in the world.
/// 
/// ```dart
/// final hit = world.raycast(origin, dir, 100);
/// if (hit != null) print(hit.point);
/// ```
class PhysicsRaycastHit {
  /// The ID of the shape that was hit.
  /// 
  /// Allows identification of the specific object the ray intersected.
  final int shapeId;

  /// The world-space point of intersection.
  /// 
  /// Useful for positioning impact effects or particles.
  final Offset point;

  /// The surface normal at the point of intersection.
  /// 
  /// Used for calculating reflection vectors or aligning decals.
  final Offset normal;

  /// The distance from the ray origin to the intersection point.
  /// 
  /// Helpful for sorting hits by proximity.
  final double distance;

  /// The distance expressed as a fraction of the ray's maximum length.
  /// 
  /// Range is [0.0, 1.0].
  final double fraction;

  /// Creates a [PhysicsRaycastHit] with intersection details.
  /// 
  /// * [shapeId]: ID of the intersected shape.
  /// * [point]: World-space hit position.
  /// * [normal]: Surface normal at hit.
  /// * [distance]: Distance from origin.
  /// * [fraction]: Percentage of ray length.
  PhysicsRaycastHit({
    required this.shapeId,
    required this.point,
    required this.normal,
    required this.distance,
    required this.fraction,
  });
}
