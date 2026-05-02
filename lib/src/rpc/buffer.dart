import 'dart:typed_data';

class Uint8Buffer {
  static const defaultCapacity = 4096;

  Uint8List _buffer;
  int _offset = 0;

  late ByteData _byteData = ByteData.view(_buffer.buffer);
  Uint8Buffer([int initialCapacity = defaultCapacity])
    : _buffer = Uint8List(initialCapacity);
  ByteData get byteData => _byteData;
  void write(int size, void Function() writer) {
    ensureCapacity(size);
    writer();
    _offset += size;
  }

  int get offset => _offset;
  void skip(int length) => _offset += length;
  void ensureCapacity(int capacity, [double growthFactor = 1.5]) {
    if (_offset + capacity > _buffer.length) {
      final newCapacity = (_buffer.length * growthFactor).round();
      assert(
        newCapacity > _buffer.length,
        'Capacity growth is not enough for growth factor $growthFactor',
      );
      final newBuffer = Uint8List(newCapacity);
      newBuffer.setRange(_offset, 0, _buffer, 0);
      _buffer = newBuffer;
      _byteData = ByteData.view(_buffer.buffer);
    }
  }

  Uint8List get compact => _buffer.sublist(0, _offset);
}
