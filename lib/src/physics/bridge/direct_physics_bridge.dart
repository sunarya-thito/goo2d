import 'package:flutter/painting.dart';
import 'package:goo2d/src/physics/core/physics_world.dart';
import 'package:goo2d/src/physics/core/physics_body.dart';
import 'package:goo2d/src/physics/core/physics_shape.dart';
import 'package:goo2d/src/physics/components/rigidbody.dart';
import 'package:goo2d/src/physics/components/collider.dart';
import 'package:goo2d/src/physics/core/physics_joint.dart';
import 'package:goo2d/src/physics/bridge/physics_bridge.dart';
import 'package:goo2d/src/physics/bridge/physics_bridge_data.dart';

/// Implementation of [PhysicsBridge] that calls [PhysicsWorld] directly.
/// 
/// This bridge is designed for environments where [Isolate]s are either 
/// unavailable (Flutter Web) or where the overhead of message serialization 
/// outweighs the benefits of parallel execution. It executes all physics 
/// logic on the caller's thread.
class DirectPhysicsBridge implements PhysicsBridge {
  late final PhysicsWorld _world;
  late void Function(PhysicsStepResult) _onStepResult;
  late void Function(int, bool, PhysicsRaycastHitData?) _onRaycastResult;

  @override
  Future<void> init(
      int worldId,
      void Function(PhysicsStepResult) onStepResult,
      void Function(int, bool, PhysicsRaycastHitData?) onRaycastResult) {
    _onStepResult = onStepResult;
    _onRaycastResult = onRaycastResult;
    _world = PhysicsWorld();
    return Future.value();
  }

  @override
  void createWorld() {
    // Already created in init
  }

  @override
  void destroyWorld() {
    _world.bodies.clear();
  }

  @override
  void addBody(int id, RigidbodyType type,
      {double mass = 1.0,
      double drag = 0.0,
      double angularDrag = 0.05,
      bool freezeRotation = false,
      double gravityScale = 1.0,
      Offset position = Offset.zero,
      double rotation = 0.0}) {
    final body = PhysicsBody(id: id, type: type.index);
    body.setMass(mass);
    body.drag = drag;
    body.angularDrag = angularDrag;
    body.freezeRotation = freezeRotation;
    body.gravityScale = gravityScale;
    body.position = position;
    body.rotation = rotation;
    _world.bodies[id] = body;
  }

  @override
  void removeBody(int id) {
    _world.bodies.remove(id);
  }

  @override
  void updateBody(int id,
      {double mass = 1.0,
      double drag = 0.0,
      double angularDrag = 0.05,
      bool freezeRotation = false,
      double gravityScale = 1.0}) {
    final body = _world.bodies[id];
    if (body != null) {
      body.setMass(mass);
      body.drag = drag;
      body.angularDrag = angularDrag;
      body.freezeRotation = freezeRotation;
      body.gravityScale = gravityScale;
    }
  }

  @override
  void addShape(int id, int bodyId, Collider collider) {
    final body = _world.bodies[bodyId];
    if (body == null) return;

    PhysicsShape shape;
    if (collider is BoxCollider) {
      shape = PhysicsBox(collider.size.width, collider.size.height);
    } else if (collider is CircleCollider) {
      shape = PhysicsCircle(collider.radius);
    } else if (collider is PolygonCollider) {
      shape = PhysicsPolygon(collider.vertices);
    } else if (collider is CapsuleCollider) {
      shape = PhysicsCapsule(
          collider.radius, collider.height, collider.direction);
    } else if (collider is CompositeCollider) {
      for (final geometry in collider.shapes) {
        PhysicsShape subShape;
        if (geometry is BoxGeometry) {
          subShape = PhysicsBox(geometry.size.width, geometry.size.height);
        } else if (geometry is CircleGeometry) {
          subShape = PhysicsCircle(geometry.radius);
        } else if (geometry is PolygonGeometry) {
          subShape = PhysicsPolygon(geometry.vertices);
        } else if (geometry is CapsuleGeometry) {
          subShape = PhysicsCapsule(
              geometry.radius, geometry.height, geometry.direction);
        } else {
          continue;
        }

        subShape.id = id;
        subShape.isTrigger = geometry.isTrigger;
        subShape.localOffset = geometry.offset + collider.offset;
        subShape.bounciness = geometry.material.bounciness;
        subShape.friction = geometry.material.friction;
        subShape.isOneWay = geometry.isOneWay;
        subShape.oneWayAngle = geometry.oneWayAngle;
        subShape.oneWayArc = geometry.oneWayArc;
        subShape.body = body;
      }
      return;
    } else {
      return;
    }

    shape.id = id;
    shape.isTrigger = collider.isTrigger;
    shape.localOffset = collider.offset;
    shape.bounciness = collider.material.bounciness;
    shape.friction = collider.material.friction;
    shape.isOneWay = collider.isOneWay;
    shape.oneWayAngle = collider.oneWayAngle;
    shape.oneWayArc = collider.oneWayArc;
    shape.body = body;
  }

  @override
  void removeShape(int id) {
    for (final body in _world.bodies.values) {
      body.shapes.removeWhere((s) => s.id == id);
    }
  }

  @override
  void addJoint(int id, Joint joint) {
    _world.joints[id] = joint;
  }

  @override
  void removeJoint(int id) {
    _world.joints.remove(id);
  }

  @override
  void applyForce(int bodyId, Offset force) {
    _world.bodies[bodyId]?.applyForce(force);
  }

  @override
  void applyImpulse(int bodyId, Offset impulse) {
    _world.bodies[bodyId]?.applyImpulse(impulse);
  }

  @override
  void applyTorque(int bodyId, double torque) {
    _world.bodies[bodyId]?.applyTorque(torque);
  }

  @override
  void applyAngularImpulse(int bodyId, double impulse) {
    _world.bodies[bodyId]?.applyAngularImpulse(impulse);
  }

  @override
  void setGravity(Offset gravity) {
    _world.gravity = gravity;
  }

  @override
  void syncVelocity(int bodyId, Offset velocity) {
    final body = _world.bodies[bodyId];
    if (body != null) {
      body.velocity = velocity;
    }
  }

  @override
  void syncAngularVelocity(int bodyId, double velocity) {
    final body = _world.bodies[bodyId];
    if (body != null) {
      body.angularVelocity = velocity;
    }
  }

  @override
  void step(double dt, Map<int, PhysicsTransformSync> sync) {
    // 1. Sync transforms
    for (final entry in sync.entries) {
      final body = _world.bodies[entry.key];
      if (body != null) {
        body.position = entry.value.position;
        body.rotation = entry.value.rotation;
      }
    }

    // 2. Perform step
    final result = _world.step(dt);

    // 3. Prepare response
    final contacts = result.contacts
        .map((c) => PhysicsContactData(
              shapeAId: c.shapeAId,
              shapeBId: c.shapeBId,
              contactPoint: c.manifold.contactPoint,
              normal: c.manifold.normal,
              depth: c.manifold.depth,
              impulse: c.impulse,
            ))
        .toList();

    final dynamicBodies = <int, PhysicsBodyState>{};
    for (final body in _world.bodies.values) {
      if (body.type == 0) {
        // dynamic
        dynamicBodies[body.id] = PhysicsBodyState(
          position: body.position,
          rotation: body.rotation,
          velocity: body.velocity,
          angularVelocity: body.angularVelocity,
        );
      }
    }

    _onStepResult(PhysicsStepResult(
      contacts: contacts,
      dynamicBodies: dynamicBodies,
    ));
  }

  @override
  void raycast(
      int requestId, Offset origin, Offset direction, double maxDistance) {
    final hit = _world.raycast(origin, direction, maxDistance);
    if (hit != null) {
      _onRaycastResult(
          requestId,
          true,
          PhysicsRaycastHitData(
            shapeId: hit.shapeId,
            point: hit.point,
            normal: hit.normal,
            distance: hit.distance,
            fraction: hit.fraction,
          ));
    } else {
      _onRaycastResult(requestId, false, null);
    }
  }
}
