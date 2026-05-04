import 'package:goo2d/src/physics/worker/engine/physics_engine.dart';
import 'package:goo2d/src/physics/worker/engine/collision/aabb.dart';
import 'package:goo2d/src/physics/worker/engine/collision/aabb_compute.dart';

/// A potential collision pair.
class BroadphasePair {
  final int colliderA;
  final int colliderB;
  const BroadphasePair(this.colliderA, this.colliderB);
}

/// Simple N² broadphase using AABB overlap.
///
/// For small body counts this is sufficient. Can be upgraded to
/// spatial hashing or sweep-and-prune later.
List<BroadphasePair> findBroadphasePairs(PhysicsEngine engine) {
  final entries = <(int, AABB)>[];

  for (final collider in engine.colliders.values) {
    final body = engine.bodies[collider.bodyHandle];
    if (body == null || !body.simulated) continue;
    entries.add((collider.handle, computeColliderAABB(collider, body)));
  }

  final pairs = <BroadphasePair>[];
  for (var i = 0; i < entries.length; i++) {
    for (var j = i + 1; j < entries.length; j++) {
      final (hA, aabbA) = entries[i];
      final (hB, aabbB) = entries[j];

      // Skip colliders on the same body
      final cA = engine.colliders[hA]!;
      final cB = engine.colliders[hB]!;
      if (cA.bodyHandle == cB.bodyHandle) continue;

      // Skip ignored pairs
      final pair = hA < hB ? (hA, hB) : (hB, hA);
      if (engine.ignoredColliderPairs.contains(pair)) continue;

      // Skip if layer collision is disabled
      // (layer check would go here once layers are tracked per body)

      if (aabbA.overlaps(aabbB)) {
        pairs.add(BroadphasePair(hA, hB));
      }
    }
  }
  return pairs;
}
