import 'package:flutter/painting.dart';
import 'package:goo2d/goo2d.dart';

class Collision {
  final Collider collider;
  final Collider otherCollider;
  final GameObject gameObject;
  final Rigidbody? rigidbody;
  final Offset contactPoint;
  final Offset normal;
  final double impulse;
  const Collision({
    required this.collider,
    required this.otherCollider,
    required this.gameObject,
    this.rigidbody,
    required this.contactPoint,
    required this.normal,
    required this.impulse,
  });
}
