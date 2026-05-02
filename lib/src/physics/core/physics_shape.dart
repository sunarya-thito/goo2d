import 'package:flutter/painting.dart';
import 'package:goo2d/src/physics/core/physics_body.dart';

abstract class PhysicsShape {
  int id = 0;
  int bodyId = 0;
  Offset localOffset = Offset.zero;
  double localRotation = 0.0;
  bool isTrigger = false;
  double bounciness = 0.0;
  double friction = 0.4;
  bool isOneWay = false;
  double oneWayAngle = 0.0;
  double oneWayArc = 3.141592653589793; // math.pi
  PhysicsBody? _body;
  PhysicsBody? get body => _body;
  set body(PhysicsBody? value) {
    if (_body == value) return;
    _body?.shapes.remove(this);
    _body = value;
    if (value != null) {
      value.shapes.add(this);
      bodyId = value.id;
    }
  }

  PhysicsShape();
}

class PhysicsBox extends PhysicsShape {
  final Size size;
  PhysicsBox(double w, double h) : size = Size(w, h);
}

class PhysicsCircle extends PhysicsShape {
  final double radius;
  PhysicsCircle(this.radius);
}

enum CapsuleDirection { vertical, horizontal }

class PhysicsCapsule extends PhysicsShape {
  final double radius;
  final double height;
  final CapsuleDirection direction;
  PhysicsCapsule(this.radius, this.height, this.direction);
}

class PhysicsPolygon extends PhysicsShape {
  final List<Offset> vertices;
  PhysicsPolygon(this.vertices);
}
