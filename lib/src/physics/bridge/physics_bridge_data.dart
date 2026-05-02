import 'package:flutter/painting.dart';

class PhysicsContactData {
  final int shapeAId;
  final int shapeBId;
  final Offset contactPoint;
  final Offset normal;
  final double depth;
  final double impulse;
  PhysicsContactData({
    required this.shapeAId,
    required this.shapeBId,
    required this.contactPoint,
    required this.normal,
    required this.depth,
    required this.impulse,
  });
}

class PhysicsStepResult {
  final List<PhysicsContactData> contacts;
  final Map<int, PhysicsBodyState> dynamicBodies;
  PhysicsStepResult({
    required this.contacts,
    required this.dynamicBodies,
  });
}

class PhysicsBodyState {
  final Offset position;
  final double rotation;
  final Offset velocity;
  final double angularVelocity;
  PhysicsBodyState({
    required this.position,
    required this.rotation,
    required this.velocity,
    required this.angularVelocity,
  });
}

class PhysicsTransformSync {
  final Offset position;
  final double rotation;
  PhysicsTransformSync(this.position, this.rotation);
}

class PhysicsRaycastHitData {
  final int shapeId;
  final Offset point;
  final Offset normal;
  final double distance;
  final double fraction;
  PhysicsRaycastHitData({
    required this.shapeId,
    required this.point,
    required this.normal,
    required this.distance,
    required this.fraction,
  });
}
