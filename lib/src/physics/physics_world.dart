import 'dart:math' as math;
import 'package:flutter/painting.dart';

class PhysicsBody {
  final int id;
  int type; // 0: dynamic, 1: kinematic, 2: static

  Offset position = Offset.zero;
  double rotation = 0.0;
  Offset velocity = Offset.zero;
  double angularVelocity = 0.0;

  double mass = 1.0;
  double invMass = 1.0;
  double inertia = 1.0;
  double invInertia = 1.0;

  double gravityScale = 1.0;
  double drag = 0.0;
  double angularDrag = 0.05;

  bool _freezeRotation = false;
  bool get freezeRotation => _freezeRotation;
  set freezeRotation(bool value) {
    _freezeRotation = value;
    setInertia(inertia);
  }

  Offset force = Offset.zero;
  double torque = 0.0;

  final List<PhysicsShape> shapes = [];

  PhysicsBody({required this.id, this.type = 0});

  void applyForce(Offset f) {
    if (type != 0) return;
    force += f;
  }

  void applyImpulse(Offset j) {
    if (type != 0) return;
    velocity += j * invMass;
  }

  void applyTorque(double t) {
    if (type != 0) return;
    torque += t;
  }

  void applyAngularImpulse(double j) {
    if (type != 0) return;
    angularVelocity += j * invInertia;
  }

  void setMass(double m) {
    mass = m;
    invMass = m > 0 ? 1.0 / m : 0.0;
  }

  void setInertia(double i) {
    inertia = i;
    invInertia = i > 0 && !freezeRotation ? 1.0 / i : 0.0;
  }

  void integrate(double dt, Offset gravity) {
    if (type != 0) return; // Only dynamic bodies integrate

    // Apply accumulated forces
    velocity += (force * invMass + gravity * gravityScale) * dt;
    angularVelocity += torque * invInertia * dt;

    // Apply drag
    velocity *= (1.0 - drag * dt);
    angularVelocity *= (1.0 - angularDrag * dt);

    // Apply velocity
    position += velocity * dt;
    rotation += angularVelocity * dt;

    // Reset forces
    force = Offset.zero;
    torque = 0.0;
  }
}

abstract class PhysicsShape {
  int id = 0;
  int bodyId = 0;
  Offset localOffset = Offset.zero;
  double localRotation = 0.0;
  bool isTrigger = false;
  double bounciness = 0.0;
  double friction = 0.4;

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

class PhysicsCapsule extends PhysicsShape {
  final double radius;
  final double height;
  final bool isVertical;
  PhysicsCapsule(this.radius, this.height, this.isVertical);
}

class PhysicsPolygon extends PhysicsShape {
  final List<Offset> vertices;
  PhysicsPolygon(this.vertices);
}

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

class PhysicsWorld {
  final Map<int, PhysicsBody> bodies = {};

  // Helper to get all shapes across all bodies
  Iterable<PhysicsShape> get allShapes => bodies.values.expand((b) => b.shapes);
  Offset gravity = const Offset(0, 980); // Default gravity (pixels/s^2)

  /// Contacts detected in the current step.
  final List<PhysicsContact> activeContacts = [];

  PhysicsRaycastHit? raycast(
    Offset origin,
    Offset direction,
    double maxDistance,
  ) {
    PhysicsRaycastHit? closestHit;

    for (final shape in allShapes) {
      final body = bodies[shape.bodyId]!;
      PhysicsRaycastHit? hit;

      if (shape is PhysicsCircle) {
        hit = _raycastCircle(shape, body, origin, direction, maxDistance);
      } else if (shape is PhysicsBox) {
        hit = _raycastPolygon(
          _boxToPolygon(shape, body),
          body,
          origin,
          direction,
          maxDistance,
        );
      } else if (shape is PhysicsPolygon) {
        hit = _raycastPolygon(shape, body, origin, direction, maxDistance);
      }

      if (hit != null) {
        if (closestHit == null || hit.distance < closestHit.distance) {
          closestHit = hit;
        }
      }
    }

    return closestHit;
  }

  PhysicsRaycastHit? _raycastCircle(
    PhysicsCircle circle,
    PhysicsBody body,
    Offset origin,
    Offset direction,
    double maxDistance,
  ) {
    final center = _getTransformedPoint(circle.localOffset, body);
    final L = center - origin;
    final tca = L.dx * direction.dx + L.dy * direction.dy;
    if (tca < 0) return null;

    final d2 = L.dx * L.dx + L.dy * L.dy - tca * tca;
    final r2 = circle.radius * circle.radius;
    if (d2 > r2) return null;

    final thc = math.sqrt(r2 - d2);
    final t0 = tca - thc;

    if (t0 < 0 || t0 > maxDistance) return null;

    final point = origin + direction * t0;
    final normal = (point - center) / circle.radius;

    return PhysicsRaycastHit(
      shapeId: circle.id,
      point: point,
      normal: normal,
      distance: t0,
      fraction: t0 / maxDistance,
    );
  }

  PhysicsRaycastHit? _raycastPolygon(
    PhysicsPolygon poly,
    PhysicsBody body,
    Offset origin,
    Offset direction,
    double maxDistance,
  ) {
    final verts = _getTransformedVertices(poly, body);
    double minT = double.infinity;
    Offset bestNormal = Offset.zero;

    for (int i = 0; i < verts.length; i++) {
      final p1 = verts[i];
      final p2 = verts[(i + 1) % verts.length];

      // Ray-Segment intersection
      final v1 = origin - p1;
      final v2 = p2 - p1;
      final v3 = Offset(-direction.dy, direction.dx);

      final dot = v2.dx * v3.dx + v2.dy * v3.dy;
      if (dot.abs() < 0.000001) continue;

      final t1 = (v2.dx * v1.dy - v2.dy * v1.dx) / dot;
      final t2 = (v1.dx * v3.dx + v1.dy * v3.dy) / dot;

      if (t1 >= 0 && t1 <= maxDistance && t2 >= 0 && t2 <= 1) {
        if (t1 < minT) {
          minT = t1;
          final edge = p2 - p1;
          final dist = edge.distance;
          if (dist > 0.000001) {
            bestNormal = Offset(-edge.dy, edge.dx) / dist;
            // Ensure normal points away from ray
            if (bestNormal.dx * direction.dx + bestNormal.dy * direction.dy > 0) {
              bestNormal *= -1.0;
            }
          }
        }
      }
    }

    if (minT == double.infinity) return null;

    return PhysicsRaycastHit(
      shapeId: poly.id,
      point: origin + direction * minT,
      normal: bestNormal,
      distance: minT,
      fraction: minT / maxDistance,
    );
  }

  StepResult step(double dt) {
    activeContacts.clear();

    // 1. Integration
    for (final body in bodies.values) {
      body.integrate(dt, gravity);
    }

    // 2. Collision Detection & Resolution
    _resolveCollisions(dt);

    return StepResult(contacts: List.from(activeContacts));
  }

  void _resolveCollisions(double dt) {
    final allShapesList = allShapes.toList();
    for (int i = 0; i < allShapesList.length; i++) {
      for (int j = i + 1; j < allShapesList.length; j++) {
        final sA = allShapesList[i];
        final sB = allShapesList[j];

        final bA = bodies[sA.bodyId]!;
        final bB = bodies[sB.bodyId]!;

        // Check if we should skip this pair
        // We only resolve physical collisions if at least one body is dynamic.
        // However, we still want to detect TRIGGERS between any bodies (except static-static).
        // Allow detection between all non-static bodies.
        // Even if both are kinematic, we want to detect the overlap for events.
        // Static-Static never collide.
        if (bA.type == 2 && bB.type == 2) continue;
        if (bA == bB) continue; // Same body

        final manifold = _checkCollision(sA, bA, sB, bB);
        if (manifold != null) {
          double impulseValue = 0.0;
          if (!sA.isTrigger && !sB.isTrigger) {
            impulseValue = _applyImpulse(bA, bB, sA, sB, manifold);
          }

          activeContacts.add(
            PhysicsContact(
              shapeAId: sA.id,
              shapeBId: sB.id,
              manifold: manifold,
              impulse: impulseValue,
            ),
          );
        }
      }
    }
  }

  ContactManifold? _checkCollision(
    PhysicsShape sA,
    PhysicsBody bA,
    PhysicsShape sB,
    PhysicsBody bB,
  ) {
    if (sA is PhysicsCircle && sB is PhysicsCircle) {
      return _checkCircleCircle(sA, bA, sB, bB);
    } else if (sA is PhysicsBox && sB is PhysicsBox) {
      return _checkBoxBox(sA, bA, sB, bB);
    } else if (sA is PhysicsCircle && sB is PhysicsBox) {
      return _checkCircleBox(sA, bA, sB, bB);
    } else if (sA is PhysicsBox && sB is PhysicsCircle) {
      return _flipManifold(_checkCircleBox(sB, bB, sA, bA));
    } else if (sA is PhysicsPolygon && sB is PhysicsPolygon) {
      return _checkPolygonPolygon(sA, bA, sB, bB);
    } else if (sA is PhysicsCircle && sB is PhysicsPolygon) {
      return _checkCirclePolygon(sA, bA, sB, bB);
    } else if (sA is PhysicsPolygon && sB is PhysicsCircle) {
      return _flipManifold(_checkCirclePolygon(sB, bB, sA, bA));
    } else if (sA is PhysicsBox && sB is PhysicsPolygon) {
      return _checkPolygonPolygon(_boxToPolygon(sA, bA), bA, sB, bB);
    } else if (sA is PhysicsPolygon && sB is PhysicsBox) {
      return _checkPolygonPolygon(sA, bA, _boxToPolygon(sB, bB), bB);
    }
    return null;
  }

  ContactManifold? _flipManifold(ContactManifold? manifold) {
    if (manifold == null) return null;
    return ContactManifold(
      normal: manifold.normal * -1.0,
      depth: manifold.depth,
      contactPoint: manifold.contactPoint,
    );
  }

  PhysicsPolygon _boxToPolygon(PhysicsBox box, PhysicsBody body) {
    final halfW = box.size.width / 2;
    final halfH = box.size.height / 2;
    return PhysicsPolygon([
        Offset(-halfW, -halfH),
        Offset(halfW, -halfH),
        Offset(halfW, halfH),
        Offset(-halfW, halfH),
      ])
      ..id = box.id
      ..bodyId = box.bodyId
      ..localOffset = box.localOffset;
  }

  ContactManifold? _checkPolygonPolygon(
    PhysicsPolygon sA,
    PhysicsBody bA,
    PhysicsPolygon sB,
    PhysicsBody bB,
  ) {
    final vertsA = _getTransformedVertices(sA, bA);
    final vertsB = _getTransformedVertices(sB, bB);

    double minOverlap = double.infinity;
    Offset bestAxis = Offset.zero;

    final axes = [..._getPolygonAxes(vertsA), ..._getPolygonAxes(vertsB)];
    for (final axis in axes) {
      final projA = _projectPolygon(vertsA, axis);
      final projB = _projectPolygon(vertsB, axis);

      final overlap =
          math.min(projA[1], projB[1]) - math.max(projA[0], projB[0]);
      if (overlap <= 0) return null;

      if (overlap < minOverlap) {
        minOverlap = overlap;
        bestAxis = axis;
      }
    }

    Offset normal = bestAxis;
    final centerA = _getPolygonCenter(vertsA);
    final centerB = _getPolygonCenter(vertsB);
    if ((centerB - centerA).dx * normal.dx +
            (centerB - centerA).dy * normal.dy <
        0) {
      normal *= -1.0;
    }

    return ContactManifold(
      normal: normal,
      depth: minOverlap,
      contactPoint: centerA + normal * (minOverlap / 2), // Rough approximation
    );
  }

  ContactManifold? _checkCirclePolygon(
    PhysicsCircle sA,
    PhysicsBody bA,
    PhysicsPolygon sB,
    PhysicsBody bB,
  ) {
    final center = _getTransformedPoint(sA.localOffset, bA);
    final verts = _getTransformedVertices(sB, bB);

    double minOverlap = double.infinity;
    Offset bestAxis = Offset.zero;

    final axes = _getPolygonAxes(verts);
    // Also check axis from closest vertex to circle center
    final closestVert = _getClosestVertex(center, verts);
    final circleAxis = (center - closestVert);
    if (circleAxis.distanceSquared > 0) {
      axes.add(circleAxis / circleAxis.distance);
    }

    for (final axis in axes) {
      final projA = [
        center.dx * axis.dx + center.dy * axis.dy - sA.radius,
        center.dx * axis.dx + center.dy * axis.dy + sA.radius,
      ];
      final projB = _projectPolygon(verts, axis);

      final overlap =
          math.min(projA[1], projB[1]) - math.max(projA[0], projB[0]);
      if (overlap <= 0) return null;

      if (overlap < minOverlap) {
        minOverlap = overlap;
        bestAxis = axis;
      }
    }

    Offset normal = bestAxis;
    final centerB = _getPolygonCenter(verts);
    if ((centerB - center).dx * normal.dx + (centerB - center).dy * normal.dy <
        0) {
      normal *= -1.0;
    }

    return ContactManifold(
      normal: normal,
      depth: minOverlap,
      contactPoint: center + normal * (sA.radius - minOverlap / 2),
    );
  }

  List<Offset> _getTransformedVertices(PhysicsPolygon poly, PhysicsBody body) {
    final cos = math.cos(body.rotation);
    final sin = math.sin(body.rotation);
    return poly.vertices.map((v) {
      final local = v + poly.localOffset;
      return body.position +
          Offset(
            local.dx * cos - local.dy * sin,
            local.dx * sin + local.dy * cos,
          );
    }).toList();
  }

  List<Offset> _getPolygonAxes(List<Offset> verts) {
    final axes = <Offset>[];
    for (int i = 0; i < verts.length; i++) {
      final p1 = verts[i];
      final p2 = verts[(i + 1) % verts.length];
      final edge = p2 - p1;
      final normal = Offset(-edge.dy, edge.dx);
      if (normal.distanceSquared > 0) {
        axes.add(normal / normal.distance);
      }
    }
    return axes;
  }

  List<double> _projectPolygon(List<Offset> verts, Offset axis) {
    double min = double.infinity;
    double max = -double.infinity;
    for (final v in verts) {
      final proj = v.dx * axis.dx + v.dy * axis.dy;
      if (proj < min) min = proj;
      if (proj > max) max = proj;
    }
    return [min, max];
  }

  Offset _getPolygonCenter(List<Offset> verts) {
    Offset sum = Offset.zero;
    for (final v in verts) {
      sum += v;
    }
    return sum / verts.length.toDouble();
  }

  Offset _getClosestVertex(Offset point, List<Offset> verts) {
    double minDist = double.infinity;
    Offset closest = verts[0];
    for (final v in verts) {
      final dist = (point - v).distanceSquared;
      if (dist < minDist) {
        minDist = dist;
        closest = v;
      }
    }
    return closest;
  }

  ContactManifold? _checkCircleCircle(
    PhysicsCircle sA,
    PhysicsBody bA,
    PhysicsCircle sB,
    PhysicsBody bB,
  ) {
    final posA = _getTransformedPoint(sA.localOffset, bA);
    final posB = _getTransformedPoint(sB.localOffset, bB);
    final delta = posB - posA;
    final distSq = delta.distanceSquared;
    final radiusSum = sA.radius + sB.radius;

    if (distSq > radiusSum * radiusSum) return null;

    final dist = math.sqrt(distSq);
    final normal = dist > 0 ? delta / dist : const Offset(0, 1);
    final depth = radiusSum - dist;

    return ContactManifold(
      normal: normal,
      depth: depth,
      contactPoint: posA + normal * sA.radius,
    );
  }

  ContactManifold? _checkBoxBox(
    PhysicsBox sA,
    PhysicsBody bA,
    PhysicsBox sB,
    PhysicsBody bB,
  ) {
    final posA = _getTransformedPoint(sA.localOffset, bA);
    final posB = _getTransformedPoint(sB.localOffset, bB);

    // Get axes for box A
    final axesA = _getBoxAxes(bA.rotation);
    final axesB = _getBoxAxes(bB.rotation);

    final halfA = [sA.size.width / 2, sA.size.height / 2];
    final halfB = [sB.size.width / 2, sB.size.height / 2];

    double minOverlap = double.infinity;
    Offset bestAxis = Offset.zero;

    final axes = [...axesA, ...axesB];
    for (final axis in axes) {
      final overlap = _getOverlap(posA, axesA, halfA, posB, axesB, halfB, axis);
      if (overlap <= 0) return null;
      if (overlap < minOverlap) {
        minOverlap = overlap;
        bestAxis = axis;
      }
    }

    // Ensure normal points from A to B
    Offset normal = bestAxis;
    if ((posB - posA).dx * normal.dx + (posB - posA).dy * normal.dy < 0) {
      normal *= -1.0;
    }

    return ContactManifold(
      normal: normal,
      depth: minOverlap,
      contactPoint:
          posA +
          normal * (halfA[0] + minOverlap / 2), // Simplified contact point
    );
  }

  List<Offset> _getBoxAxes(double rotation) {
    final cos = math.cos(rotation);
    final sin = math.sin(rotation);
    return [Offset(cos, sin), Offset(-sin, cos)];
  }

  double _getOverlap(
    Offset posA,
    List<Offset> axesA,
    List<double> halfA,
    Offset posB,
    List<Offset> axesB,
    List<double> halfB,
    Offset axis,
  ) {
    final projA = _projectBox(posA, axesA, halfA, axis);
    final projB = _projectBox(posB, axesB, halfB, axis);

    final minA = projA[0];
    final maxA = projA[1];
    final minB = projB[0];
    final maxB = projB[1];

    if (maxA < minB || maxB < minA) return 0;
    return math.min(maxA, maxB) - math.max(minA, minB);
  }

  List<double> _projectBox(
    Offset pos,
    List<Offset> axes,
    List<double> half,
    Offset axis,
  ) {
    final centerProj = pos.dx * axis.dx + pos.dy * axis.dy;
    final r =
        half[0] * (axes[0].dx * axis.dx + axes[0].dy * axis.dy).abs() +
        half[1] * (axes[1].dx * axis.dx + axes[1].dy * axis.dy).abs();
    return [centerProj - r, centerProj + r];
  }

  ContactManifold? _checkCircleBox(
    PhysicsCircle sA,
    PhysicsBody bA,
    PhysicsBox sB,
    PhysicsBody bB,
  ) {
    final center = _getTransformedPoint(sA.localOffset, bA);
    final boxPos = _getTransformedPoint(sB.localOffset, bB);

    // Transform circle center to box local space
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

    // Transform normal back to world space
    Offset worldNormal;
    double depth;
    Offset contactPoint;

    if (distSq == 0) {
      // Inside box
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

  double _applyImpulse(
    PhysicsBody bA,
    PhysicsBody bB,
    PhysicsShape sA,
    PhysicsShape sB,
    ContactManifold manifold,
  ) {
    // Vectors from center of mass to contact point
    final rA = manifold.contactPoint - bA.position;
    final rB = manifold.contactPoint - bB.position;

    // Relative velocity at contact point
    final vA =
        bA.velocity +
        Offset(-bA.angularVelocity * rA.dy, bA.angularVelocity * rA.dx);
    final vB =
        bB.velocity +
        Offset(-bB.angularVelocity * rB.dy, bB.angularVelocity * rB.dx);
    final relativeVelocity = vB - vA;

    final velocityAlongNormal =
        relativeVelocity.dx * manifold.normal.dx +
        relativeVelocity.dy * manifold.normal.dy;
    if (velocityAlongNormal > 0) return 0.0;

    final raCrossN = rA.dx * manifold.normal.dy - rA.dy * manifold.normal.dx;
    final rbCrossN = rB.dx * manifold.normal.dy - rB.dy * manifold.normal.dx;

    final invMassSum =
        bA.invMass +
        bB.invMass +
        (raCrossN * raCrossN * bA.invInertia) +
        (rbCrossN * rbCrossN * bB.invInertia);

    if (invMassSum <= 0) return 0.0;

    // Combine restitution and friction
    final e = math.max(sA.bounciness, sB.bounciness);
    final mu = math.sqrt(sA.friction * sB.friction);

    double j = -(1.0 + e) * velocityAlongNormal;
    j /= invMassSum;

    final impulse = manifold.normal * j;
    bA.velocity -= impulse * bA.invMass;
    bA.angularVelocity -= raCrossN * j * bA.invInertia;
    bB.velocity += impulse * bB.invMass;
    bB.angularVelocity += rbCrossN * j * bB.invInertia;

    // Friction
    final tangent = relativeVelocity - manifold.normal * velocityAlongNormal;
    final tangentMag = tangent.distance;
    if (tangentMag > 0.0001) {
      final t = tangent / tangentMag;
      final raCrossT = rA.dx * t.dy - rA.dy * t.dx;
      final rbCrossT = rB.dx * t.dy - rB.dy * t.dx;
      final invMassSumT =
          bA.invMass +
          bB.invMass +
          (raCrossT * raCrossT * bA.invInertia) +
          (rbCrossT * rbCrossT * bB.invInertia);

      double jt = -relativeVelocity.dx * t.dx - relativeVelocity.dy * t.dy;
      jt /= invMassSumT;

      // Coulomb's law: clamp friction to normal impulse * friction coefficient
      final maxFriction = j * mu;
      jt = jt.clamp(-maxFriction, maxFriction);

      final frictionImpulse = t * jt;
      bA.velocity -= frictionImpulse * bA.invMass;
      bA.angularVelocity -= raCrossT * jt * bA.invInertia;
      bB.velocity += frictionImpulse * bB.invMass;
      bB.angularVelocity += rbCrossT * jt * bB.invInertia;
    }

    // Positional correction
    const percent = 0.2;
    const slop = 0.01;
    final correction =
        manifold.normal *
        (math.max(manifold.depth - slop, 0.0) /
            (bA.invMass + bB.invMass) *
            percent);
    bA.position -= correction * bA.invMass;
    bB.position += correction * bB.invMass;

    return j;
  }

  Offset _getTransformedPoint(Offset local, PhysicsBody body) {
    if (local == Offset.zero) return body.position;
    final cos = math.cos(body.rotation);
    final sin = math.sin(body.rotation);
    return body.position +
        Offset(
          local.dx * cos - local.dy * sin,
          local.dx * sin + local.dy * cos,
        );
  }
}

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
