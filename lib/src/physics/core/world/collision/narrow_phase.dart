import 'package:goo2d/src/physics/core/physics_body.dart';
import 'package:goo2d/src/physics/core/physics_shape.dart';
import 'package:goo2d/src/physics/core/physics_contact.dart';
import 'package:goo2d/src/physics/core/world/collision/utils.dart';
import 'package:goo2d/src/physics/core/world/collision/circle_circle.dart';
import 'package:goo2d/src/physics/core/world/collision/box_box.dart';
import 'package:goo2d/src/physics/core/world/collision/circle_box.dart';
import 'package:goo2d/src/physics/core/world/collision/polygon_polygon.dart';
import 'package:goo2d/src/physics/core/world/collision/circle_polygon.dart';
import 'package:goo2d/src/physics/core/world/collision/capsule_circle.dart';
import 'package:goo2d/src/physics/core/world/collision/capsule_capsule.dart';
import 'package:goo2d/src/physics/core/world/collision/capsule_box.dart';
import 'package:goo2d/src/physics/core/world/collision/capsule_polygon.dart';

ContactManifold? checkCollision(
  PhysicsShape sA,
  PhysicsBody bA,
  PhysicsShape sB,
  PhysicsBody bB,
) {
  if (sA is PhysicsCircle && sB is PhysicsCircle) {
    return checkCircleCircle(sA, bA, sB, bB);
  } else if (sA is PhysicsBox && sB is PhysicsBox) {
    return checkBoxBox(sA, bA, sB, bB);
  } else if (sA is PhysicsCircle && sB is PhysicsBox) {
    return checkCircleBox(sA, bA, sB, bB);
  } else if (sA is PhysicsBox && sB is PhysicsCircle) {
    return flipManifold(checkCircleBox(sB, bB, sA, bA));
  } else if (sA is PhysicsPolygon && sB is PhysicsPolygon) {
    return checkPolygonPolygon(sA, bA, sB, bB);
  } else if (sA is PhysicsCircle && sB is PhysicsPolygon) {
    return checkCirclePolygon(sA, bA, sB, bB);
  } else if (sA is PhysicsPolygon && sB is PhysicsCircle) {
    return flipManifold(checkCirclePolygon(sB, bB, sA, bA));
  } else if (sA is PhysicsBox && sB is PhysicsPolygon) {
    return checkPolygonPolygon(boxToPolygon(sA, bA), bA, sB, bB);
  } else if (sA is PhysicsPolygon && sB is PhysicsBox) {
    return checkPolygonPolygon(sA, bA, boxToPolygon(sB, bB), bB);
  } else if (sA is PhysicsCapsule && sB is PhysicsCapsule) {
    return checkCapsuleCapsule(sA, bA, sB, bB);
  } else if (sA is PhysicsCapsule && sB is PhysicsCircle) {
    return checkCapsuleCircle(sA, bA, sB, bB);
  } else if (sA is PhysicsCircle && sB is PhysicsCapsule) {
    return flipManifold(checkCapsuleCircle(sB, bB, sA, bA));
  } else if (sA is PhysicsCapsule && sB is PhysicsBox) {
    return checkCapsuleBox(sA, bA, sB, bB);
  } else if (sA is PhysicsBox && sB is PhysicsCapsule) {
    return flipManifold(checkCapsuleBox(sB, bB, sA, bA));
  } else if (sA is PhysicsCapsule && sB is PhysicsPolygon) {
    return checkCapsulePolygon(sA, bA, sB, bB);
  } else if (sA is PhysicsPolygon && sB is PhysicsCapsule) {
    return flipManifold(checkCapsulePolygon(sB, bB, sA, bA));
  }
  return null;
}
