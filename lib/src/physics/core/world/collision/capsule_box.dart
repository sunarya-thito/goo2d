import 'package:goo2d/src/physics/core/physics_body.dart';
import 'package:goo2d/src/physics/core/physics_shape.dart';
import 'package:goo2d/src/physics/core/physics_contact.dart';
import 'package:goo2d/src/physics/core/world/collision/utils.dart';
import 'package:goo2d/src/physics/core/world/collision/capsule_polygon.dart';

/// Checks for collision between a capsule and a box.
ContactManifold? checkCapsuleBox(
  PhysicsCapsule sA,
  PhysicsBody bA,
  PhysicsBox sB,
  PhysicsBody bB,
) {
  return checkCapsulePolygon(sA, bA, boxToPolygon(sB, bB), bB);
}
