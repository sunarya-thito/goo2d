import 'dart:math' as math;
import 'package:flutter/painting.dart';
import 'package:goo2d/src/physics/core/physics_body.dart';
import 'package:goo2d/src/physics/core/physics_shape.dart';
import 'package:goo2d/src/physics/core/physics_contact.dart';
import 'package:goo2d/src/physics/core/world/collision/utils.dart';

/// Checks for collision between a circle and an oriented box.
ContactManifold? checkCircleBox(
  PhysicsCircle sA,
  PhysicsBody bA,
  PhysicsBox sB,
  PhysicsBody bB,
) {
  final center = getTransformedPoint(sA.localOffset, bA);
  final boxPos = getTransformedPoint(sB.localOffset, bB);

  final relative = center - boxPos;
  final cos = math.cos(-bB.rotation);
  final sin = math.sin(-bB.rotation);
  final localCenter = Offset(
    relative.dx * cos - relative.dy * sin,
    relative.dx * sin + relative.dy * cos,
  );

  final half = Offset(sB.size.width / 2, sB.size.height / 2);

  final closest = Offset(
    localCenter.dx.clamp(-half.dx, half.dx),
    localCenter.dy.clamp(-half.dy, half.dy),
  );

  final localDelta = closest - localCenter;
  final distSq = localDelta.distanceSquared;

  if (distSq > sA.radius * sA.radius && distSq > 0) return null;

  Offset worldNormal;
  double depth;
  Offset contactPoint;

  if (distSq == 0) {
    final dX = localCenter.dx.abs() - half.dx;
    final dY = localCenter.dy.abs() - half.dy;
    if (dX > dY) {
      final nx = localCenter.dx > 0 ? 1.0 : -1.0;
      worldNormal = Offset(
        nx * math.cos(bB.rotation),
        nx * math.sin(bB.rotation),
      );
      depth = sA.radius - dX;
    } else {
      final ny = localCenter.dy > 0 ? 1.0 : -1.0;
      worldNormal = Offset(
        -ny * math.sin(bB.rotation),
        ny * math.cos(bB.rotation),
      );
      depth = sA.radius - dY;
    }
    contactPoint = center + worldNormal * sA.radius;
  } else {
    final dist = math.sqrt(distSq);
    final localNormal = localDelta / dist;
    worldNormal = Offset(
      localNormal.dx * math.cos(bB.rotation) -
          localNormal.dy * math.sin(bB.rotation),
      localNormal.dx * math.sin(bB.rotation) +
          localNormal.dy * math.cos(bB.rotation),
    );
    depth = sA.radius - dist;
    contactPoint =
        boxPos +
        Offset(
          closest.dx * math.cos(bB.rotation) -
              closest.dy * math.sin(bB.rotation),
          closest.dx * math.sin(bB.rotation) +
              closest.dy * math.cos(bB.rotation),
        );
  }

  return ContactManifold(
    normal: worldNormal * -1.0,
    depth: depth,
    contactPoint: contactPoint,
  );
}
