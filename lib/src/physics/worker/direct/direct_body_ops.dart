import 'package:vector_math/vector_math_64.dart';
import 'package:goo2d/src/physics/worker/engine/physics_engine.dart';

/// Body property indices for generic get/set access.
class BodyProp {
  static const int position = 0;
  static const int rotation = 1;
  static const int linearVelocity = 2;
  static const int angularVelocity = 3;
  static const int linearDamping = 4;
  static const int angularDamping = 5;
  static const int gravityScale = 6;
  static const int mass = 7;
  static const int inertia = 8;
  static const int freezeRotation = 9;
  static const int simulated = 10;
  static const int useAutoMass = 11;
  static const int useFullKinematicContacts = 12;
  static const int constraints = 13;
  static const int bodyType = 14;
  static const int interpolation = 15;
  static const int collisionDetectionMode = 16;
  static const int sleepMode = 17;
  static const int centerOfMass = 18;
  static const int worldCenterOfMass = 19;
  static const int totalForce = 20;
  static const int totalTorque = 21;
  static const int sharedMaterialHandle = 22;
  static const int excludeLayers = 23;
  static const int includeLayers = 24;
  static const int layer = 25;
}

/// Direct body operations. `object → invocation`.
class DirectBodyOps {
  DirectBodyOps._();

  static Future<int> create(PhysicsEngine e) => Future.value(e.createBody());
  static Future<void> destroy(PhysicsEngine e, int h) { e.destroyBody(h); return Future.value(); }

  static Future<Object?> getProperty(PhysicsEngine e, int h, int p) {
    final b = e.getBody(h);
    return Future.value(switch (p) {
      BodyProp.position => b.position,
      BodyProp.rotation => b.rotation,
      BodyProp.linearVelocity => b.linearVelocity,
      BodyProp.angularVelocity => b.angularVelocity,
      BodyProp.linearDamping => b.linearDamping,
      BodyProp.angularDamping => b.angularDamping,
      BodyProp.gravityScale => b.gravityScale,
      BodyProp.mass => b.mass,
      BodyProp.inertia => b.inertia,
      BodyProp.freezeRotation => b.freezeRotation,
      BodyProp.simulated => b.simulated,
      BodyProp.useAutoMass => b.useAutoMass,
      BodyProp.useFullKinematicContacts => b.useFullKinematicContacts,
      BodyProp.constraints => b.constraints,
      BodyProp.bodyType => b.bodyType,
      BodyProp.interpolation => b.interpolation,
      BodyProp.collisionDetectionMode => b.collisionDetectionMode,
      BodyProp.sleepMode => b.sleepMode,
      BodyProp.centerOfMass => b.centerOfMass,
      BodyProp.worldCenterOfMass => b.worldCenterOfMass,
      BodyProp.totalForce => b.totalForce,
      BodyProp.totalTorque => b.totalTorque,
      BodyProp.sharedMaterialHandle => b.sharedMaterialHandle,
      BodyProp.excludeLayers => b.excludeLayers,
      BodyProp.includeLayers => b.includeLayers,
      BodyProp.layer => b.layer,
      _ => throw ArgumentError('Unknown body property: $p'),
    });
  }

  static Future<void> setProperty(PhysicsEngine e, int h, int p, Object? v) {
    final b = e.getBody(h);
    switch (p) {
      case BodyProp.position: b.position.setFrom(v as Vector2);
      case BodyProp.rotation: b.rotation = v as double;
      case BodyProp.linearVelocity: b.linearVelocity.setFrom(v as Vector2);
      case BodyProp.angularVelocity: b.angularVelocity = v as double;
      case BodyProp.linearDamping: b.linearDamping = v as double;
      case BodyProp.angularDamping: b.angularDamping = v as double;
      case BodyProp.gravityScale: b.gravityScale = v as double;
      case BodyProp.mass: b.mass = v as double;
      case BodyProp.inertia: b.inertia = v as double;
      case BodyProp.freezeRotation: b.freezeRotation = v as bool;
      case BodyProp.simulated: b.simulated = v as bool;
      case BodyProp.useAutoMass: b.useAutoMass = v as bool;
      case BodyProp.useFullKinematicContacts: b.useFullKinematicContacts = v as bool;
      case BodyProp.constraints: b.constraints = v as int;
      case BodyProp.bodyType: b.bodyType = v as int;
      case BodyProp.interpolation: b.interpolation = v as int;
      case BodyProp.collisionDetectionMode: b.collisionDetectionMode = v as int;
      case BodyProp.sleepMode: b.sleepMode = v as int;
      case BodyProp.centerOfMass: b.centerOfMass.setFrom(v as Vector2);
      case BodyProp.totalForce: b.totalForce.setFrom(v as Vector2);
      case BodyProp.totalTorque: b.totalTorque = v as double;
      case BodyProp.sharedMaterialHandle: b.sharedMaterialHandle = v as int;
      case BodyProp.excludeLayers: b.excludeLayers = v as int;
      case BodyProp.includeLayers: b.includeLayers = v as int;
      case BodyProp.layer: b.layer = v as int;
      default: throw ArgumentError('Unknown or readonly body property: $p');
    }
    return Future.value();
  }

  static Future<void> addForce(PhysicsEngine e, int h, Vector2 f, int m) { e.getBody(h).addForce(f, m); return Future.value(); }
  static Future<void> addForceAtPosition(PhysicsEngine e, int h, Vector2 f, Vector2 p, int m) { e.getBody(h).addForceAtPosition(f, p, m); return Future.value(); }
  static Future<void> addTorque(PhysicsEngine e, int h, double t, int m) { e.getBody(h).addTorque(t, m); return Future.value(); }
  static Future<void> addRelativeForce(PhysicsEngine e, int h, Vector2 f, int m) { e.getBody(h).addRelativeForce(f, m); return Future.value(); }
  static Future<void> movePosition(PhysicsEngine e, int h, Vector2 p) { e.getBody(h).movePosition(p); return Future.value(); }
  static Future<void> moveRotation(PhysicsEngine e, int h, double a) { e.getBody(h).moveRotation(a); return Future.value(); }
  static Future<void> movePositionAndRotation(PhysicsEngine e, int h, Vector2 p, double a) { e.getBody(h).movePositionAndRotation(p, a); return Future.value(); }
  static Future<void> setRotation(PhysicsEngine e, int h, double a) { e.getBody(h).setRotation(a); return Future.value(); }
  static Future<void> wakeUp(PhysicsEngine e, int h) { e.getBody(h).wake(); return Future.value(); }
  static Future<void> sleep(PhysicsEngine e, int h) { e.getBody(h).putToSleep(); return Future.value(); }
  static Future<bool> isAwake(PhysicsEngine e, int h) => Future.value(e.getBody(h).isAwake);
  static Future<bool> isSleeping(PhysicsEngine e, int h) => Future.value(e.getBody(h).isSleeping);
  static Future<Vector2> getPoint(PhysicsEngine e, int h, Vector2 p) => Future.value(e.getBody(h).getPoint(p));
  static Future<Vector2> getRelativePoint(PhysicsEngine e, int h, Vector2 p) => Future.value(e.getBody(h).getRelativePoint(p));
  static Future<Vector2> getVector(PhysicsEngine e, int h, Vector2 v) => Future.value(e.getBody(h).getVector(v));
  static Future<Vector2> getRelativeVector(PhysicsEngine e, int h, Vector2 v) => Future.value(e.getBody(h).getRelativeVector(v));
  static Future<Vector2> getPointVelocity(PhysicsEngine e, int h, Vector2 p) => Future.value(e.getBody(h).getPointVelocity(p));
  static Future<Vector2> getRelativePointVelocity(PhysicsEngine e, int h, Vector2 p) => Future.value(e.getBody(h).getRelativePointVelocity(p));
  static Future<Vector2> closestPoint(PhysicsEngine e, int h, Vector2 p) => Future.value(e.closestPoint(p, h));
}
