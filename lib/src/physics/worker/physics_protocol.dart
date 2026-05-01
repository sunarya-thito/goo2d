import 'dart:typed_data';

/// Defines the operation codes for the binary physics protocol.
/// 
/// These constants are used to identify the type of message being sent 
/// between the main thread and the physics worker Isolate. They ensure 
/// both sides agree on the interpretation of the [ByteData] packets.
/// 
/// ```dart
/// buffer.writeUint8(PhysicsPacket.applyForce);
/// buffer.writeInt32(bodyId);
/// ```
class PhysicsPacket {
  /// Command to create a new physics world.
  /// 
  /// Initializes the internal Forge2D instance and prepares for body registration.
  static const int createWorld = 0x01;
  
  /// Command to destroy the current physics world.
  /// 
  /// Releases all allocated memory and clears body/collider registries in the worker.
  static const int destroyWorld = 0x02;
  
  /// Command to add a [Rigidbody] to the world.
  /// 
  /// The payload specifies the unique ID and movement behavior (static/dynamic).
  static const int addBody = 0x03;
  
  /// Command to remove a [Rigidbody] from the world.
  /// 
  /// Effectively unregisters the body from the simulation and removes all its shapes.
  static const int removeBody = 0x04;
  
  /// Command to update the properties of an existing body.
  /// 
  /// Synchronizes mass, drag, and gravity scale between the main thread and worker.
  static const int updateBody = 0x05;
  
  /// Command to add a [Collider] to a body.
  /// 
  /// Attaches a geometric shape and its physical material to a registered body.
  static const int addShape = 0x06;
  
  /// Command to remove a [Collider].
  /// 
  /// Removes the shape from its parent body and the broad-phase detection.
  static const int removeShape = 0x07;
  
  /// Command to apply a continuous force.
  /// 
  /// Forces are applied at the center of mass and accumulate over the current step.
  static const int applyForce = 0x08;
  
  /// Command to apply an instantaneous impulse.
  /// 
  /// Results in an immediate velocity change without being affected by time.
  static const int applyImpulse = 0x09;
  
  /// Command to apply a torque.
  /// 
  /// Applies rotational acceleration to a body based on its moment of inertia.
  static const int applyTorque = 0x0A;
  
  /// Command to apply an angular impulse.
  /// 
  /// Instantly changes the rotational velocity of a body.
  static const int applyAngularImpulse = 0x0B;
  
  /// Command to change the global gravity vector.
  /// 
  /// Updates the acceleration vector applied to all dynamic bodies in the world.
  static const int setGravity = 0x0C;
  
  /// Command to perform a raycast.
  /// 
  /// Dispatches a query to find the nearest intersection along a world-space ray.
  static const int raycast = 0x0D;
  
  /// Command to synchronize linear velocity.
  /// 
  /// Explicitly sets the velocity of a body, overwriting simulation results.
  static const int syncVelocity = 0x0E;
  
  /// Command to synchronize angular velocity.
  /// 
  /// Explicitly sets the rotational speed of a body.
  static const int syncAngularVelocity = 0x0F;
  
  /// Command to advance the simulation by a fixed time step.
  /// 
  /// Triggers integration and collision resolution for the specified duration.
  static const int step = 0x10;
  
  /// Command to add a [Joint] to the simulation.
  static const int addJoint = 0x11;
  
  /// Command to remove a [Joint].
  static const int removeJoint = 0x12;

  /// Response containing the updated state of all dynamic bodies.
  /// 
  /// Includes positions, rotations, and velocities for synchronization with the engine.
  static const int stepResult = 0x80;
  
  /// Response containing the result of a raycast request.
  /// 
  /// Returns intersection data or a null indicator back to the requesting system.
  static const int raycastResult = 0x81;

  // Joint Types
  static const int jointDistance = 0;
  static const int jointHinge = 1;
  static const int jointSpring = 2;
  static const int jointSlider = 3;
  static const int jointWheel = 4;
  static const int jointFixed = 5;
  static const int jointFriction = 6;
  static const int jointRelative = 7;
  static const int jointTarget = 8;

  // Shape Types
  static const int shapeBox = 0;
  static const int shapeCircle = 1;
  static const int shapePolygon = 2;
  static const int shapeCapsule = 3;
  static const int shapeComposite = 4;
}

/// Helper for reading and writing binary physics data in a stream-like fashion.
/// 
/// [PhysicsBuffer] provides a wrapper around [ByteData] with an internal 
/// offset that advances automatically after each read or write operation. 
/// It uses little-endian byte order for all multi-byte values.
/// 
/// ```dart
/// final buffer = PhysicsBuffer.fixed(12);
/// buffer.writeFloat32(1.0);
/// buffer.writeFloat32(2.0);
/// ```
class PhysicsBuffer {
  /// The underlying byte data.
  /// 
  /// Stores the binary representation of the physics packets.
  final ByteData data;

  /// The current read/write offset.
  /// 
  /// Automatically advanced after every read or write operation.
  int _offset = 0;

  /// Creates a [PhysicsBuffer] from existing [data].
  /// 
  /// The internal offset starts at zero. Useful for reading responses 
  /// from the physics worker.
  /// 
  /// * [data]: The source byte data.
  PhysicsBuffer(this.data);
  
  /// Creates a [PhysicsBuffer] with a fixed [size] in bytes.
  /// 
  /// Allocates a new [ByteData] instance. Useful for building command 
  /// packets to send to the worker.
  /// 
  /// * [size]: Capacity in bytes.
  PhysicsBuffer.fixed(int size) : data = ByteData(size);

  /// The current read/write offset.
  /// 
  /// Represents the byte position for the next operation in the [data] buffer.
  int get offset => _offset;

  /// Writes a single byte.
  /// 
  /// * [value]: The byte value (0-255).
  void writeUint8(int value) => data.setUint8(_offset++, value);
  
  /// Writes a 32-bit signed integer.
  /// 
  /// * [value]: The integer value.
  void writeInt32(int value) {
    data.setInt32(_offset, value, Endian.little);
    _offset += 4;
  }
  
  /// Writes a 32-bit float and advances the offset.
  /// 
  /// Uses little-endian byte order. Commonly used for position and 
  /// velocity components to save space over 64-bit doubles.
  /// 
  /// * [value]: The double value to write as float.
  void writeFloat32(double value) {
    data.setFloat32(_offset, value, Endian.little);
    _offset += 4;
  }
  
  /// Writes a 64-bit float and advances the offset.
  /// 
  /// Uses little-endian byte order. Used for high-precision physical 
  /// constants or accumulated time.
  /// 
  /// * [value]: The double value.
  void writeFloat64(double value) {
    data.setFloat64(_offset, value, Endian.little);
    _offset += 8;
  }
  
  /// Writes a boolean as a single byte (0 or 1).
  /// 
  /// The offset is advanced by 1 byte after the operation.
  /// 
  /// * [value]: The boolean to serialize.
  void writeBool(bool value) => writeUint8(value ? 1 : 0);

  /// Reads a single byte and advances the offset.
  /// 
  /// Returns the value as an unsigned 8-bit integer.
  int readUint8() => data.getUint8(_offset++);
  
  /// Reads a 32-bit signed integer and advances the offset.
  /// 
  /// Decodes the value using little-endian byte order.
  int readInt32() {
    final v = data.getInt32(_offset, Endian.little);
    _offset += 4;
    return v;
  }
  
  /// Reads a 32-bit float and advances the offset.
  /// 
  /// Returns the value as a Dart double.
  double readFloat32() {
    final v = data.getFloat32(_offset, Endian.little);
    _offset += 4;
    return v;
  }
  
  /// Reads a 64-bit float and advances the offset.
  /// 
  /// Returns the high-precision double value.
  double readFloat64() {
    final v = data.getFloat64(_offset, Endian.little);
    _offset += 8;
    return v;
  }
  
  /// Reads a boolean value and advances the offset.
  /// 
  /// Decodes the value by checking if the next byte is equal to 1.
  bool readBool() => readUint8() == 1;
}
