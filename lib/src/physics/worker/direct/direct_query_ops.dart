import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/src/physics/worker/engine/physics_engine.dart';
import 'package:goo2d/src/physics/worker/data/raycast_hit_data.dart';
import 'package:goo2d/src/physics/worker/data/contact_point_data.dart';

/// Direct query operations. `object → invocation`.
class DirectQueryOps {
  DirectQueryOps._();

  static Future<List<RaycastHitData>> raycast(PhysicsEngine e, Vector2 o, Vector2 d, double dist, int lm, double mind, double maxd) =>
      Future.value(e.raycast(o, d, dist, lm, mind, maxd));
  static Future<List<RaycastHitData>> linecast(PhysicsEngine e, Vector2 s, Vector2 end, int lm, double mind, double maxd) =>
      Future.value(e.linecast(s, end, lm, mind, maxd));
  static Future<List<RaycastHitData>> boxCast(PhysicsEngine e, Vector2 o, Vector2 sz, double a, Vector2 d, double dist, int lm, double mind, double maxd) =>
      Future.value(e.boxCast(o, sz, a, d, dist, lm, mind, maxd));
  static Future<List<RaycastHitData>> circleCast(PhysicsEngine e, Vector2 o, double r, Vector2 d, double dist, int lm, double mind, double maxd) =>
      Future.value(e.circleCast(o, r, d, dist, lm, mind, maxd));
  static Future<List<RaycastHitData>> capsuleCast(PhysicsEngine e, Vector2 o, Vector2 sz, int cd, double a, Vector2 d, double dist, int lm, double mind, double maxd) =>
      Future.value(e.capsuleCast(o, sz, cd, a, d, dist, lm, mind, maxd));
  static Future<List<int>> overlapCircle(PhysicsEngine e, Vector2 p, double r, int lm, double mind, double maxd) =>
      Future.value(e.overlapCircle(p, r, lm, mind, maxd));
  static Future<List<int>> overlapBox(PhysicsEngine e, Vector2 p, Vector2 sz, double a, int lm, double mind, double maxd) =>
      Future.value(e.overlapBox(p, sz, a, lm, mind, maxd));
  static Future<List<int>> overlapPoint(PhysicsEngine e, Vector2 p, int lm, double mind, double maxd) =>
      Future.value(e.overlapPoint(p, lm, mind, maxd));
  static Future<Vector2> closestPoint(PhysicsEngine e, Vector2 p, int ch) =>
      Future.value(e.closestPoint(p, ch));
  static Future<List<ContactPointData>> getContacts(PhysicsEngine e, int h) =>
      Future.value(e.getContacts(h));
  static Future<List<int>> getContactColliders(PhysicsEngine e, int h) =>
      Future.value(e.getContactColliders(h));
  static Future<List<int>> overlapCollider(PhysicsEngine e, int h) =>
      Future.value(e.overlapCollider(h));
}
