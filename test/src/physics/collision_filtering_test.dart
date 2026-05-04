import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/src/physics/worker/engine/physics_engine.dart';
import 'package:goo2d/src/physics/worker/data/collider_shape_type.dart';
import 'package:goo2d/src/physics/worker/engine/collision/broadphase.dart';

void main() {
  late PhysicsEngine engine;

  setUp(() {
    engine = PhysicsEngine();
  });

  test('global layer matrix prevents collision', () {
    final bodyA = engine.bodies[engine.createBody()]!;
    final bodyB = engine.bodies[engine.createBody()]!;
    
    bodyA.position.setValues(0, 0);
    bodyB.position.setValues(0.5, 0); // Overlapping circles
    
    bodyA.layer = 1;
    bodyB.layer = 2;
    
    engine.createCollider(ColliderShapeType.circle, bodyA.handle);
    engine.createCollider(ColliderShapeType.circle, bodyB.handle);
    
    // By default all layers collide
    var pairs = findBroadphasePairs(engine);
    expect(pairs.length, 1);
    
    // Disable collision between layer 1 and 2
    engine.layerCollisionMask[1] &= ~(1 << 2);
    engine.layerCollisionMask[2] &= ~(1 << 1);
    
    pairs = findBroadphasePairs(engine);
    expect(pairs.length, 0);
  });

  test('excludeLayers override prevents collision', () {
    final bodyA = engine.bodies[engine.createBody()]!;
    final bodyB = engine.bodies[engine.createBody()]!;
    
    bodyA.position.setValues(0, 0);
    bodyB.position.setValues(0.5, 0);
    
    bodyA.layer = 1;
    bodyB.layer = 2;
    
    engine.createCollider(ColliderShapeType.circle, bodyA.handle);
    engine.createCollider(ColliderShapeType.circle, bodyB.handle);
    
    // Exclude layer 2 from bodyA
    bodyA.excludeLayers = (1 << 2);
    
    var pairs = findBroadphasePairs(engine);
    expect(pairs.length, 0);
  });

  test('includeLayers override allows collision', () {
    final bodyA = engine.bodies[engine.createBody()]!;
    final bodyB = engine.bodies[engine.createBody()]!;
    
    bodyA.position.setValues(0, 0);
    bodyB.position.setValues(0.5, 0);
    
    bodyA.layer = 1;
    bodyB.layer = 2;
    
    engine.createCollider(ColliderShapeType.circle, bodyA.handle);
    engine.createCollider(ColliderShapeType.circle, bodyB.handle);
    
    // Set layer matrix to ignore 1 and 2
    engine.layerCollisionMask[1] &= ~(1 << 2);
    engine.layerCollisionMask[2] &= ~(1 << 1);
    
    // Include layer 2 on bodyA (but global matrix says no)
    bodyA.includeLayers = (1 << 2);
    
    var pairs = findBroadphasePairs(engine);
    expect(pairs.length, 0); // Matrix still says no
    
    // Fix matrix
    engine.layerCollisionMask[1] |= (1 << 2);
    engine.layerCollisionMask[2] |= (1 << 1);
    
    pairs = findBroadphasePairs(engine);
    expect(pairs.length, 1);
  });

  test('raycast filters by layer mask', () {
    final bodyA = engine.bodies[engine.createBody()]!;
    bodyA.position.setValues(5, 0);
    bodyA.layer = 5;
    engine.createCollider(ColliderShapeType.circle, bodyA.handle);
    engine.getCollider(bodyA.colliderHandles[0]).circleRadius = 1.0;
    
    engine.syncTransforms(); // Update AABB Tree
    
    // Raycast that should hit bodyA
    var hits = engine.raycast(Vector2(0, 0), Vector2(1, 0), 10, ~0, 0, 100);
    expect(hits.length, 1);
    
    // Raycast that ignores layer 5
    hits = engine.raycast(Vector2(0, 0), Vector2(1, 0), 10, ~(1 << 5), 0, 100);
    expect(hits.length, 0);
  });
}
