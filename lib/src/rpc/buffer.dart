import 'dart:typed_data';

/// A dynamic-capacity buffer for building [Uint8List] packets.
///
/// [Uint8Buffer] provides a wrapper around [ByteData] that automatically
/// grows as data is written. It is optimized for the RPC system's sequential
/// write patterns.
///
/// ```dart
/// final buffer = Uint8Buffer();
/// buffer.write(4, () => buffer.byteData.setInt32(buffer.offset, 42));
/// ```
class Uint8Buffer {
  /// The default initial capacity of the buffer (4KB).
  ///
  /// Balance between memory usage and allocation frequency.
  static const defaultCapacity = 4096;

  Uint8List _buffer;
  int _offset = 0;

  late ByteData _byteData = ByteData.view(_buffer.buffer);

  /// Creates a [Uint8Buffer] with an optional [initialCapacity].
  ///
  /// Initializes the storage for sequential writes.
  ///
  /// * [initialCapacity]: The starting byte size.
  Uint8Buffer([int initialCapacity = defaultCapacity])
    : _buffer = Uint8List(initialCapacity);

  /// Returns the underlying [ByteData] for the current buffer.
  ///
  /// The view is updated whenever the buffer grows. Provides direct memory
  /// access for [ByteData] operations.
  ByteData get byteData => _byteData;

  /// Executes a [writer] function that adds [size] bytes to the buffer.
  ///
  /// This method ensures that the buffer has enough capacity before
  /// invoking the [writer] and automatically advances the internal [offset].
  ///
  /// * [size]: The number of bytes to allocate.
  /// * [writer]: The callback that performs the actual write operation.
  void write(int size, void Function() writer) {
    ensureCapacity(size);
    writer();
    _offset += size;
  }

  /// The current write position in the buffer.
  ///
  /// Indicates how many bytes have been written so far.
  int get offset => _offset;

  /// Manually advances the write position by [length].
  ///
  /// Useful when skipping reserved space for later updates.
  ///
  /// * [length]: The number of bytes to skip.
  void skip(int length) => _offset += length;

  /// Ensures that the buffer has at least [capacity] bytes available.
  ///
  /// If the current buffer is too small, it is resized by the [growthFactor]
  /// (default 1.5x).
  ///
  /// * [capacity]: The required number of bytes.
  /// * [growthFactor]: The multiplier for resizing.
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

  /// Returns a copy of the buffer containing only the written data.
  ///
  /// Allocates a new [Uint8List] of exactly the [offset] size.
  Uint8List get compact => _buffer.sublist(0, _offset);
}
