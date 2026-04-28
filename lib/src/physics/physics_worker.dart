import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/painting.dart';
import 'physics_world.dart';
import 'physics_protocol.dart';

void physicsWorkerEntry(SendPort mainSendPort) {
  final workerReceivePort = ReceivePort();
  mainSendPort.send(workerReceivePort.sendPort);

  final Map<int, PhysicsWorld> worlds = {};

  workerReceivePort.listen((message) {
    if (message is! ByteData) return;

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

      case PhysicsPacket.syncVelocity:
        final id = buffer.readInt32();
        final body = world.bodies[id];
        if (body != null) {
          body.velocity = Offset(buffer.readFloat32(), buffer.readFloat32());
        }
        break;

      case PhysicsPacket.syncAngularVelocity:
        final id = buffer.readInt32();
        final body = world.bodies[id];
        if (body != null) {
          body.angularVelocity = buffer.readFloat32();
        }
        break;

      case PhysicsPacket.addShape:
        final shapeId = buffer.readInt32();
        final bodyId = buffer.readInt32();
        final isTrigger = buffer.readBool();
        final offsetX = buffer.readFloat32();
        final offsetY = buffer.readFloat32();
        final bounciness = buffer.readFloat32();
        final friction = buffer.readFloat32();
        final shapeType = buffer.readUint8();

        PhysicsShape shape;
        if (shapeType == 0) { // Box
          shape = PhysicsBox(buffer.readFloat32(), buffer.readFloat32());
        } else if (shapeType == 1) { // Circle
          shape = PhysicsCircle(buffer.readFloat32());
        } else if (shapeType == 2) { // Polygon
          final count = buffer.readInt32();
          final verts = <Offset>[];
          for (int i = 0; i < count; i++) {
            verts.add(Offset(buffer.readFloat32(), buffer.readFloat32()));
          }
          shape = PhysicsPolygon(verts);
        } else { // Capsule
          shape = PhysicsCapsule(buffer.readFloat32(), buffer.readFloat32(), buffer.readUint8() == 0);
        }

        shape.id = shapeId;
        shape.isTrigger = isTrigger;
        shape.localOffset = Offset(offsetX, offsetY);
        shape.bounciness = bounciness;
        shape.friction = friction;

        final body = world.bodies[bodyId];
        if (body != null) {
          shape.body = body;
        }
        break;

      case PhysicsPacket.removeShape:
        final shapeId = buffer.readInt32();
        for (final body in world.bodies.values) {
          body.shapes.removeWhere((s) => s.id == shapeId);
        }
        break;

      case PhysicsPacket.applyForce:
        final id = buffer.readInt32();
        final body = world.bodies[id];
        if (body != null) {
          body.applyForce(Offset(buffer.readFloat32(), buffer.readFloat32()));
        }
        break;

      case PhysicsPacket.applyImpulse:
        final id = buffer.readInt32();
        final body = world.bodies[id];
        if (body != null) {
          body.applyImpulse(Offset(buffer.readFloat32(), buffer.readFloat32()));
        }
        break;

      case PhysicsPacket.applyTorque:
        final id = buffer.readInt32();
        final body = world.bodies[id];
        if (body != null) {
          body.applyTorque(buffer.readFloat32());
        }
        break;

      case PhysicsPacket.applyAngularImpulse:
        final id = buffer.readInt32();
        final body = world.bodies[id];
        if (body != null) {
          body.applyAngularImpulse(buffer.readFloat32());
        }
        break;

      case PhysicsPacket.setGravity:
        world.gravity = Offset(buffer.readFloat32(), buffer.readFloat32());
        break;

      case PhysicsPacket.raycast:
        final requestId = buffer.readInt32();
        final origin = Offset(buffer.readFloat32(), buffer.readFloat32());
        final dir = Offset(buffer.readFloat32(), buffer.readFloat32());
        final maxDist = buffer.readFloat32();
        
        final hit = world.raycast(origin, dir, maxDist);
        
        final respSize = 1 + 4 + 4 + 1 + (hit != null ? (4 + 4 + 4 + 4 + 4 + 4 + 4) : 0);
        final respBuf = PhysicsBuffer.fixed(respSize);
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
        mainSendPort.send(respBuf.data);
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
        final dynamicBodies = world.bodies.values.where((b) => b.type == 0).toList(); // dynamic
        final respSize = 1 + 4 + 4 + (dynamicBodies.length * 28) + 4 + (result.contacts.length * 32);
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
        
        mainSendPort.send(respBuf.data);
        break;
    }
  });
}
