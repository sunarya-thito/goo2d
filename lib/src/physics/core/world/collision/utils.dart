import 'dart:math' as math;
import 'package:flutter/painting.dart';
import 'package:goo2d/src/physics/core/physics_body.dart';
import 'package:goo2d/src/physics/core/physics_shape.dart';
import 'package:goo2d/src/physics/core/physics_contact.dart';

ContactManifold? flipManifold(ContactManifold? manifold) {
  if (manifold == null) return null;
  return ContactManifold(
    normal: manifold.normal * -1.0,
    depth: manifold.depth,
    contactPoint: manifold.contactPoint,
  );
}

PhysicsPolygon boxToPolygon(PhysicsBox box, PhysicsBody body) {
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

List<Offset> getTransformedVertices(PhysicsPolygon poly, PhysicsBody body) {
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

List<Offset> getPolygonAxes(List<Offset> verts) {
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

List<double> projectPolygon(List<Offset> verts, Offset axis) {
  double min = double.infinity;
  double max = -double.infinity;
  for (final v in verts) {
    final proj = v.dx * axis.dx + v.dy * axis.dy;
    if (proj < min) min = proj;
    if (proj > max) max = proj;
  }
  return [min, max];
}

Offset getPolygonCenter(List<Offset> verts) {
  Offset sum = Offset.zero;
  for (final v in verts) {
    sum += v;
  }
  return sum / verts.length.toDouble();
}

Offset getClosestVertex(Offset point, List<Offset> verts) {
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

List<Offset> getBoxAxes(double rotation) {
  final cos = math.cos(rotation);
  final sin = math.sin(rotation);
  return [Offset(cos, sin), Offset(-sin, cos)];
}

double getOverlap(
  Offset posA,
  List<Offset> axesA,
  List<double> halfA,
  Offset posB,
  List<Offset> axesB,
  List<double> halfB,
  Offset axis,
) {
  final projA = projectBox(posA, axesA, halfA, axis);
  final projB = projectBox(posB, axesB, halfB, axis);

  final minA = projA[0];
  final maxA = projA[1];
  final minB = projB[0];
  final maxB = projB[1];

  if (maxA < minB || maxB < minA) return 0;
  return math.min(maxA, maxB) - math.max(minA, minB);
}

List<double> projectBox(
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

Offset getTransformedPoint(Offset local, PhysicsBody body) {
  if (local == Offset.zero) return body.position;
  final cos = math.cos(body.rotation);
  final sin = math.sin(body.rotation);
  return body.position +
      Offset(
        local.dx * cos - local.dy * sin,
        local.dx * sin + local.dy * cos,
      );
}

List<Offset> getCapsuleSegment(PhysicsCapsule s, PhysicsBody b) {
  double capOffset = (s.height / 2) - s.radius;
  if (capOffset < 0) capOffset = 0;

  final localA = s.direction == CapsuleDirection.vertical
      ? s.localOffset + Offset(0, -capOffset)
      : s.localOffset + Offset(-capOffset, 0);
  final localB = s.direction == CapsuleDirection.vertical
      ? s.localOffset + Offset(0, capOffset)
      : s.localOffset + Offset(capOffset, 0);

  return [getTransformedPoint(localA, b), getTransformedPoint(localB, b)];
}

Offset getClosestPointOnSegment(Offset p, Offset a, Offset b) {
  final ab = b - a;
  final distSq = ab.distanceSquared;
  if (distSq == 0) return a;

  final ap = p - a;
  double t = (ap.dx * ab.dx + ap.dy * ab.dy) / distSq;
  t = t.clamp(0.0, 1.0);
  return a + ab * t;
}

List<Offset> getClosestPointsBetweenSegments(
  Offset p1,
  Offset p2,
  Offset q1,
  Offset q2,
) {
  final d1 = p2 - p1;
  final d2 = q2 - q1;
  final r = p1 - q1;
  final a = d1.distanceSquared;
  final e = d2.distanceSquared;
  final f = d2.dx * r.dx + d2.dy * r.dy;

  double s = 0.0;
  double t = 0.0;

  if (a <= 1e-6 && e <= 1e-6) {
    s = 0.0;
    t = 0.0;
  } else if (a <= 1e-6) {
    s = 0.0;
    t = (f / e).clamp(0.0, 1.0);
  } else {
    final c = d1.dx * r.dx + d1.dy * r.dy;
    if (e <= 1e-6) {
      t = 0.0;
      s = (-c / a).clamp(0.0, 1.0);
    } else {
      final b = d1.dx * d2.dx + d1.dy * d2.dy;
      final denom = a * e - b * b;

      if (denom != 0) {
        s = ((b * f - c * e) / denom).clamp(0.0, 1.0);
      } else {
        s = 0.0;
      }

      t = (b * s + f) / e;
      if (t < 0.0) {
        t = 0.0;
        s = (-c / a).clamp(0.0, 1.0);
      } else if (t > 1.0) {
        t = 1.0;
        s = ((b - c) / a).clamp(0.0, 1.0);
      }
    }
  }

  return [p1 + d1 * s, q1 + d2 * t];
}
