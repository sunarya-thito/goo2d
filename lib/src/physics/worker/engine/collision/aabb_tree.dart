import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/src/physics/worker/engine/collision/aabb.dart';

/// A node in the dynamic AABB tree.
class AABBTreeNode {
  AABB aabb;
  int handle; // Leaf handle. -1 if branch.
  AABBTreeNode? parent;
  AABBTreeNode? child1;
  AABBTreeNode? child2;
  int height;

  AABBTreeNode({
    required this.aabb,
    this.handle = -1,
    this.parent,
    this.child1,
    this.child2,
    this.height = 0,
  });

  bool get isLeaf => child1 == null;
}

/// A dynamic AABB tree for broadphase collision detection.
/// Based on Box2D's b2DynamicTree implementation.
class AABBTree {
  AABBTreeNode? _root;
  final Map<int, AABBTreeNode> _leafMap = {};
  
  /// Margin for "fat" AABBs to reduce tree updates.
  final double aabbExtension = 0.1;
  
  /// Velocity multiplier for "fat" AABBs.
  final double aabbMultiplier = 2.0;

  AABBTreeNode? get root => _root;

  /// Inserts a leaf into the tree.
  void insert(int handle, AABB aabb) {
    // Fatten the AABB
    final fatAABB = AABB(aabb.minX, aabb.minY, aabb.maxX, aabb.maxY);
    fatAABB.expand(aabbExtension);
    
    final node = AABBTreeNode(aabb: fatAABB, handle: handle);
    _leafMap[handle] = node;
    
    _insertLeaf(node);
  }

  /// Removes a leaf from the tree.
  void remove(int handle) {
    final node = _leafMap.remove(handle);
    if (node != null) {
      _removeLeaf(node);
    }
  }

  /// Moves a leaf. Re-inserts only if the new AABB is outside the fat AABB.
  /// Returns true if the leaf was re-inserted (moved significantly).
  bool move(int handle, AABB aabb, Vector2 displacement) {
    final node = _leafMap[handle];
    if (node == null) return false;

    // Check if new AABB is still within the fat AABB
    if (node.aabb.minX <= aabb.minX && node.aabb.minY <= aabb.minY &&
        node.aabb.maxX >= aabb.maxX && node.aabb.maxY >= aabb.maxY) {
      return false;
    }

    // Re-insert with new fat AABB
    _removeLeaf(node);

    // Fatten with velocity prediction
    final fatAABB = AABB(aabb.minX, aabb.minY, aabb.maxX, aabb.maxY);
    fatAABB.expand(aabbExtension);
    
    // Prediction: extend in direction of movement
    final d = displacement * aabbMultiplier;
    if (d.x < 0) fatAABB.minX += d.x; else fatAABB.maxX += d.x;
    if (d.y < 0) fatAABB.minY += d.y; else fatAABB.maxY += d.y;

    node.aabb = fatAABB;
    _insertLeaf(node);
    return true;
  }

  /// Queries the tree for all leaves overlapping the given AABB.
  void query(AABB aabb, void Function(int) callback) {
    if (_root == null) return;
    
    final stack = <AABBTreeNode>[_root!];
    while (stack.isNotEmpty) {
      final node = stack.removeLast();
      if (!node.aabb.overlaps(aabb)) continue;

      if (node.isLeaf) {
        callback(node.handle);
      } else {
        stack.add(node.child1!);
        stack.add(node.child2!);
      }
    }
  }

  /// Raycast against the tree. 
  /// The callback should return the new maxFraction (to prune search).
  void raycast(Vector2 origin, Vector2 direction, double maxFraction, 
      double Function(int, double) callback) {
    if (_root == null) return;

    var currentMax = maxFraction;
    final stack = <AABBTreeNode>[_root!];

    while (stack.isNotEmpty) {
      final node = stack.removeLast();
      
      // Early out if ray misses node or current best is already better
      final t = node.aabb.raycast(origin, direction, currentMax);
      if (t < 0) continue;

      if (node.isLeaf) {
        currentMax = callback(node.handle, t);
      } else {
        // Optimization: visit closer child first (heuristic)
        stack.add(node.child1!);
        stack.add(node.child2!);
      }
    }
  }

  void _insertLeaf(AABBTreeNode leaf) {
    if (_root == null) {
      _root = leaf;
      return;
    }

    // Find the best sibling for the new leaf using Surface Area Heuristic (SAH)
    final leafAABB = leaf.aabb;
    var index = _root!;
    
    while (!index.isLeaf) {
      final combinedArea = _unionArea(index.aabb, leafAABB);
      
      // Cost of creating a new parent for this node and the leaf
      final cost = 2.0 * combinedArea;
      
      // Minimum cost of pushing the leaf lower in the tree
      final inheritanceCost = 2.0 * (combinedArea - _surfaceArea(index.aabb));
      
      // Cost of descending into child1
      final cost1 = inheritanceCost + _computeDescendingCost(index.child1!, leafAABB);
      // Cost of descending into child2
      final cost2 = inheritanceCost + _computeDescendingCost(index.child2!, leafAABB);

      if (cost < cost1 && cost < cost2) break;
      
      index = (cost1 < cost2) ? index.child1! : index.child2!;
    }

    final sibling = index;
    final oldParent = sibling.parent;
    final newParent = AABBTreeNode(
      aabb: _union(sibling.aabb, leafAABB),
      parent: oldParent,
      child1: sibling,
      child2: leaf,
      height: sibling.height + 1,
    );

    sibling.parent = newParent;
    leaf.parent = newParent;

    if (oldParent != null) {
      if (oldParent.child1 == sibling) {
        oldParent.child1 = newParent;
      } else {
        oldParent.child2 = newParent;
      }
    } else {
      _root = newParent;
    }

    // Walk back up the tree fixing heights and AABBs
    _syncUp(newParent.parent);
  }

  void _removeLeaf(AABBTreeNode leaf) {
    if (leaf == _root) {
      _root = null;
      return;
    }

    final parent = leaf.parent!;
    final grandParent = parent.parent;
    final sibling = (parent.child1 == leaf) ? parent.child2! : parent.child1!;

    if (grandParent != null) {
      if (grandParent.child1 == parent) {
        grandParent.child1 = sibling;
      } else {
        grandParent.child2 = sibling;
      }
      sibling.parent = grandParent;
      _syncUp(grandParent);
    } else {
      _root = sibling;
      sibling.parent = null;
    }
    
    leaf.parent = null;
  }

  double _computeDescendingCost(AABBTreeNode node, AABB leafAABB) {
    final area = _unionArea(node.aabb, leafAABB);
    if (node.isLeaf) {
      return area;
    } else {
      return area - _surfaceArea(node.aabb);
    }
  }

  void _syncUp(AABBTreeNode? node) {
    var index = node;
    while (index != null) {
      index = _balance(index);
      
      final child1 = index.child1!;
      final child2 = index.child2!;
      
      index.height = 1 + math.max(child1.height, child2.height);
      index.aabb = _union(child1.aabb, child2.aabb);
      
      index = index.parent;
    }
  }

  /// AVL-style rebalancing.
  AABBTreeNode _balance(AABBTreeNode iA) {
    if (iA.isLeaf || iA.height < 2) return iA;

    final iB = iA.child1!;
    final iC = iA.child2!;
    final balance = iC.height - iB.height;

    // Rotate C up
    if (balance > 1) {
      final iF = iC.child1!;
      final iG = iC.child2!;

      // Swap A and C
      iC.child1 = iA;
      iC.parent = iA.parent;
      iA.parent = iC;

      // A's old parent should point to C
      if (iC.parent != null) {
        if (iC.parent!.child1 == iA) {
          iC.parent!.child1 = iC;
        } else {
          iC.parent!.child2 = iC;
        }
      } else {
        _root = iC;
      }

      // Rotate
      if (iF.height > iG.height) {
        iC.child2 = iF;
        iA.child2 = iG;
        iG.parent = iA;
        iA.aabb = _union(iB.aabb, iG.aabb);
        iC.aabb = _union(iA.aabb, iF.aabb);
        iA.height = 1 + math.max(iB.height, iG.height);
        iC.height = 1 + math.max(iA.height, iF.height);
      } else {
        iC.child2 = iG;
        iA.child2 = iF;
        iF.parent = iA;
        iA.aabb = _union(iB.aabb, iF.aabb);
        iC.aabb = _union(iA.aabb, iG.aabb);
        iA.height = 1 + math.max(iB.height, iF.height);
        iC.height = 1 + math.max(iA.height, iG.height);
      }
      return iC;
    }

    // Rotate B up
    if (balance < -1) {
      final iD = iB.child1!;
      final iE = iB.child2!;

      iB.child1 = iA;
      iB.parent = iA.parent;
      iA.parent = iB;

      if (iB.parent != null) {
        if (iB.parent!.child1 == iA) {
          iB.parent!.child1 = iB;
        } else {
          iB.parent!.child2 = iB;
        }
      } else {
        _root = iB;
      }

      if (iD.height > iE.height) {
        iB.child2 = iD;
        iA.child1 = iE;
        iE.parent = iA;
        iA.aabb = _union(iC.aabb, iE.aabb);
        iB.aabb = _union(iA.aabb, iD.aabb);
        iA.height = 1 + math.max(iC.height, iE.height);
        iB.height = 1 + math.max(iA.height, iD.height);
      } else {
        iB.child2 = iE;
        iA.child1 = iD;
        iD.parent = iA;
        iA.aabb = _union(iC.aabb, iD.aabb);
        iB.aabb = _union(iA.aabb, iE.aabb);
        iA.height = 1 + math.max(iC.height, iD.height);
        iB.height = 1 + math.max(iA.height, iE.height);
      }
      return iB;
    }

    return iA;
  }

  AABB _union(AABB a, AABB b) {
    return AABB(
      math.min(a.minX, b.minX),
      math.min(a.minY, b.minY),
      math.max(a.maxX, b.maxX),
      math.max(a.maxY, b.maxY),
    );
  }

  double _surfaceArea(AABB a) {
    final w = a.maxX - a.minX;
    final h = a.maxY - a.minY;
    return 2.0 * (w + h);
  }

  double _unionArea(AABB a, AABB b) {
    final w = math.max(a.maxX, b.maxX) - math.min(a.minX, b.minX);
    final h = math.max(a.maxY, b.maxY) - math.min(a.minY, b.minY);
    return 2.0 * (w + h);
  }
}
