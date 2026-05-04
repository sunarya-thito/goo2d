/// Contact point result data (pure value type, no component handles).
import 'package:vector_math/vector_math_64.dart';

class ContactPointData {
  final Vector2 point;
  final Vector2 normal;
  final Vector2 relativeVelocity;
  final double separation;
  final double normalImpulse;
  final double tangentImpulse;
  final int colliderHandle;
  final int otherColliderHandle;

  const ContactPointData({
    required this.point,
    required this.normal,
    required this.relativeVelocity,
    required this.separation,
    required this.normalImpulse,
    required this.tangentImpulse,
    required this.colliderHandle,
    required this.otherColliderHandle,
  });
}
