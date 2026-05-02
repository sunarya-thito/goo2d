import 'package:flutter/painting.dart';
import 'package:goo2d/src/physics/components/collider.dart';

class RaycastHit {
  final Collider collider;
  final Offset point;
  final Offset normal;
  final double distance;
  final double fraction;
  RaycastHit({
    required this.collider,
    required this.point,
    required this.normal,
    required this.distance,
    required this.fraction,
  });
}
