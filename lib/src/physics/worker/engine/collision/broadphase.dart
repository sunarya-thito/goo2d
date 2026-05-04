import 'package:goo2d/src/physics/worker/engine/physics_engine.dart';
import 'package:goo2d/src/physics/worker/engine/physics_collider.dart';
import 'package:goo2d/src/physics/worker/engine/collision/broadphase.dart';
import 'package:goo2d/src/physics/worker/engine/collision/aabb_compute.dart';

/// A potential collision pair.
class BroadphasePair {
  final int colliderA;
  final int colliderB;
  const BroadphasePair(this.colliderA, this.colliderB);
}

/// Refined Broadphase using Dynamic AABB Tree.
List<BroadphasePair> findBroadphasePairs(PhysicsEngine engine) {
  final tree = engine.broadphaseTree;
  final pairs = <BroadphasePair>[];
  final seen = <int>{}; // Used to deduplicate pairs if we query from both sides

  // We need to find ALL overlapping pairs.
  // Standard approach: iterate over all leaves and query.
  // To optimize, we could only query "dirty" leaves, but then we'd need
  // to maintain a persistent pair set. For now, let's do a semi-brute query
  // that is still much faster than N² because of tree pruning.
  
  void queryCallback(int hA, int hB) {
    if (hA == hB) return;
    
    // Canonical order for deduplication
    final p1 = hA < hB ? hA : hB;
    final p2 = hA < hB ? hB : hA;
    final pairKey = (p1 << 32) | p2;
    if (seen.contains(pairKey)) return;
    seen.add(pairKey);

    final cA = engine.colliders[hA];
    final cB = engine.colliders[hB];
    if (cA == null || cB == null) return;

    // Skip colliders on the same body
    if (cA.bodyHandle == cB.bodyHandle) return;

    // Skip ignored pairs
    if (engine.ignoredColliderPairs.contains((p1, p2))) return;

    // Layer check
    final bodyA = engine.bodies[cA.bodyHandle];
    final bodyB = engine.bodies[cB.bodyHandle];
    if (bodyA != null && bodyB != null) {
      // (Layer collision logic can be added here)
    }

    pairs.add(BroadphasePair(hA, hB));
  }

  // Option 1: Query every object (Still much faster than N² due to tree)
  for (final hA in engine.colliders.keys) {
    final collider = engine.colliders[hA]!;
    final body = engine.bodies[collider.bodyHandle];
    if (body == null || !body.simulated) continue;
    
    // Use the actual (not fat) AABB for the query to be precise
    final aabb = computeColliderAABB(collider, body);
    tree.query(aabb, (hB) => queryCallback(hA, hB));
  }

  return pairs;
}
