import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/painting.dart';
import 'physics_world.dart';
import 'physics_protocol.dart';

/// Manages multiple physics worlds within a background Isolate.
/// 
/// [PhysicsWorkerManager] processes binary messages from the main thread, 
/// routes them to the correct [PhysicsWorld] instance, and sends back 
/// simulation results. It acts as the orchestration layer for all background 
/// physical simulations.
/// 
/// ```dart
/// final worker = PhysicsWorkerManager(onResponse: (data) => print('Sent!'));
/// ```
class PhysicsWorkerManager {
  /// Map of world IDs to their respective physics simulations.
  /// 
  /// Each ID corresponds to a [PhysicsWorld] instance managed by this worker.
  final Map<int, PhysicsWorld> worlds = {};
  
  /// Callback used to send serialized responses back to the main thread.
  /// 
  /// This typically wraps a [SendPort] to communicate across Isolate boundaries.
  final void Function(ByteData) onResponse;

  /// Creates a [PhysicsWorkerManager].
  /// 
  /// * [onResponse]: The handler for sending binary packets back to the main thread.
  PhysicsWorkerManager({required this.onResponse});

  /// Decodes and executes a binary [message].
  /// 
  /// This is the main entry point for commands sent from the [WorkerPhysicsBridge]. 
  /// It uses a [PhysicsBuffer] to parse the opcode and data payload.
  /// 
  /// * [message]: The raw binary data received from the main thread.
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
          shape = PhysicsCapsule(
              buffer.readFloat32(), buffer.readFloat32(), buffer.readUint8() == 1);
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
        final id = buffer.readInt32();
        for (final body in world.bodies.values) {
          body.shapes.removeWhere((s) => s.id == id);
        }
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
        final dynamicBodies =
            world.bodies.values.where((b) => b.type == 0).toList(); // dynamic
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
}

/// The entry point for the physics Isolate.
/// 
/// This function is called by [Isolate.spawn] and establishes the 
/// communication channel with the main thread.
/// 
/// * [mainSendPort]: The port used to communicate back to the main isolate.
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
