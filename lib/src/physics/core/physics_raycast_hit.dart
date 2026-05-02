import 'package:flutter/painting.dart';

class PhysicsRaycastHit {
  final int shapeId;
  final Offset point;
  final Offset normal;
  final double distance;
  final double fraction;
  PhysicsRaycastHit({
    required this.shapeId,
    required this.point,
    required this.normal,
    required this.distance,
    required this.fraction,
  });
}
