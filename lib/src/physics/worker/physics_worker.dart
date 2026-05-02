import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/painting.dart';
import 'package:goo2d/src/physics/core/physics_world.dart';
import 'package:goo2d/src/physics/core/physics_body.dart';
import 'package:goo2d/src/physics/core/physics_shape.dart';
import 'package:goo2d/src/physics/core/physics_joint.dart';
import 'package:goo2d/src/physics/worker/physics_protocol.dart';

class PhysicsWorkerManager {
  final Map<int, PhysicsWorld> worlds = {};
  final void Function(ByteData) onResponse;
  PhysicsWorkerManager({required this.onResponse});
  void handleMessage(ByteData message) {
    final buffer = PhysicsBuffer(message);
    final packetId = buffer.readUint8();
    final worldId = buffer.readInt32();

    if (packetId == PhysicsPacket.createWorld) {
      worlds[worldId] = PhysicsWorld();
      return;
    }

    final world = worlds[worldId];
    if (world == null) return;

    switch (packetId) {
      case PhysicsPacket.destroyWorld:
        worlds.remove(worldId);
        break;

      case PhysicsPacket.addBody:
        final id = buffer.readInt32();
        final type = buffer.readUint8();
        final body = PhysicsBody(id: id, type: type);
        body.setMass(buffer.readFloat32());
        body.drag = buffer.readFloat32();
        body.angularDrag = buffer.readFloat32();
        body.freezeRotation = buffer.readBool();
        body.gravityScale = buffer.readFloat32();
        body.position = Offset(buffer.readFloat32(), buffer.readFloat32());
        body.rotation = buffer.readFloat32();
        world.bodies[id] = body;
        break;

      case PhysicsPacket.removeBody:
        world.bodies.remove(buffer.readInt32());
        break;

      case PhysicsPacket.updateBody:
        final id = buffer.readInt32();
        final body = world.bodies[id];
        if (body != null) {
          body.setMass(buffer.readFloat32());
          body.drag = buffer.readFloat32();
          body.angularDrag = buffer.readFloat32();
          body.freezeRotation = buffer.readBool();
          body.gravityScale = buffer.readFloat32();
        }
        break;

      case PhysicsPacket.addShape:
        final shapeId = buffer.readInt32();
        final bodyId = buffer.readInt32();
        final body = world.bodies[bodyId];
        if (body == null) break;

        final isTrigger = buffer.readBool();
        final offsetX = buffer.readFloat32();
        final offsetY = buffer.readFloat32();
        final bounciness = buffer.readFloat32();
        final friction = buffer.readFloat32();
        final isOneWay = buffer.readBool();
        final oneWayAngle = buffer.readFloat32();
        final oneWayArc = buffer.readFloat32();
        final shapeType = buffer.readUint8();

        if (shapeType == PhysicsPacket.shapeComposite) {
          final count = buffer.readInt32();
          for (int i = 0; i < count; i++) {
            final sOffX = buffer.readFloat32();
            final sOffY = buffer.readFloat32();
            final sB = buffer.readFloat32();
            final sF = buffer.readFloat32();
            final sTrig = buffer.readBool();
            final sOW = buffer.readBool();
            final sOWAngle = buffer.readFloat32();
            final sOWArc = buffer.readFloat32();
            final sType = buffer.readUint8();

            final shape = _readShape(buffer, sType);
            shape.id = shapeId;
            shape.isTrigger = sTrig;
            shape.localOffset = Offset(sOffX, sOffY) + Offset(offsetX, offsetY);
            shape.bounciness = sB;
            shape.friction = sF;
            shape.isOneWay = sOW;
            shape.oneWayAngle = sOWAngle;
            shape.oneWayArc = sOWArc;
            shape.body = body;
          }
        } else {
          final shape = _readShape(buffer, shapeType);
          shape.id = shapeId;
          shape.isTrigger = isTrigger;
          shape.localOffset = Offset(offsetX, offsetY);
          shape.bounciness = bounciness;
          shape.friction = friction;
          shape.isOneWay = isOneWay;
          shape.oneWayAngle = oneWayAngle;
          shape.oneWayArc = oneWayArc;
          shape.body = body;
        }
        break;

      case PhysicsPacket.removeShape:
        final id = buffer.readInt32();
        for (final body in world.bodies.values) {
          body.shapes.removeWhere((s) => s.id == id);
        }
        break;

      case PhysicsPacket.addJoint:
        final id = buffer.readInt32();
        final bodyAId = buffer.readInt32();
        final bodyBId = buffer.readInt32();
        final jointType = buffer.readUint8();

        Joint joint;
        if (jointType == PhysicsPacket.jointDistance) {
          joint = DistanceJoint(
            id: id,
            bodyAId: bodyAId,
            bodyBId: bodyBId,
            anchorA: Offset(buffer.readFloat32(), buffer.readFloat32()),
            anchorB: Offset(buffer.readFloat32(), buffer.readFloat32()),
            length: buffer.readFloat32(),
          );
        } else if (jointType == PhysicsPacket.jointHinge) {
          joint = HingeJoint(
            id: id,
            bodyAId: bodyAId,
            bodyBId: bodyBId,
            anchorA: Offset(buffer.readFloat32(), buffer.readFloat32()),
            anchorB: Offset(buffer.readFloat32(), buffer.readFloat32()),
          );
        } else if (jointType == PhysicsPacket.jointSpring) {
          joint = SpringJoint(
            id: id,
            bodyAId: bodyAId,
            bodyBId: bodyBId,
            anchorA: Offset(buffer.readFloat32(), buffer.readFloat32()),
            anchorB: Offset(buffer.readFloat32(), buffer.readFloat32()),
            restLength: buffer.readFloat32(),
            stiffness: buffer.readFloat32(),
            damping: buffer.readFloat32(),
          );
        } else if (jointType == PhysicsPacket.jointSlider) {
          joint = SliderJoint(
            id: id,
            bodyAId: bodyAId,
            bodyBId: bodyBId,
            anchorA: Offset(buffer.readFloat32(), buffer.readFloat32()),
            anchorB: Offset(buffer.readFloat32(), buffer.readFloat32()),
            axis: Offset(buffer.readFloat32(), buffer.readFloat32()),
          );
        } else if (jointType == PhysicsPacket.jointWheel) {
          joint = WheelJoint(
            id: id,
            bodyAId: bodyAId,
            bodyBId: bodyBId,
            anchorA: Offset(buffer.readFloat32(), buffer.readFloat32()),
            anchorB: Offset(buffer.readFloat32(), buffer.readFloat32()),
            suspensionAxis: Offset(buffer.readFloat32(), buffer.readFloat32()),
          );
        } else if (jointType == PhysicsPacket.jointFixed) {
          joint = FixedJoint(
            id: id,
            bodyAId: bodyAId,
            bodyBId: bodyBId,
            localAnchorA: Offset(buffer.readFloat32(), buffer.readFloat32()),
            localAnchorB: Offset(buffer.readFloat32(), buffer.readFloat32()),
            referenceAngle: buffer.readFloat32(),
          );
        } else if (jointType == PhysicsPacket.jointFriction) {
          joint = FrictionJoint(
            id: id,
            bodyAId: bodyAId,
            bodyBId: bodyBId,
            localAnchorA: Offset(buffer.readFloat32(), buffer.readFloat32()),
            localAnchorB: Offset(buffer.readFloat32(), buffer.readFloat32()),
            maxForce: buffer.readFloat32(),
            maxTorque: buffer.readFloat32(),
          );
        } else if (jointType == PhysicsPacket.jointRelative) {
          joint = RelativeJoint(
            id: id,
            bodyAId: bodyAId,
            bodyBId: bodyBId,
            linearOffset: Offset(buffer.readFloat32(), buffer.readFloat32()),
            angularOffset: buffer.readFloat32(),
            maxForce: buffer.readFloat32(),
            maxTorque: buffer.readFloat32(),
          );
        } else if (jointType == PhysicsPacket.jointTarget) {
          joint = TargetJoint(
            id: id,
            bodyAId: bodyAId,
            bodyBId: bodyBId,
            target: Offset(buffer.readFloat32(), buffer.readFloat32()),
            maxForce: buffer.readFloat32(),
            frequency: buffer.readFloat32(),
            dampingRatio: buffer.readFloat32(),
          );
        } else {
          break;
        }

        world.joints[id] = joint;
        break;

      case PhysicsPacket.removeJoint:
        world.joints.remove(buffer.readInt32());
        break;

      case PhysicsPacket.applyForce:
        final body = world.bodies[buffer.readInt32()];
        body?.applyForce(Offset(buffer.readFloat32(), buffer.readFloat32()));
        break;

      case PhysicsPacket.applyImpulse:
        final body = world.bodies[buffer.readInt32()];
        body?.applyImpulse(Offset(buffer.readFloat32(), buffer.readFloat32()));
        break;

      case PhysicsPacket.applyTorque:
        final body = world.bodies[buffer.readInt32()];
        body?.applyTorque(buffer.readFloat32());
        break;

      case PhysicsPacket.applyAngularImpulse:
        final body = world.bodies[buffer.readInt32()];
        body?.applyAngularImpulse(buffer.readFloat32());
        break;

      case PhysicsPacket.setGravity:
        world.gravity = Offset(buffer.readFloat32(), buffer.readFloat32());
        break;

      case PhysicsPacket.syncVelocity:
        final body = world.bodies[buffer.readInt32()];
        if (body != null) {
          body.velocity = Offset(buffer.readFloat32(), buffer.readFloat32());
        }
        break;

      case PhysicsPacket.syncAngularVelocity:
        final body = world.bodies[buffer.readInt32()];
        if (body != null) {
          body.angularVelocity = buffer.readFloat32();
        }
        break;

      case PhysicsPacket.raycast:
        final requestId = buffer.readInt32();
        final origin = Offset(buffer.readFloat32(), buffer.readFloat32());
        final direction = Offset(buffer.readFloat32(), buffer.readFloat32());
        final maxDistance = buffer.readFloat32();

        final hit = world.raycast(origin, direction, maxDistance);

        final respBuf = PhysicsBuffer.fixed(37);
        respBuf.writeUint8(PhysicsPacket.raycastResult);
        respBuf.writeInt32(worldId);
        respBuf.writeInt32(requestId);
        respBuf.writeBool(hit != null);
        if (hit != null) {
          respBuf.writeInt32(hit.shapeId);
          respBuf.writeFloat32(hit.point.dx);
          respBuf.writeFloat32(hit.point.dy);
          respBuf.writeFloat32(hit.normal.dx);
          respBuf.writeFloat32(hit.normal.dy);
          respBuf.writeFloat32(hit.distance);
          respBuf.writeFloat32(hit.fraction);
        }
        onResponse(respBuf.data);
        break;

      case PhysicsPacket.step:
        final dt = buffer.readFloat32();
        final kinCount = buffer.readInt32();
        for (int i = 0; i < kinCount; i++) {
          final id = buffer.readInt32();
          final px = buffer.readFloat32();
          final py = buffer.readFloat32();
          final rot = buffer.readFloat32();
          final body = world.bodies[id];
          if (body != null) {
            body.position = Offset(px, py);
            body.rotation = rot;
          }
        }

        final result = world.step(dt);

        // Encode step result
        final dynamicBodies = world.bodies.values
            .where((b) => b.type == 0)
            .toList(); // dynamic
        final respSize =
            1 +
            4 +
            4 +
            (dynamicBodies.length * 28) +
            4 +
            (result.contacts.length * 32);
        final respBuf = PhysicsBuffer.fixed(respSize);
        respBuf.writeUint8(PhysicsPacket.stepResult);
        respBuf.writeInt32(worldId);
        respBuf.writeInt32(dynamicBodies.length);
        for (final b in dynamicBodies) {
          respBuf.writeInt32(b.id);
          respBuf.writeFloat32(b.position.dx);
          respBuf.writeFloat32(b.position.dy);
          respBuf.writeFloat32(b.rotation);
          respBuf.writeFloat32(b.velocity.dx);
          respBuf.writeFloat32(b.velocity.dy);
          respBuf.writeFloat32(b.angularVelocity);
        }

        respBuf.writeInt32(result.contacts.length);
        for (final c in result.contacts) {
          respBuf.writeInt32(c.shapeAId);
          respBuf.writeInt32(c.shapeBId);
          respBuf.writeFloat32(c.manifold.contactPoint.dx);
          respBuf.writeFloat32(c.manifold.contactPoint.dy);
          respBuf.writeFloat32(c.manifold.normal.dx);
          respBuf.writeFloat32(c.manifold.normal.dy);
          respBuf.writeFloat32(c.impulse);
        }

        onResponse(respBuf.data);
        break;
    }
  }

  PhysicsShape _readShape(PhysicsBuffer buffer, int shapeType) {
    if (shapeType == 0) {
      // Box
      return PhysicsBox(buffer.readFloat32(), buffer.readFloat32());
    } else if (shapeType == 1) {
      // Circle
      return PhysicsCircle(buffer.readFloat32());
    } else if (shapeType == 2) {
      // Polygon
      final count = buffer.readInt32();
      final verts = List.generate(
        count,
        (_) => Offset(buffer.readFloat32(), buffer.readFloat32()),
      );
      return PhysicsPolygon(verts);
    } else {
      return PhysicsCapsule(
        buffer.readFloat32(),
        buffer.readFloat32(),
        buffer.readUint8() == 1
            ? CapsuleDirection.vertical
            : CapsuleDirection.horizontal,
      );
    }
  }
}

void physicsWorkerEntry(SendPort mainSendPort) {
  final workerReceivePort = ReceivePort();
  mainSendPort.send(workerReceivePort.sendPort);

  final manager = PhysicsWorkerManager(
    onResponse: (data) => mainSendPort.send(data),
  );

  workerReceivePort.listen((message) {
    if (message is ByteData) {
      manager.handleMessage(message);
    }
  });
}
