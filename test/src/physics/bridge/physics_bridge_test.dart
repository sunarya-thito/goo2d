import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/painting.dart';
import 'package:goo2d/goo2d.dart';
import 'package:goo2d/src/physics/worker/physics_worker.dart';
import 'package:goo2d/src/physics/worker/physics_protocol.dart';

void main() {
  group('Physics Worker & Protocol', () {
    test('PhysicsWorkerManager creates world', () {
      final manager = PhysicsWorkerManager(onResponse: (_) {});
      
      final buf = PhysicsBuffer.fixed(5);
      buf.writeUint8(PhysicsPacket.createWorld);
      buf.writeInt32(101);
      
      manager.handleMessage(buf.data);
      expect(manager.worlds.containsKey(101), isTrue);
    });

    test('PhysicsWorkerManager adds and removes body', () {
      final manager = PhysicsWorkerManager(onResponse: (_) {});
      
      // Create world 1
      var buf = PhysicsBuffer.fixed(5);
      buf.writeUint8(PhysicsPacket.createWorld);
      buf.writeInt32(1);
      manager.handleMessage(buf.data);
      
      // Add dynamic body 10
      buf = PhysicsBuffer.fixed(1 + 4 + 4 + 1 + 4 + 4 + 4 + 1 + 4 + 4 + 4 + 4);
      buf.writeUint8(PhysicsPacket.addBody);
      buf.writeInt32(1); // worldId
      buf.writeInt32(10); // bodyId
      buf.writeUint8(0); // type dynamic
      buf.writeFloat32(5.0); // mass
      buf.writeFloat32(0.1); // drag
      buf.writeFloat32(0.2); // angularDrag
      buf.writeBool(false); // freezeRotation
      buf.writeFloat32(1.0); // gravityScale
      buf.writeFloat32(100.0); // posX
      buf.writeFloat32(200.0); // posY
      buf.writeFloat32(0.5); // rotation
      
      manager.handleMessage(buf.data);
      
      final world = manager.worlds[1]!;
      expect(world.bodies.containsKey(10), isTrue);
      final body = world.bodies[10]!;
      expect(body.mass, 5.0);
      expect(body.position, const Offset(100, 200));
      expect(body.rotation, 0.5);
      
      // Remove body
      buf = PhysicsBuffer.fixed(9);
      buf.writeUint8(PhysicsPacket.removeBody);
      buf.writeInt32(1);
      buf.writeInt32(10);
      manager.handleMessage(buf.data);
      expect(world.bodies.containsKey(10), isFalse);
    });

    test('PhysicsWorkerManager step returns results', () {
      ByteData? response;
      final manager = PhysicsWorkerManager(onResponse: (data) => response = data);
      
      // Setup world with one dynamic body
      var buf = PhysicsBuffer.fixed(5);
      buf.writeUint8(PhysicsPacket.createWorld);
      buf.writeInt32(1);
      manager.handleMessage(buf.data);
      
      buf = PhysicsBuffer.fixed(41); // body packet size
      buf.writeUint8(PhysicsPacket.addBody);
      buf.writeInt32(1);
      buf.writeInt32(1);
      buf.writeUint8(0); // dynamic
      buf.writeFloat32(1.0); // mass
      buf.writeFloat32(0.0); // drag
      buf.writeFloat32(0.0); // angularDrag
      buf.writeBool(false);
      buf.writeFloat32(1.0); // gravityScale
      buf.writeFloat32(0.0); // posX
      buf.writeFloat32(0.0); // posY
      buf.writeFloat32(0.0); // rot
      manager.handleMessage(buf.data);
      
      // Step
      buf = PhysicsBuffer.fixed(1 + 4 + 4 + 4);
      buf.writeUint8(PhysicsPacket.step);
      buf.writeInt32(1);
      buf.writeFloat32(0.1);
      buf.writeInt32(0); // no kinematic syncs
      
      manager.handleMessage(buf.data);
      
      expect(response, isNotNull);
      final respBuf = PhysicsBuffer(response!);
      expect(respBuf.readUint8(), PhysicsPacket.stepResult);
      expect(respBuf.readInt32(), 1); // worldId
      expect(respBuf.readInt32(), 1); // dynamic body count
      expect(respBuf.readInt32(), 1); // bodyId
      
      // After 0.1s with gravity 980, pos.y should be g * dt^2 = 980 * 0.1^2 = 9.8
      final py = respBuf.readFloat32(); // posX
      final pyVal = respBuf.readFloat32(); // posY
      expect(pyVal, closeTo(9.8, 0.001));
    });
  });
}
