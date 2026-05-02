import 'package:flutter/painting.dart';
import 'package:goo2d/src/physics/components/rigidbody.dart';
import 'package:goo2d/src/physics/components/collider.dart';
import 'package:goo2d/src/physics/core/physics_joint.dart';
import 'package:goo2d/src/physics/bridge/physics_bridge_data.dart';

abstract class PhysicsBridge {
  Future<void> init(
    int worldId,
    void Function(PhysicsStepResult) onStepResult,
    void Function(int, bool, PhysicsRaycastHitData?) onRaycastResult,
  );
  void createWorld();
  void destroyWorld();
  void addBody(
    int id,
    RigidbodyType type, {
    double mass = 1.0,
    double drag = 0.0,
    double angularDrag = 0.05,
    bool freezeRotation = false,
    double gravityScale = 1.0,
    Offset position = Offset.zero,
    double rotation = 0.0,
  });
  void removeBody(int id);
  void updateBody(
    int id, {
    double mass = 1.0,
    double drag = 0.0,
    double angularDrag = 0.05,
    bool freezeRotation = false,
    double gravityScale = 1.0,
  });
  void addShape(int id, int bodyId, Collider collider);
  void removeShape(int id);
  void addJoint(int id, Joint joint);
  void removeJoint(int id);
  void applyForce(int bodyId, Offset force);
  void applyImpulse(int bodyId, Offset impulse);
  void applyTorque(int bodyId, double torque);
  void applyAngularImpulse(int bodyId, double impulse);
  void setGravity(Offset gravity);
  void syncVelocity(int bodyId, Offset velocity);
  void syncAngularVelocity(int bodyId, double velocity);
  void step(double dt, Map<int, PhysicsTransformSync> sync);
  void raycast(
    int requestId,
    Offset origin,
    Offset direction,
    double maxDistance,
  );
}
