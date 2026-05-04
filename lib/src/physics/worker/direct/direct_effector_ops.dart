import 'package:goo2d/src/physics/worker/engine/physics_engine.dart';

/// Effector property indices.
class EffectorProp {
  static const int colliderMask = 0;
  static const int useColliderMask = 1;
  // Area
  static const int forceAngle = 100;
  static const int forceMagnitude = 101;
  static const int forceVariation = 102;
  static const int drag = 103;
  static const int angularDrag = 104;
  static const int forceTarget = 105;
  static const int useGlobalAngle = 106;
  static const int areaForceMode = 107;
  // Buoyancy
  static const int surfaceLevel = 200;
  static const int buoyancyDensity = 201;
  static const int flowAngle = 202;
  static const int flowMagnitude = 203;
  static const int flowVariation = 204;
  static const int linearDrag = 205;
  static const int angularDragBuoyancy = 206;
  // Platform
  static const int useOneWay = 300;
  static const int useOneWayGrouping = 301;
  static const int useSideFriction = 302;
  static const int useSideBounce = 303;
  static const int surfaceArc = 304;
  static const int sideArc = 305;
  static const int rotationalOffset = 306;
  // Point
  static const int pointForceMagnitude = 400;
  static const int pointForceVariation = 401;
  static const int distanceScale = 402;
  static const int pointDrag = 403;
  static const int pointAngularDrag = 404;
  static const int pointForceSource = 405;
  static const int pointForceTarget = 406;
  static const int pointForceMode = 407;
  // Surface
  static const int speed = 500;
  static const int speedVariation = 501;
  static const int forceScale = 502;
  static const int useContactForce = 503;
  static const int useFriction = 504;
  static const int useBounce = 505;
}

/// Direct effector operations. `object → invocation`.
class DirectEffectorOps {
  DirectEffectorOps._();

  static Future<int> create(PhysicsEngine e, int t) => Future.value(e.createEffector(t));
  static Future<void> destroy(PhysicsEngine e, int h) { e.destroyEffector(h); return Future.value(); }

  static Future<Object?> getProperty(PhysicsEngine e, int h, int p) {
    final ef = e.getEffector(h);
    return Future.value(switch (p) {
      EffectorProp.colliderMask => ef.colliderMask,
      EffectorProp.useColliderMask => ef.useColliderMask,
      EffectorProp.forceAngle => ef.forceAngle,
      EffectorProp.forceMagnitude => ef.forceMagnitude,
      EffectorProp.forceVariation => ef.forceVariation,
      EffectorProp.drag => ef.drag,
      EffectorProp.angularDrag => ef.angularDrag,
      EffectorProp.forceTarget => ef.forceTarget,
      EffectorProp.useGlobalAngle => ef.useGlobalAngle,
      EffectorProp.areaForceMode => ef.areaForceMode,
      EffectorProp.surfaceLevel => ef.surfaceLevel,
      EffectorProp.buoyancyDensity => ef.buoyancyDensity,
      EffectorProp.flowAngle => ef.flowAngle,
      EffectorProp.flowMagnitude => ef.flowMagnitude,
      EffectorProp.flowVariation => ef.flowVariation,
      EffectorProp.linearDrag => ef.linearDrag,
      EffectorProp.angularDragBuoyancy => ef.angularDragBuoyancy,
      EffectorProp.useOneWay => ef.useOneWay,
      EffectorProp.useOneWayGrouping => ef.useOneWayGrouping,
      EffectorProp.useSideFriction => ef.useSideFriction,
      EffectorProp.useSideBounce => ef.useSideBounce,
      EffectorProp.surfaceArc => ef.surfaceArc,
      EffectorProp.sideArc => ef.sideArc,
      EffectorProp.rotationalOffset => ef.rotationalOffset,
      EffectorProp.pointForceMagnitude => ef.pointForceMagnitude,
      EffectorProp.pointForceVariation => ef.pointForceVariation,
      EffectorProp.distanceScale => ef.distanceScale,
      EffectorProp.pointDrag => ef.pointDrag,
      EffectorProp.pointAngularDrag => ef.pointAngularDrag,
      EffectorProp.pointForceSource => ef.pointForceSource,
      EffectorProp.pointForceTarget => ef.pointForceTarget,
      EffectorProp.pointForceMode => ef.pointForceMode,
      EffectorProp.speed => ef.speed,
      EffectorProp.speedVariation => ef.speedVariation,
      EffectorProp.forceScale => ef.forceScale,
      EffectorProp.useContactForce => ef.useContactForce,
      EffectorProp.useFriction => ef.useFriction,
      EffectorProp.useBounce => ef.useBounce,
      _ => throw ArgumentError('Unknown effector property: $p'),
    });
  }

  static Future<void> setProperty(PhysicsEngine e, int h, int p, Object? v) {
    final ef = e.getEffector(h);
    switch (p) {
      case EffectorProp.colliderMask: ef.colliderMask = v as int;
      case EffectorProp.useColliderMask: ef.useColliderMask = v as bool;
      case EffectorProp.forceAngle: ef.forceAngle = v as double;
      case EffectorProp.forceMagnitude: ef.forceMagnitude = v as double;
      case EffectorProp.forceVariation: ef.forceVariation = v as double;
      case EffectorProp.drag: ef.drag = v as double;
      case EffectorProp.angularDrag: ef.angularDrag = v as double;
      case EffectorProp.forceTarget: ef.forceTarget = v as int;
      case EffectorProp.useGlobalAngle: ef.useGlobalAngle = v as bool;
      case EffectorProp.areaForceMode: ef.areaForceMode = v as int;
      case EffectorProp.surfaceLevel: ef.surfaceLevel = v as double;
      case EffectorProp.buoyancyDensity: ef.buoyancyDensity = v as double;
      case EffectorProp.flowAngle: ef.flowAngle = v as double;
      case EffectorProp.flowMagnitude: ef.flowMagnitude = v as double;
      case EffectorProp.flowVariation: ef.flowVariation = v as double;
      case EffectorProp.linearDrag: ef.linearDrag = v as double;
      case EffectorProp.angularDragBuoyancy: ef.angularDragBuoyancy = v as double;
      case EffectorProp.useOneWay: ef.useOneWay = v as bool;
      case EffectorProp.useOneWayGrouping: ef.useOneWayGrouping = v as bool;
      case EffectorProp.useSideFriction: ef.useSideFriction = v as bool;
      case EffectorProp.useSideBounce: ef.useSideBounce = v as bool;
      case EffectorProp.surfaceArc: ef.surfaceArc = v as double;
      case EffectorProp.sideArc: ef.sideArc = v as double;
      case EffectorProp.rotationalOffset: ef.rotationalOffset = v as int;
      case EffectorProp.pointForceMagnitude: ef.pointForceMagnitude = v as double;
      case EffectorProp.pointForceVariation: ef.pointForceVariation = v as double;
      case EffectorProp.distanceScale: ef.distanceScale = v as double;
      case EffectorProp.pointDrag: ef.pointDrag = v as double;
      case EffectorProp.pointAngularDrag: ef.pointAngularDrag = v as double;
      case EffectorProp.pointForceSource: ef.pointForceSource = v as int;
      case EffectorProp.pointForceTarget: ef.pointForceTarget = v as int;
      case EffectorProp.pointForceMode: ef.pointForceMode = v as int;
      case EffectorProp.speed: ef.speed = v as double;
      case EffectorProp.speedVariation: ef.speedVariation = v as double;
      case EffectorProp.forceScale: ef.forceScale = v as double;
      case EffectorProp.useContactForce: ef.useContactForce = v as bool;
      case EffectorProp.useFriction: ef.useFriction = v as bool;
      case EffectorProp.useBounce: ef.useBounce = v as bool;
      default: throw ArgumentError('Unknown effector property: $p');
    }
    return Future.value();
  }
}
