/// Raycast hit result data (pure value type, no component handles).
///
/// This is the cross-boundary data representation used by both
/// [DirectPhysicsWorker] and [IsolatePhysicsWorker].
import 'package:vector_math/vector_math_64.dart';

class RaycastHitData {
  final Vector2 point;
  final Vector2 normal;
  final Vector2 centroid;
  final double distance;
  final double fraction;
  final int colliderHandle;
  final int bodyHandle;

  const RaycastHitData({
    required this.point,
    required this.normal,
    required this.centroid,
    required this.distance,
    required this.fraction,
    required this.colliderHandle,
    required this.bodyHandle,
  });
}
