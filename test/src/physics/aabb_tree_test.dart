import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/src/physics/worker/engine/collision/aabb.dart';
import 'package:goo2d/src/physics/worker/engine/collision/aabb_tree.dart';

void main() {
  group('AABBTree', () {
    test('insert and query', () {
      final tree = AABBTree();
      
      // Insert some non-overlapping boxes
      tree.insert(1, AABB(0, 0, 1, 1));
      tree.insert(2, AABB(5, 5, 6, 6));
      tree.insert(3, AABB(-5, -5, -4, -4));
      
      final results = <int>[];
      tree.query(AABB(0.5, 0.5, 0.6, 0.6), (h) => results.add(h));
      expect(results, [1]);
      
      results.clear();
      tree.query(AABB(4, 4, 7, 7), (h) => results.add(h));
      expect(results, [2]);
      
      results.clear();
      tree.query(AABB(-10, -10, 10, 10), (h) => results.add(h));
      expect(results.length, 3);
      expect(results, containsAll([1, 2, 3]));
    });

    test('remove and query', () {
      final tree = AABBTree();
      tree.insert(1, AABB(0, 0, 1, 1));
      tree.insert(2, AABB(2, 2, 3, 3));
      
      tree.remove(1);
      
      final results = <int>[];
      tree.query(AABB(-1, -1, 4, 4), (h) => results.add(h));
      expect(results, [2]);
    });

    test('move and query', () {
      final tree = AABBTree();
      tree.insert(1, AABB(0, 0, 1, 1));
      
      // Move slightly (within fat AABB)
      var moved = tree.move(1, AABB(0.01, 0.01, 1.01, 1.01), Vector2.zero());
      expect(moved, isFalse);
      
      // Move significantly (outside fat AABB)
      moved = tree.move(1, AABB(10, 10, 11, 11), Vector2.zero());
      expect(moved, isTrue);
      
      final results = <int>[];
      tree.query(AABB(10.5, 10.5, 10.6, 10.6), (h) => results.add(h));
      expect(results, [1]);
      
      results.clear();
      tree.query(AABB(0.5, 0.5, 0.6, 0.6), (h) => results.isEmpty);
      expect(results, isEmpty);
    });

    test('raycast', () {
      final tree = AABBTree();
      tree.insert(1, AABB(0, 0, 1, 1));
      tree.insert(2, AABB(2, 0, 3, 1));
      
      final hits = <int>[];
      tree.raycast(Vector2(-1, 0.5), Vector2(1, 0), 10, (h, t) {
        hits.add(h);
        return 10; // Keep going
      });
      
      expect(hits, containsAll([1, 2]));
      
      hits.clear();
      tree.raycast(Vector2(-1, 0.5), Vector2(0, 1), 10, (h, t) {
        hits.add(h);
        return 10;
      });
      expect(hits, isEmpty);
    });

    test('balancing and stability', () {
      final tree = AABBTree();
      // Insert many nodes to trigger rotations and rebalancing
      for (var i = 0; i < 100; i++) {
        tree.insert(i, AABB(i.toDouble(), 0, i + 0.5, 0.5));
      }
      
      final results = <int>[];
      tree.query(AABB(-1, -1, 101, 1), (h) => results.add(h));
      expect(results.length, 100);
      
      // Remove half
      for (var i = 0; i < 50; i++) {
        tree.remove(i);
      }
      
      results.clear();
      tree.query(AABB(-1, -1, 101, 1), (h) => results.add(h));
      expect(results.length, 50);
      expect(results, contains(99));
      expect(results, isNot(contains(0)));
    });
  });
}
