import 'dart:typed_data';

class PhysicsPacket {
  static const int createWorld = 0x01;
  static const int destroyWorld = 0x02;
  static const int addBody = 0x03;
  static const int removeBody = 0x04;
  static const int updateBody = 0x05;
  static const int addShape = 0x06;
  static const int removeShape = 0x07;
  static const int applyForce = 0x08;
  static const int applyImpulse = 0x09;
  static const int applyTorque = 0x0A;
  static const int applyAngularImpulse = 0x0B;
  static const int setGravity = 0x0C;
  static const int raycast = 0x0D;
  static const int syncVelocity = 0x0E;
  static const int syncAngularVelocity = 0x0F;
  static const int step = 0x10;
  static const int addJoint = 0x11;
  static const int removeJoint = 0x12;
  static const int stepResult = 0x80;
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

class PhysicsBuffer {
  final ByteData data;
  int _offset = 0;
  PhysicsBuffer(this.data);
  PhysicsBuffer.fixed(int size) : data = ByteData(size);
  int get offset => _offset;
  void writeUint8(int value) => data.setUint8(_offset++, value);
  void writeInt32(int value) {
    data.setInt32(_offset, value, Endian.little);
    _offset += 4;
  }

  void writeFloat32(double value) {
    data.setFloat32(_offset, value, Endian.little);
    _offset += 4;
  }

  void writeFloat64(double value) {
    data.setFloat64(_offset, value, Endian.little);
    _offset += 8;
  }

  void writeBool(bool value) => writeUint8(value ? 1 : 0);
  int readUint8() => data.getUint8(_offset++);
  int readInt32() {
    final v = data.getInt32(_offset, Endian.little);
    _offset += 4;
    return v;
  }

  double readFloat32() {
    final v = data.getFloat32(_offset, Endian.little);
    _offset += 4;
    return v;
  }

  double readFloat64() {
    final v = data.getFloat64(_offset, Endian.little);
    _offset += 8;
    return v;
  }

  bool readBool() => readUint8() == 1;
}
