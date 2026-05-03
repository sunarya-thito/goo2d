import 'dart:typed_data';

/// A dynamic byte buffer for efficient binary data serialization.
///
/// [Uint8Buffer] provides a wrapper around [Uint8List] that automatically 
/// grows as needed. It is designed for write-heavy operations where 
/// data is appended sequentially, and it provides a [ByteData] view 
/// for typed writing (e.g., integers, floats).
///
/// ```dart
/// final buffer = Uint8Buffer();
/// 
/// buffer.write(4, () {
///   buffer.byteData.setUint32(buffer.offset, 12345);
/// });
/// 
/// final result = buffer.compact;
/// ```
///
/// See also:
/// * [Uint8List] for the underlying byte array.
/// * [ByteData] for the typed view used to write values.
class Uint8Buffer {
  /// The default initial capacity for a new buffer.
  ///
  /// This value is chosen to balance memory usage and the frequency 
  /// of reallocations for typical network packets.
  static const defaultCapacity = 4096;

  Uint8List _buffer;
  int _offset = 0;

  late ByteData _byteData = ByteData.view(_buffer.buffer);

  /// Creates a new buffer with the specified initial capacity.
  ///
  /// * [initialCapacity]: The starting size of the internal byte array.
  Uint8Buffer([int initialCapacity = defaultCapacity])
      : _buffer = Uint8List(initialCapacity);

  /// Returns a [ByteData] view of the entire internal buffer.
  ///
  /// This view is automatically updated whenever the internal buffer 
  /// grows. Use the [offset] property to determine the current 
  /// write position within this view.
  ByteData get byteData => _byteData;

  /// Appends a specific amount of data to the buffer using a callback.
  ///
  /// This method ensures that the buffer has enough capacity for the 
  /// [size] requested before executing the [writer] callback. After 
  /// the callback completes, the internal [offset] is advanced.
  ///
  /// * [size]: The number of bytes that will be written.
  /// * [writer]: A callback that performs the actual writing to [byteData].
  void write(int size, void Function() writer) {
    ensureCapacity(size);
    writer();
    _offset += size;
  }

  /// The current write position within the buffer.
  ///
  /// This offset indicates where the next byte will be written and 
  /// also represents the total number of bytes written so far.
  int get offset => _offset;

  /// Advances the write position without writing any data.
  ///
  /// This is useful for leaving space in a packet that will be 
  /// filled in later, such as a length header or a checksum.
  ///
  /// * [length]: The number of bytes to skip.
  void skip(int length) => _offset += length;

  /// Ensures the internal buffer has enough space for additional data.
  ///
  /// If the current capacity is insufficient, the buffer is reallocated 
  /// using the [growthFactor] to minimize future allocations.
  ///
  /// * [capacity]: The required additional space.
  /// * [growthFactor]: The multiplier used when growing the buffer.
  void ensureCapacity(int capacity, [double growthFactor = 1.5]) {
    if (_offset + capacity > _buffer.length) {
      final newCapacity = (_buffer.length * growthFactor).round();
      assert(
        newCapacity > _buffer.length,
        'Capacity growth is not enough for growth factor $growthFactor',
      );
      final newBuffer = Uint8List(newCapacity);
      newBuffer.setRange(0, _offset, _buffer);
      _buffer = newBuffer;
      _byteData = ByteData.view(_buffer.buffer);
    }
  }

  /// Returns a sublist containing exactly the data written so far.
  ///
  /// This creates a new [Uint8List] that matches the current [offset]. 
  /// It is typically called when serialization is complete.
  Uint8List get compact => _buffer.sublist(0, _offset);
}
