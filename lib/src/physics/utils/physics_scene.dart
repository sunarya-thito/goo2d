import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/goo2d.dart';

/// Represents a single instance of a 2D physics Scene.
///
/// Equivalent to Unity's `PhysicsScene2D`.
class PhysicsScene {
  double subStepLostTime = 0.0;
  int subStepCount = 0;

  static List<Collider> overlapCollider(Collider collider, ContactFilter contactFilter, int allocator) => const [];

  List<Collider> overlapCapsule(Vector2 point, Vector2 size, CapsuleDirection direction, double angle, ContactFilter contactFilter, int allocator) => const [];

  List<RaycastHit> circleCast(Vector2 origin, double radius, Vector2 direction, double distance, ContactFilter contactFilter, int allocator) => const [];

  bool isEmpty() => true;

  List<Collider> overlapArea(Vector2 pointA, Vector2 pointB, ContactFilter contactFilter, int allocator) => const [];

  List<RaycastHit> capsuleCast(Vector2 origin, Vector2 size, CapsuleDirection capsuleDirection, double angle, Vector2 direction, double distance, ContactFilter contactFilter, int allocator) => const [];

  List<RaycastHit> getRayIntersection(Ray ray, double distance, int layerMask, int allocator) => const [];

  List<RaycastHit> raycast(Vector2 origin, Vector2 direction, double distance, ContactFilter contactFilter, int allocator) => const [];

  List<Collider> overlapPoint(Vector2 point, ContactFilter contactFilter, int allocator) => const [];

  List<RaycastHit> linecast(Vector2 start, Vector2 end, ContactFilter contactFilter, int allocator) => const [];

  List<Collider> overlapCircle(Vector2 point, double radius, ContactFilter contactFilter, int allocator) => const [];

  List<RaycastHit> boxCast(Vector2 origin, Vector2 size, double angle, Vector2 direction, double distance, ContactFilter contactFilter, int allocator) => const [];

  bool simulate(double deltaTime, int simulationLayers) => true;

  bool isValid() => true;

  List<Collider> overlapBox(Vector2 point, Vector2 size, double angle, ContactFilter contactFilter, int allocator) => const [];
}
