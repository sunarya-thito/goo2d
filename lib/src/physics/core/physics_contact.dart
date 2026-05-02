import 'package:flutter/painting.dart';

class ContactManifold {
  final Offset normal;
  final double depth;
  final Offset contactPoint;
  ContactManifold({
    required this.normal,
    required this.depth,
    required this.contactPoint,
  });
}

class PhysicsContact {
  final int shapeAId;
  final int shapeBId;
  final ContactManifold manifold;
  final double impulse;
  PhysicsContact({
    required this.shapeAId,
    required this.shapeBId,
    required this.manifold,
    this.impulse = 0.0,
  });
}

class StepResult {
  final List<PhysicsContact> contacts;
  StepResult({required this.contacts});
}
