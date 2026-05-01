import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/painting.dart';
import 'package:goo2d/src/physics/components/rigidbody.dart';
import 'package:goo2d/src/physics/components/collider.dart';
import 'package:goo2d/src/physics/worker/physics_protocol.dart';
import 'package:goo2d/src/physics/worker/physics_worker.dart';
import 'package:goo2d/src/physics/bridge/physics_bridge.dart';
import 'package:goo2d/src/physics/core/physics_joint.dart';
import 'package:goo2d/src/physics/core/physics_shape.dart';
import 'package:goo2d/src/physics/bridge/physics_bridge_data.dart';

/// Implementation of [PhysicsBridge] that uses an [Isolate] worker.
/// 
/// This bridge is the preferred implementation for high-performance native 
/// applications. It offloads the entire simulation (integration, collision 
/// detection, and resolution) to a background thread to prevent "jank" on 
/// the UI thread. Data is synchronized via high-performance binary serialization.
class WorkerPhysicsBridge extends PhysicsBridge {
  late int _worldId;
  late void Function(PhysicsStepResult) _onStepResult;
  late void Function(int, bool, PhysicsRaycastHitData?) _onRaycastResult;

  final ReceivePort _receivePort = ReceivePort();
  SendPort? _sendPort;
  bool _initialized = false;
  final List<ByteData> _pendingMessages = [];

  @override
  Future<void> init(int worldId, void Function(PhysicsStepResult) onStepResult,
      void Function(int, bool, PhysicsRaycastHitData?) onRaycastResult) async {
    _worldId = worldId;
    _onStepResult = onStepResult;
    _onRaycastResult = onRaycastResult;

    _receivePort.listen(_handleMessage);

    await Isolate.spawn(physicsWorkerEntry, _receivePort.sendPort);
  }

  void _handleMessage(dynamic message) {
    if (message is SendPort) {
      _sendPort = message;
      _initialized = true;
      for (final msg in _pendingMessages) {
        _sendPort!.send(msg);
      }
      _pendingMessages.clear();
      return;
    }

    if (message is ByteData) {
      final buffer = PhysicsBuffer(message);
      final packetId = buffer.readUint8();
      final wId = buffer.readInt32();

      if (wId != _worldId) return;

      if (packetId == PhysicsPacket.stepResult) {
        _handleStepResult(buffer);
      } else if (packetId == PhysicsPacket.raycastResult) {
        _handleRaycastResult(buffer);
      }
    }
  }

  void _handleStepResult(PhysicsBuffer buffer) {
    final bodyCount = buffer.readInt32();
    final dynamicBodies = <int, PhysicsBodyState>{};
    for (int i = 0; i < bodyCount; i++) {
      final id = buffer.readInt32();
      final px = buffer.readFloat32();
      final py = buffer.readFloat32();
      final rot = buffer.readFloat32();
      final vx = buffer.readFloat32();
      final vy = buffer.readFloat32();
      final av = buffer.readFloat32();
      dynamicBodies[id] = PhysicsBodyState(
        position: Offset(px, py),
        rotation: rot,
        velocity: Offset(vx, vy),
        angularVelocity: av,
      );
    }

    final contactCount = buffer.readInt32();
    final contacts = <PhysicsContactData>[];
    for (int i = 0; i < contactCount; i++) {
      final sAId = buffer.readInt32();
      final sBId = buffer.readInt32();
      final px = buffer.readFloat32();
      final py = buffer.readFloat32();
      final nx = buffer.readFloat32();
      final ny = buffer.readFloat32();
      final impulse = buffer.readFloat32();
      contacts.add(PhysicsContactData(
        shapeAId: sAId,
        shapeBId: sBId,
        contactPoint: Offset(px, py),
        normal: Offset(nx, ny),
        depth: 0, // Not currently sent back by worker, but could be added
        impulse: impulse,
      ));
    }

    _onStepResult(PhysicsStepResult(
      contacts: contacts,
      dynamicBodies: dynamicBodies,
    ));
  }

  void _handleRaycastResult(PhysicsBuffer buffer) {
    final requestId = buffer.readInt32();
    final hasHit = buffer.readBool();
    if (hasHit) {
      final shapeId = buffer.readInt32();
      final px = buffer.readFloat32();
      final py = buffer.readFloat32();
      final nx = buffer.readFloat32();
      final ny = buffer.readFloat32();
      final dist = buffer.readFloat32();
      final frac = buffer.readFloat32();
      _onRaycastResult(
          requestId,
          true,
          PhysicsRaycastHitData(
            shapeId: shapeId,
            point: Offset(px, py),
            normal: Offset(nx, ny),
            distance: dist,
            fraction: frac,
          ));
    } else {
      _onRaycastResult(requestId, false, null);
    }
  }

  void _send(ByteData data) {
    if (!_initialized) {
      _pendingMessages.add(data);
    } else {
      _sendPort!.send(data);
    }
  }

  @override
  void createWorld() {
    final buf = PhysicsBuffer.fixed(5);
    buf.writeUint8(PhysicsPacket.createWorld);
    buf.writeInt32(_worldId);
    _send(buf.data);
  }

  @override
  void destroyWorld() {
    final buf = PhysicsBuffer.fixed(5);
    buf.writeUint8(PhysicsPacket.destroyWorld);
    buf.writeInt32(_worldId);
    _send(buf.data);
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
    final buf = PhysicsBuffer.fixed(42);
    buf.writeUint8(PhysicsPacket.addBody);
    buf.writeInt32(_worldId);
    buf.writeInt32(id);
    buf.writeUint8(type.index);
    buf.writeFloat32(mass);
    buf.writeFloat32(drag);
    buf.writeFloat32(angularDrag);
    buf.writeBool(freezeRotation);
    buf.writeFloat32(gravityScale);
    buf.writeFloat32(position.dx);
    buf.writeFloat32(position.dy);
    buf.writeFloat32(rotation);
    _send(buf.data);
  }

  @override
  void removeBody(int id) {
    final buf = PhysicsBuffer.fixed(9);
    buf.writeUint8(PhysicsPacket.removeBody);
    buf.writeInt32(_worldId);
    buf.writeInt32(id);
    _send(buf.data);
  }

  @override
  void updateBody(int id,
      {double mass = 1.0,
      double drag = 0.0,
      double angularDrag = 0.05,
      bool freezeRotation = false,
      double gravityScale = 1.0}) {
    final buf = PhysicsBuffer.fixed(26);
    buf.writeUint8(PhysicsPacket.updateBody);
    buf.writeInt32(_worldId);
    buf.writeInt32(id);
    buf.writeFloat32(mass);
    buf.writeFloat32(drag);
    buf.writeFloat32(angularDrag);
    buf.writeBool(freezeRotation);
    buf.writeFloat32(gravityScale);
    _send(buf.data);
  }

  @override
  void addShape(int id, int bodyId, Collider collider) {
    // Calculate required size
    int size = 1 + 4 + 4 + 4 + 1 + 4 + 4 + 4 + 4 + 1 + 4 + 4 + 1; // Base fields + oneWay + shape type
    if (collider is BoxCollider) {
      size += 8;
    } else if (collider is CircleCollider) {
      size += 4;
    } else if (collider is PolygonCollider) {
      size += 4 + (collider.vertices.length * 8);
    } else if (collider is CapsuleCollider) {
      size += 4 + 4 + 1;
    } else if (collider is CompositeCollider) {
      size += 4; // count
      for (final shape in collider.shapes) {
        size += 8 + 8 + 1 + 1 + 9; // offset, material, trigger, sub-type + oneWay(9)
        if (shape is BoxGeometry) {
          size += 8;
        } else if (shape is CircleGeometry) {
          size += 4;
        } else if (shape is PolygonGeometry) {
          size += 4 + (shape.vertices.length * 8);
        } else if (shape is CapsuleGeometry) {
          size += 4 + 4 + 1;
        }
      }
    }

    final buf = PhysicsBuffer.fixed(size);
    buf.writeUint8(PhysicsPacket.addShape);
    buf.writeInt32(_worldId);
    buf.writeInt32(id);
    buf.writeInt32(bodyId);
    buf.writeBool(collider.isTrigger);
    buf.writeFloat32(collider.offset.dx);
    buf.writeFloat32(collider.offset.dy);
    buf.writeFloat32(collider.material.bounciness);
    buf.writeFloat32(collider.material.friction);
    buf.writeBool(collider.isOneWay);
    buf.writeFloat32(collider.oneWayAngle);
    buf.writeFloat32(collider.oneWayArc);

    if (collider is BoxCollider) {
      buf.writeUint8(0);
      buf.writeFloat32(collider.size.width);
      buf.writeFloat32(collider.size.height);
    } else if (collider is CircleCollider) {
      buf.writeUint8(1);
      buf.writeFloat32(collider.radius);
    } else if (collider is PolygonCollider) {
      buf.writeUint8(2);
      buf.writeInt32(collider.vertices.length);
      for (final v in collider.vertices) {
        buf.writeFloat32(v.dx);
        buf.writeFloat32(v.dy);
      }
    } else if (collider is CapsuleCollider) {
      buf.writeUint8(3);
      buf.writeFloat32(collider.radius);
      buf.writeFloat32(collider.height);
      buf.writeUint8(collider.direction == CapsuleDirection.vertical ? 1 : 0);
    } else if (collider is CompositeCollider) {
      buf.writeUint8(4);
      buf.writeInt32(collider.shapes.length);
      for (final shape in collider.shapes) {
        buf.writeFloat32(shape.offset.dx);
        buf.writeFloat32(shape.offset.dy);
        buf.writeFloat32(shape.material.bounciness);
        buf.writeFloat32(shape.material.friction);
        buf.writeBool(shape.isTrigger);
        buf.writeBool(shape.isOneWay);
        buf.writeFloat32(shape.oneWayAngle);
        buf.writeFloat32(shape.oneWayArc);

        if (shape is BoxGeometry) {
          buf.writeUint8(0);
          buf.writeFloat32(shape.size.width);
          buf.writeFloat32(shape.size.height);
        } else if (shape is CircleGeometry) {
          buf.writeUint8(1);
          buf.writeFloat32(shape.radius);
        } else if (shape is PolygonGeometry) {
          buf.writeUint8(2);
          buf.writeInt32(shape.vertices.length);
          for (final v in shape.vertices) {
            buf.writeFloat32(v.dx);
            buf.writeFloat32(v.dy);
          }
        } else if (shape is CapsuleGeometry) {
          buf.writeUint8(3);
          buf.writeFloat32(shape.radius);
          buf.writeFloat32(shape.height);
          buf.writeUint8(shape.direction == CapsuleDirection.vertical ? 1 : 0);
        }
      }
    }
    _send(buf.data);
  }

  @override
  void removeShape(int id) {
    final buf = PhysicsBuffer.fixed(9);
    buf.writeUint8(PhysicsPacket.removeShape);
    buf.writeInt32(_worldId);
    buf.writeInt32(id);
    _send(buf.data);
  }

  @override
  void addJoint(int id, Joint joint) {
    int size = 1 + 4 + 4 + 4 + 4 + 1; // base fields
    if (joint is DistanceJoint) {
      size += 8 + 8 + 4;
    } else if (joint is HingeJoint) {
      size += 8 + 8;
    } else if (joint is SpringJoint) {
      size += 8 + 8 + 4 + 4 + 4;
    } else if (joint is SliderJoint) {
      size += 8 + 8 + 8;
    } else if (joint is WheelJoint) {
      size += 8 + 8 + 8;
    } else if (joint is FixedJoint) {
      size += 8 + 8 + 4;
    } else if (joint is FrictionJoint) {
      size += 8 + 8 + 4 + 4;
    } else if (joint is RelativeJoint) {
      size += 8 + 4 + 4 + 4;
    } else if (joint is TargetJoint) {
      size += 8 + 4 + 4 + 4;
    }

    final buf = PhysicsBuffer.fixed(size);
    buf.writeUint8(PhysicsPacket.addJoint);
    buf.writeInt32(_worldId);
    buf.writeInt32(id);
    buf.writeInt32(joint.bodyAId);
    buf.writeInt32(joint.bodyBId);

    if (joint is DistanceJoint) {
      buf.writeUint8(PhysicsPacket.jointDistance);
      buf.writeFloat32(joint.anchorA.dx);
      buf.writeFloat32(joint.anchorA.dy);
      buf.writeFloat32(joint.anchorB.dx);
      buf.writeFloat32(joint.anchorB.dy);
      buf.writeFloat32(joint.length);
    } else if (joint is HingeJoint) {
      buf.writeUint8(PhysicsPacket.jointHinge);
      buf.writeFloat32(joint.anchorA.dx);
      buf.writeFloat32(joint.anchorA.dy);
      buf.writeFloat32(joint.anchorB.dx);
      buf.writeFloat32(joint.anchorB.dy);
    } else if (joint is SpringJoint) {
      buf.writeUint8(PhysicsPacket.jointSpring);
      buf.writeFloat32(joint.anchorA.dx);
      buf.writeFloat32(joint.anchorA.dy);
      buf.writeFloat32(joint.anchorB.dx);
      buf.writeFloat32(joint.anchorB.dy);
      buf.writeFloat32(joint.restLength);
      buf.writeFloat32(joint.stiffness);
      buf.writeFloat32(joint.damping);
    } else if (joint is SliderJoint) {
      buf.writeUint8(PhysicsPacket.jointSlider);
      buf.writeFloat32(joint.anchorA.dx);
      buf.writeFloat32(joint.anchorA.dy);
      buf.writeFloat32(joint.anchorB.dx);
      buf.writeFloat32(joint.anchorB.dy);
      buf.writeFloat32(joint.axis.dx);
      buf.writeFloat32(joint.axis.dy);
    } else if (joint is WheelJoint) {
      buf.writeUint8(PhysicsPacket.jointWheel);
      buf.writeFloat32(joint.anchorA.dx);
      buf.writeFloat32(joint.anchorA.dy);
      buf.writeFloat32(joint.anchorB.dx);
      buf.writeFloat32(joint.anchorB.dy);
      buf.writeFloat32(joint.suspensionAxis.dx);
      buf.writeFloat32(joint.suspensionAxis.dy);
    } else if (joint is FixedJoint) {
      buf.writeUint8(PhysicsPacket.jointFixed);
      buf.writeFloat32(joint.localAnchorA.dx);
      buf.writeFloat32(joint.localAnchorA.dy);
      buf.writeFloat32(joint.localAnchorB.dx);
      buf.writeFloat32(joint.localAnchorB.dy);
      buf.writeFloat32(joint.referenceAngle);
    } else if (joint is FrictionJoint) {
      buf.writeUint8(PhysicsPacket.jointFriction);
      buf.writeFloat32(joint.localAnchorA.dx);
      buf.writeFloat32(joint.localAnchorA.dy);
      buf.writeFloat32(joint.localAnchorB.dx);
      buf.writeFloat32(joint.localAnchorB.dy);
      buf.writeFloat32(joint.maxForce);
      buf.writeFloat32(joint.maxTorque);
    } else if (joint is RelativeJoint) {
      buf.writeUint8(PhysicsPacket.jointRelative);
      buf.writeFloat32(joint.linearOffset.dx);
      buf.writeFloat32(joint.linearOffset.dy);
      buf.writeFloat32(joint.angularOffset);
      buf.writeFloat32(joint.maxForce);
      buf.writeFloat32(joint.maxTorque);
    } else if (joint is TargetJoint) {
      buf.writeUint8(PhysicsPacket.jointTarget);
      buf.writeFloat32(joint.target.dx);
      buf.writeFloat32(joint.target.dy);
      buf.writeFloat32(joint.maxForce);
      buf.writeFloat32(joint.frequency);
      buf.writeFloat32(joint.dampingRatio);
    }
    _send(buf.data);
  }

  @override
  void removeJoint(int id) {
    final buf = PhysicsBuffer.fixed(9);
    buf.writeUint8(PhysicsPacket.removeJoint);
    buf.writeInt32(_worldId);
    buf.writeInt32(id);
    _send(buf.data);
  }

  @override
  void applyForce(int bodyId, Offset force) {
    final buf = PhysicsBuffer.fixed(17);
    buf.writeUint8(PhysicsPacket.applyForce);
    buf.writeInt32(_worldId);
    buf.writeInt32(bodyId);
    buf.writeFloat32(force.dx);
    buf.writeFloat32(force.dy);
    _send(buf.data);
  }

  @override
  void applyImpulse(int bodyId, Offset impulse) {
    final buf = PhysicsBuffer.fixed(17);
    buf.writeUint8(PhysicsPacket.applyImpulse);
    buf.writeInt32(_worldId);
    buf.writeInt32(bodyId);
    buf.writeFloat32(impulse.dx);
    buf.writeFloat32(impulse.dy);
    _send(buf.data);
  }

  @override
  void applyTorque(int bodyId, double torque) {
    final buf = PhysicsBuffer.fixed(13);
    buf.writeUint8(PhysicsPacket.applyTorque);
    buf.writeInt32(_worldId);
    buf.writeInt32(bodyId);
    buf.writeFloat32(torque);
    _send(buf.data);
  }

  @override
  void applyAngularImpulse(int bodyId, double impulse) {
    final buf = PhysicsBuffer.fixed(13);
    buf.writeUint8(PhysicsPacket.applyAngularImpulse);
    buf.writeInt32(_worldId);
    buf.writeInt32(bodyId);
    buf.writeFloat32(impulse);
    _send(buf.data);
  }

  @override
  void setGravity(Offset gravity) {
    final buf = PhysicsBuffer.fixed(13);
    buf.writeUint8(PhysicsPacket.setGravity);
    buf.writeInt32(_worldId);
    buf.writeFloat32(gravity.dx);
    buf.writeFloat32(gravity.dy);
    _send(buf.data);
  }

  @override
  void syncVelocity(int bodyId, Offset velocity) {
    final buf = PhysicsBuffer.fixed(17);
    buf.writeUint8(PhysicsPacket.syncVelocity);
    buf.writeInt32(_worldId);
    buf.writeInt32(bodyId);
    buf.writeFloat32(velocity.dx);
    buf.writeFloat32(velocity.dy);
    _send(buf.data);
  }

  @override
  void syncAngularVelocity(int bodyId, double velocity) {
    final buf = PhysicsBuffer.fixed(13);
    buf.writeUint8(PhysicsPacket.syncAngularVelocity);
    buf.writeInt32(_worldId);
    buf.writeInt32(bodyId);
    buf.writeFloat32(velocity);
    _send(buf.data);
  }

  @override
  void step(double dt, Map<int, PhysicsTransformSync> sync) {
    final buf =
        PhysicsBuffer.fixed(13 + (sync.length * 16));
    buf.writeUint8(PhysicsPacket.step);
    buf.writeInt32(_worldId);
    buf.writeFloat32(dt);
    buf.writeInt32(sync.length);
    for (final entry in sync.entries) {
      buf.writeInt32(entry.key);
      buf.writeFloat32(entry.value.position.dx);
      buf.writeFloat32(entry.value.position.dy);
      buf.writeFloat32(entry.value.rotation);
    }
    _send(buf.data);
  }

  @override
  void raycast(
      int requestId, Offset origin, Offset direction, double maxDistance) {
    final buf = PhysicsBuffer.fixed(25);
    buf.writeUint8(PhysicsPacket.raycast);
    buf.writeInt32(_worldId);
    buf.writeInt32(requestId);
    buf.writeFloat32(origin.dx);
    buf.writeFloat32(origin.dy);
    buf.writeFloat32(direction.dx);
    buf.writeFloat32(direction.dy);
    buf.writeFloat32(maxDistance);
    _send(buf.data);
  }
}
