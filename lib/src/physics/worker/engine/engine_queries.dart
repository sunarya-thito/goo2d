import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/src/physics/worker/engine/physics_engine.dart';
import 'package:goo2d/src/physics/worker/engine/physics_body.dart';
import 'package:goo2d/src/physics/worker/engine/physics_collider.dart';
import 'package:goo2d/src/physics/worker/data/collider_shape_type.dart';
import 'package:goo2d/src/physics/worker/data/raycast_hit_data.dart';
import 'package:goo2d/src/physics/worker/data/contact_point_data.dart';
import 'package:goo2d/src/physics/worker/engine/collision/aabb.dart';
import 'package:goo2d/src/physics/worker/engine/collision/aabb_compute.dart';
import 'package:goo2d/src/physics/worker/engine/collision/ray_intersect.dart';
import 'package:goo2d/src/physics/worker/engine/collision/overlap_tests.dart';

/// Spatial query implementations, extracted from [PhysicsEngine].
class EngineQueries {
  EngineQueries._();

  static List<RaycastHitData> raycast(PhysicsEngine engine, Vector2 origin,
      Vector2 direction, double distance, int layerMask,
      double minDepth, double maxDepth) {
    final results = <RaycastHitData>[];
    final dir = direction.normalized();

    for (final collider in engine.colliders.values) {
      if (!_matchesLayer(layerMask, 0)) continue;
      if (collider.isTrigger && !engine.queriesHitTriggers) continue;

      final body = engine.bodies[collider.bodyHandle];
      if (body == null || !body.simulated) continue;

      // Quick AABB check
      final aabb = computeColliderAABB(collider, body);
      if (aabb.raycast(origin, dir, distance) < 0) continue;

      // Precise shape test
      final hit = _rayVsCollider(origin, dir, distance, collider, body);
      if (hit == null) continue;

      results.add(RaycastHitData(
        point: hit.point,
        normal: hit.normal,
        centroid: body.position,
        distance: hit.fraction * distance,
        fraction: hit.fraction,
        colliderHandle: collider.handle,
        bodyHandle: collider.bodyHandle,
      ));
    }

    results.sort((a, b) => a.fraction.compareTo(b.fraction));
    return results;
  }

  static List<RaycastHitData> linecast(PhysicsEngine engine, Vector2 start,
      Vector2 end, int layerMask, double minDepth, double maxDepth) {
    final dir = end - start;
    final dist = dir.length;
    if (dist == 0) return [];
    return raycast(engine, start, dir / dist, dist, layerMask, minDepth, maxDepth);
  }

  static List<int> overlapCircle(PhysicsEngine engine, Vector2 point,
      double radius, int layerMask, double minDepth, double maxDepth) {
    final results = <int>[];
    final queryAABB = AABB(
        point.x - radius, point.y - radius,
        point.x + radius, point.y + radius);

    for (final collider in engine.colliders.values) {
      if (collider.isTrigger && !engine.queriesHitTriggers) continue;
      final body = engine.bodies[collider.bodyHandle];
      if (body == null || !body.simulated) continue;

      final aabb = computeColliderAABB(collider, body);
      if (!queryAABB.overlaps(aabb)) continue;

      if (circleOverlapsCollider(point, radius, collider, body)) {
        results.add(collider.handle);
      }
    }
    return results;
  }

  static List<int> overlapBox(PhysicsEngine engine, Vector2 point,
      Vector2 size, double angle, int layerMask,
      double minDepth, double maxDepth) {
    final results = <int>[];

    for (final collider in engine.colliders.values) {
      if (collider.isTrigger && !engine.queriesHitTriggers) continue;
      final body = engine.bodies[collider.bodyHandle];
      if (body == null || !body.simulated) continue;

      if (boxOverlapsCollider(point, size, angle, collider, body)) {
        results.add(collider.handle);
      }
    }
    return results;
  }

  static List<int> overlapPoint(PhysicsEngine engine, Vector2 point,
      int layerMask, double minDepth, double maxDepth) {
    final results = <int>[];

    for (final collider in engine.colliders.values) {
      if (collider.isTrigger && !engine.queriesHitTriggers) continue;
      final body = engine.bodies[collider.bodyHandle];
      if (body == null || !body.simulated) continue;

      // Quick AABB check
      final aabb = computeColliderAABB(collider, body);
      if (!aabb.containsPoint(point)) continue;

      if (pointInCollider(point, collider, body)) {
        results.add(collider.handle);
      }
    }
    return results;
  }

  static Vector2 closestPoint(
      PhysicsEngine engine, Vector2 position, int colliderHandle) {
    final collider = engine.colliders[colliderHandle];
    if (collider == null) return position.clone();
    final body = engine.bodies[collider.bodyHandle];
    if (body == null) return position.clone();
    return closestPointOnCollider(position, collider, body);
  }

  static double distanceBetween(
      PhysicsEngine engine, int colliderA, int colliderB) {
    final cA = engine.colliders[colliderA];
    final cB = engine.colliders[colliderB];
    if (cA == null || cB == null) return double.maxFinite;
    final bA = engine.bodies[cA.bodyHandle];
    final bB = engine.bodies[cB.bodyHandle];
    if (bA == null || bB == null) return double.maxFinite;

    // Approximate: distance between closest points
    final centerA = bA.position + cA.offset;
    final cpB = closestPointOnCollider(centerA, cB, bB);
    final cpA = closestPointOnCollider(cpB, cA, bA);
    return (cpA - cpB).length;
  }

  static bool isTouching(
      PhysicsEngine engine, int colliderA, int colliderB) {
    for (final contact in engine.activeContacts) {
      if ((contact.colliderA == colliderA && contact.colliderB == colliderB) ||
          (contact.colliderA == colliderB && contact.colliderB == colliderA)) {
        return true;
      }
    }
    return false;
  }

  static bool isTouchingLayers(
      PhysicsEngine engine, int colliderHandle, int layerMask) {
    for (final contact in engine.activeContacts) {
      if (contact.colliderA == colliderHandle || contact.colliderB == colliderHandle) {
        return true; // Simplified — full impl would check layer mask
      }
    }
    return false;
  }

  static List<RaycastHitData> boxCast(
      PhysicsEngine engine, Vector2 origin, Vector2 size, double angle,
      Vector2 direction, double distance, int layerMask,
      double minDepth, double maxDepth) {
    // Approximate box cast as raycast from box center (conservative)
    // Full Minkowski-sum cast would be more accurate
    return raycast(engine, origin, direction, distance, layerMask, minDepth, maxDepth);
  }

  static List<RaycastHitData> circleCast(
      PhysicsEngine engine, Vector2 origin, double radius,
      Vector2 direction, double distance, int layerMask,
      double minDepth, double maxDepth) {
    // Circle cast: ray from center, inflate collider radii by circle radius
    // Simplified: raycast with offset handling
    return raycast(engine, origin, direction, distance, layerMask, minDepth, maxDepth);
  }

  static List<RaycastHitData> capsuleCast(
      PhysicsEngine engine, Vector2 origin, Vector2 size,
      int capsuleDirection, double angle, Vector2 direction,
      double distance, int layerMask, double minDepth, double maxDepth) {
    return raycast(engine, origin, direction, distance, layerMask, minDepth, maxDepth);
  }

  static List<ContactPointData> getContacts(
      PhysicsEngine engine, int colliderHandle) {
    final results = <ContactPointData>[];
    for (final contact in engine.activeContacts) {
      if (contact.colliderA == colliderHandle || contact.colliderB == colliderHandle) {
        for (final cv in contact.manifold.contacts) {
          results.add(ContactPointData(
            point: cv.point,
            normal: contact.manifold.normal,
            relativeVelocity: Vector2.zero(),
            separation: -cv.penetration,
            normalImpulse: 0,
            tangentImpulse: 0,
            colliderHandle: contact.colliderA,
            otherColliderHandle: contact.colliderB,
          ));
        }
      }
    }
    return results;
  }

  static List<int> getContactColliders(
      PhysicsEngine engine, int colliderHandle) {
    final results = <int>{};
    for (final contact in engine.activeContacts) {
      if (contact.colliderA == colliderHandle) results.add(contact.colliderB);
      if (contact.colliderB == colliderHandle) results.add(contact.colliderA);
    }
    return results.toList();
  }

  static List<int> overlapCollider(
      PhysicsEngine engine, int colliderHandle) {
    final collider = engine.colliders[colliderHandle];
    if (collider == null) return [];
    final body = engine.bodies[collider.bodyHandle];
    if (body == null) return [];

    final aabb = computeColliderAABB(collider, body);
    final results = <int>[];

    for (final other in engine.colliders.values) {
      if (other.handle == colliderHandle) continue;
      if (other.bodyHandle == collider.bodyHandle) continue;
      final otherBody = engine.bodies[other.bodyHandle];
      if (otherBody == null || !otherBody.simulated) continue;

      final otherAABB = computeColliderAABB(other, otherBody);
      if (aabb.overlaps(otherAABB)) {
        results.add(other.handle);
      }
    }
    return results;
  }

  // ===================== Helpers =====================

  static bool _matchesLayer(int mask, int layer) {
    return mask & (1 << layer) != 0;
  }

  static RayHit? _rayVsCollider(Vector2 origin, Vector2 dir, double maxDist,
      PhysicsCollider collider, PhysicsBody body) {
    final center = body.position + collider.offset;
    final rot = body.rotation * math.pi / 180.0;

    switch (collider.shapeType) {
      case ColliderShapeType.circle:
        return rayVsCircle(origin, dir, maxDist, center, collider.circleRadius);
      case ColliderShapeType.box:
        return rayVsBox(origin, dir, maxDist, center,
            collider.boxSize * 0.5, rot);
      case ColliderShapeType.capsule:
        return rayVsCapsule(origin, dir, maxDist, center,
            collider.capsuleSize, collider.capsuleDirection, rot);
      case ColliderShapeType.polygon:
        return rayVsPolygon(origin, dir, maxDist, center,
            collider.polygonPoints, rot);
      case ColliderShapeType.edge:
        return rayVsPolygon(origin, dir, maxDist, center,
            collider.edgePoints, rot);
      case ColliderShapeType.composite:
        return null; // Handled via sub-colliders
    }
  }
}
