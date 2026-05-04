import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';

/// Internal physics body matching Unity's Rigidbody2D state.
class PhysicsBody {
  final int handle;

  // Transform
  Vector2 position = Vector2.zero();
  double rotation = 0.0;

  // Dynamics
  Vector2 linearVelocity = Vector2.zero();
  double angularVelocity = 0.0;
  double linearDamping = 0.0;
  double angularDamping = 0.0;
  double gravityScale = 1.0;
  double mass = 1.0;
  double inertia = 0.0;
  bool freezeRotation = false;
  bool simulated = true;
  bool useAutoMass = false;
  bool useFullKinematicContacts = false;
  int constraints = 0;
  int bodyType = 0; // 0=dynamic, 1=static, 2=kinematic
  int interpolation = 0; // 0=none, 1=interpolate, 2=extrapolate
  int collisionDetectionMode = 0; // 0=discrete, 1=continuous
  int sleepMode = 0; // 0=startAwake, 1=startAsleep, 2=neverSleep
  int excludeLayers = 0;
  int includeLayers = 0;

  // Computed
  Vector2 centerOfMass = Vector2.zero();
  Vector2 worldCenterOfMass = Vector2.zero();
  Vector2 totalForce = Vector2.zero();
  double totalTorque = 0.0;

  // Material
  int sharedMaterialHandle = -1;

  // State
  bool _sleeping = false;
  double sleepTime = 0;

  // Attached colliders
  final List<int> colliderHandles = [];

  PhysicsBody(this.handle);

  bool get isAwake => !_sleeping;
  bool get isSleeping => _sleeping;
  void wake() => _sleeping = false;
  void putToSleep() => _sleeping = true;

  void addForce(Vector2 force, int mode) {
    if (mode == 0) {
      linearVelocity += force / mass;
    } else {
      totalForce += force;
    }
  }

  void addForceAtPosition(Vector2 force, Vector2 point, int mode) {
    addForce(force, mode);
    final r = point - worldCenterOfMass;
    addTorque(r.x * force.y - r.y * force.x, mode);
  }

  void addTorque(double torque, int mode) {
    if (mode == 0) {
      if (inertia > 0) angularVelocity += torque / inertia;
    } else {
      totalTorque += torque;
    }
  }

  void addRelativeForce(Vector2 relativeForce, int mode) {
    final rad = rotation * math.pi / 180.0;
    final c = math.cos(rad);
    final s = math.sin(rad);
    addForce(Vector2(
      relativeForce.x * c - relativeForce.y * s,
      relativeForce.x * s + relativeForce.y * c,
    ), mode);
  }

  void movePosition(Vector2 target) => position.setFrom(target);
  void moveRotation(double angle) => rotation = angle;
  void movePositionAndRotation(Vector2 target, double angle) {
    position.setFrom(target);
    rotation = angle;
  }
  void setRotation(double angle) => rotation = angle;

  Vector2 getPoint(Vector2 worldPoint) {
    final rad = -rotation * math.pi / 180.0;
    final c = math.cos(rad);
    final s = math.sin(rad);
    final d = worldPoint - position;
    return Vector2(d.x * c - d.y * s, d.x * s + d.y * c);
  }

  Vector2 getRelativePoint(Vector2 localPoint) {
    final rad = rotation * math.pi / 180.0;
    final c = math.cos(rad);
    final s = math.sin(rad);
    return Vector2(
      localPoint.x * c - localPoint.y * s + position.x,
      localPoint.x * s + localPoint.y * c + position.y,
    );
  }

  Vector2 getVector(Vector2 worldVector) {
    final rad = -rotation * math.pi / 180.0;
    final c = math.cos(rad);
    final s = math.sin(rad);
    return Vector2(worldVector.x * c - worldVector.y * s,
        worldVector.x * s + worldVector.y * c);
  }

  Vector2 getRelativeVector(Vector2 localVector) {
    final rad = rotation * math.pi / 180.0;
    final c = math.cos(rad);
    final s = math.sin(rad);
    return Vector2(localVector.x * c - localVector.y * s,
        localVector.x * s + localVector.y * c);
  }

  Vector2 getPointVelocity(Vector2 worldPoint) {
    final r = worldPoint - worldCenterOfMass;
    final w = angularVelocity * math.pi / 180.0;
    return Vector2(linearVelocity.x - w * r.y, linearVelocity.y + w * r.x);
  }

  Vector2 getRelativePointVelocity(Vector2 localPoint) {
    return getPointVelocity(getRelativePoint(localPoint));
  }
}
