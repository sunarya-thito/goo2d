import 'package:flutter/painting.dart';
import 'package:goo2d/src/physics/components/collider.dart';

/// Information about a raycast intersection.
/// 
/// [RaycastHit] contains the point of contact, the surface normal, and the 
/// distance from the origin. It is returned by [PhysicsWorld.raycast].
/// 
/// ```dart
/// final hit = world.raycast(origin, direction);
/// if (hit != null) {
///   print('Hit ${hit.collider.gameObject.name} at ${hit.point}');
/// }
/// ```
class RaycastHit {
  /// The collider that was hit.
  /// 
  /// Use this to access the [GameObject] or other components of the target.
  final Collider collider;
  
  /// The world-space position of the intersection.
  /// 
  /// This is the exact coordinate where the ray intersected the collider surface.
  final Offset point;
  
  /// The surface normal at the hit point.
  /// 
  /// The normal vector points away from the surface and can be used for 
  /// calculating bounce directions or placing decals.
  final Offset normal;
  
  /// The absolute distance from the ray origin to the hit point.
  /// 
  /// This value is measured in world units along the ray's path.
  final double distance;
  
  /// The relative fraction (0.0 to 1.0) along the ray's maximum distance.
  /// 
  /// Useful for determining which of multiple hits is closer without 
  /// comparing absolute distances.
  final double fraction;

  /// Creates a [RaycastHit] data container.
  /// 
  /// * [collider]: The shape that was hit.
  /// * [point]: World-space hit position.
  /// * [normal]: Surface normal vector.
  /// * [distance]: Distance from origin.
  /// * [fraction]: Normalized distance (0-1).
  RaycastHit({
    required this.collider,
    required this.point,
    required this.normal,
    required this.distance,
    required this.fraction,
  });
}
