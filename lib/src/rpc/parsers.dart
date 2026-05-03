import 'dart:convert';
import 'dart:typed_data';

import 'package:goo2d/src/rpc/buffer.dart';
import 'package:goo2d/src/rpc/parser.dart';

/// Defines the size of the length prefix for variable-length types.
enum _LengthType {
  /// 1-byte length prefix (max 255).
  uint8(1),

  /// 2-byte length prefix (max 65,535).
  uint16(2),

  /// 4-byte length prefix (max 4.29 billion).
  uint32(4),

  /// 8-byte length prefix (max 18.4 quintillion).
  uint64(8)
  ;

  /// The number of bytes consumed by this length type.
  final int size;
  const _LengthType(this.size);

  /// Determines the appropriate length type for a given maximum limit.
  static _LengthType fromLimit(int limit) => switch (limit) {
    <= 255 => _LengthType.uint8,
    <= 65535 => _LengthType.uint16,
    <= 4294967295 => _LengthType.uint32,
    _ => _LengthType.uint64,
  };
}

/// Reads a length prefix from the [buffer] at the given [offset].
({int length, int offset}) _readLength(
  ByteData buffer,
  int offset,
  _LengthType type,
) {
  return switch (type) {
    _LengthType.uint8 => (length: buffer.getUint8(offset), offset: offset + 1),
    _LengthType.uint16 => (
      length: buffer.getUint16(offset),
      offset: offset + 2,
    ),
    _LengthType.uint32 => (
      length: buffer.getUint32(offset),
      offset: offset + 4,
    ),
    _LengthType.uint64 => (
      length: buffer.getUint64(offset),
      offset: offset + 8,
    ),
  };
}

/// Writes a length prefix to the [buffer] using the specified [type].
void _writeLength(Uint8ListBuffer buffer, int length, _LengthType type) {
  buffer.write(type.size, () {
    switch (type) {
      case _LengthType.uint8:
        buffer.byteData.setUint8(buffer.offset, length);
      case _LengthType.uint16:
        buffer.byteData.setUint16(buffer.offset, length);
      case _LengthType.uint32:
        buffer.byteData.setUint32(buffer.offset, length);
      case _LengthType.uint64:
        buffer.byteData.setUint64(buffer.offset, length);
    }
  });
}

/// A parser for signed 8-bit integers.
///
/// [Int8Parser] handles the serialization of single-byte signed 
/// integers. It consumes exactly 1 byte from the buffer.
///
/// ```dart
/// final parser = TypeParser.int8;
/// final buffer = Uint8ListBuffer();
/// parser.write(buffer, -128);
/// ```
///
/// See also:
/// * [Uint8Parser] for unsigned 8-bit integers.
/// * [TypeParser] for the base class.
class Int8Parser extends TypeParser {
  /// Creates a new signed 8-bit integer parser.
  ///
  /// This constructor is usually called indirectly through the 
  /// [TypeParser.int8] static getter.
  const Int8Parser();

  @override
  ({int length, Object? object}) read(ByteData buffer, int offset) =>
      (length: 1, object: buffer.getInt8(offset));

  @override
  void write(Uint8ListBuffer buffer, Object? object) => buffer.write(
    1,
    () => buffer.byteData.setInt8(buffer.offset, object as int),
  );
}

/// A parser for unsigned 8-bit integers.
///
/// [Uint8Parser] handles the serialization of single-byte unsigned 
/// integers. It consumes exactly 1 byte from the buffer.
///
/// ```dart
/// final parser = TypeParser.uint8;
/// final buffer = Uint8ListBuffer();
/// parser.write(buffer, 255);
/// ```
///
/// See also:
/// * [Int8Parser] for signed 8-bit integers.
/// * [TypeParser] for the base class.
class Uint8Parser extends TypeParser {
  /// Creates a new unsigned 8-bit integer parser.
  ///
  /// This constructor is usually called indirectly through the 
  /// [TypeParser.uint8] static getter.
  const Uint8Parser();

  @override
  ({int length, Object? object}) read(ByteData buffer, int offset) =>
      (length: 1, object: buffer.getUint8(offset));

  @override
  void write(Uint8ListBuffer buffer, Object? object) => buffer.write(
    1,
    () => buffer.byteData.setUint8(buffer.offset, object as int),
  );
}

/// A parser for signed 16-bit integers.
///
/// [Int16Parser] handles the serialization of 2-byte signed 
/// integers. It consumes exactly 2 bytes from the buffer.
///
/// ```dart
/// final parser = TypeParser.int16;
/// final buffer = Uint8ListBuffer();
/// parser.write(buffer, -32768);
/// ```
///
/// See also:
/// * [Uint16Parser] for unsigned 16-bit integers.
/// * [TypeParser] for the base class.
class Int16Parser extends TypeParser {
  /// Creates a new signed 16-bit integer parser.
  ///
  /// This constructor is usually called indirectly through the 
  /// [TypeParser.int16] static getter.
  const Int16Parser();

  @override
  ({int length, Object? object}) read(ByteData buffer, int offset) =>
      (length: 2, object: buffer.getInt16(offset));

  @override
  void write(Uint8ListBuffer buffer, Object? object) => buffer.write(
    2,
    () => buffer.byteData.setInt16(buffer.offset, object as int),
  );
}

/// A parser for unsigned 16-bit integers.
///
/// [Uint16Parser] handles the serialization of 2-byte unsigned 
/// integers. It consumes exactly 2 bytes from the buffer.
///
/// ```dart
/// final parser = TypeParser.uint16;
/// final buffer = Uint8ListBuffer();
/// parser.write(buffer, 65535);
/// ```
///
/// See also:
/// * [Int16Parser] for signed 16-bit integers.
/// * [TypeParser] for the base class.
class Uint16Parser extends TypeParser {
  /// Creates a new unsigned 16-bit integer parser.
  ///
  /// This constructor is usually called indirectly through the 
  /// [TypeParser.uint16] static getter.
  const Uint16Parser();

  @override
  ({int length, Object? object}) read(ByteData buffer, int offset) =>
      (length: 2, object: buffer.getUint16(offset));

  @override
  void write(Uint8ListBuffer buffer, Object? object) => buffer.write(
    2,
    () => buffer.byteData.setUint16(buffer.offset, object as int),
  );
}

/// A parser for signed 32-bit integers.
///
/// [Int32Parser] handles the serialization of 4-byte signed 
/// integers. It consumes exactly 4 bytes from the buffer.
///
/// ```dart
/// final parser = TypeParser.int32;
/// final buffer = Uint8ListBuffer();
/// parser.write(buffer, -2147483648);
/// ```
///
/// See also:
/// * [Uint32Parser] for unsigned 32-bit integers.
/// * [TypeParser] for the base class.
class Int32Parser extends TypeParser {
  /// Creates a new signed 32-bit integer parser.
  ///
  /// This constructor is usually called indirectly through the 
  /// [TypeParser.int32] static getter.
  const Int32Parser();

  @override
  ({int length, Object? object}) read(ByteData buffer, int offset) =>
      (length: 4, object: buffer.getInt32(offset));

  @override
  void write(Uint8ListBuffer buffer, Object? object) => buffer.write(
    4,
    () => buffer.byteData.setInt32(buffer.offset, object as int),
  );
}

/// A parser for unsigned 32-bit integers.
///
/// [Uint32Parser] handles the serialization of 4-byte unsigned 
/// integers. It consumes exactly 4 bytes from the buffer.
///
/// ```dart
/// final parser = TypeParser.uint32;
/// final buffer = Uint8ListBuffer();
/// parser.write(buffer, 4294967295);
/// ```
///
/// See also:
/// * [Int32Parser] for signed 32-bit integers.
/// * [TypeParser] for the base class.
class Uint32Parser extends TypeParser {
  /// Creates a new unsigned 32-bit integer parser.
  ///
  /// This constructor is usually called indirectly through the 
  /// [TypeParser.uint32] static getter.
  const Uint32Parser();

  @override
  ({int length, Object? object}) read(ByteData buffer, int offset) =>
      (length: 4, object: buffer.getUint32(offset));

  @override
  void write(Uint8ListBuffer buffer, Object? object) => buffer.write(
    4,
    () => buffer.byteData.setUint32(buffer.offset, object as int),
  );
}

/// A parser for signed 64-bit integers.
///
/// [Int64Parser] handles the serialization of 8-byte signed 
/// integers. It consumes exactly 8 bytes from the buffer.
///
/// ```dart
/// final parser = TypeParser.int64;
/// final buffer = Uint8ListBuffer();
/// parser.write(buffer, 42);
/// ```
///
/// See also:
/// * [Uint64Parser] for unsigned 64-bit integers.
/// * [TypeParser] for the base class.
class Int64Parser extends TypeParser {
  /// Creates a new signed 64-bit integer parser.
  ///
  /// This constructor is usually called indirectly through the 
  /// [TypeParser.int64] static getter.
  const Int64Parser();

  @override
  ({int length, Object? object}) read(ByteData buffer, int offset) =>
      (length: 8, object: buffer.getInt64(offset));

  @override
  void write(Uint8ListBuffer buffer, Object? object) => buffer.write(
    8,
    () => buffer.byteData.setInt64(buffer.offset, object as int),
  );
}

/// A parser for unsigned 64-bit integers.
///
/// [Uint64Parser] handles the serialization of 8-byte unsigned 
/// integers. It consumes exactly 8 bytes from the buffer.
///
/// ```dart
/// final parser = TypeParser.uint64;
/// final buffer = Uint8ListBuffer();
/// parser.write(buffer, 42);
/// ```
///
/// See also:
/// * [Int64Parser] for signed 64-bit integers.
/// * [TypeParser] for the base class.
class Uint64Parser extends TypeParser {
  /// Creates a new unsigned 64-bit integer parser.
  ///
  /// This constructor is usually called indirectly through the 
  /// [TypeParser.uint64] static getter.
  const Uint64Parser();

  @override
  ({int length, Object? object}) read(ByteData buffer, int offset) =>
      (length: 8, object: buffer.getUint64(offset));

  @override
  void write(Uint8ListBuffer buffer, Object? object) => buffer.write(
    8,
    () => buffer.byteData.setUint64(buffer.offset, object as int),
  );
}

/// A parser for 32-bit floating-point numbers.
///
/// [Float32Parser] handles the serialization of 4-byte floating 
/// point numbers. It consumes exactly 4 bytes from the buffer.
///
/// ```dart
/// final parser = TypeParser.float32;
/// final buffer = Uint8ListBuffer();
/// parser.write(buffer, 3.14);
/// ```
///
/// See also:
/// * [Float64Parser] for 64-bit floats.
/// * [TypeParser] for the base class.
class Float32Parser extends TypeParser {
  /// Creates a new 32-bit float parser.
  ///
  /// This constructor is usually called indirectly through the 
  /// [TypeParser.float32] static getter.
  const Float32Parser();

  @override
  ({int length, Object? object}) read(ByteData buffer, int offset) =>
      (length: 4, object: buffer.getFloat32(offset));

  @override
  void write(Uint8ListBuffer buffer, Object? object) => buffer.write(
    4,
    () => buffer.byteData.setFloat32(buffer.offset, object as double),
  );
}

/// A parser for 64-bit floating-point numbers.
///
/// [Float64Parser] handles the serialization of 8-byte floating 
/// point numbers. It consumes exactly 8 bytes from the buffer.
///
/// ```dart
/// final parser = TypeParser.float64;
/// final buffer = Uint8ListBuffer();
/// parser.write(buffer, 3.14159265359);
/// ```
///
/// See also:
/// * [Float32Parser] for 32-bit floats.
/// * [TypeParser] for the base class.
class Float64Parser extends TypeParser {
  /// Creates a new 64-bit float parser.
  ///
  /// This constructor is usually called indirectly through the 
  /// [TypeParser.float64] static getter.
  const Float64Parser();

  @override
  ({int length, Object? object}) read(ByteData buffer, int offset) =>
      (length: 8, object: buffer.getFloat64(offset));

  @override
  void write(Uint8ListBuffer buffer, Object? object) => buffer.write(
    8,
    () => buffer.byteData.setFloat64(buffer.offset, object as double),
  );
}

/// A parser for boolean values.
///
/// [BoolParser] handles the serialization of booleans as a single 
/// byte (1 for true, 0 for false).
///
/// ```dart
/// final parser = TypeParser.bool;
/// final buffer = Uint8ListBuffer();
/// parser.write(buffer, true);
/// ```
///
/// See also:
/// * [Int8Parser] for another single-byte parser.
/// * [TypeParser] for the base class.
class BoolParser extends TypeParser {
  /// Creates a new boolean parser.
  ///
  /// This constructor is usually called indirectly through the 
  /// [TypeParser.bool] static getter.
  const BoolParser();

  @override
  ({int length, Object? object}) read(ByteData buffer, int offset) =>
      (length: 1, object: buffer.getUint8(offset) == 1);

  @override
  void write(Uint8ListBuffer buffer, Object? object) => buffer.write(
    1,
    () => buffer.byteData.setUint8(buffer.offset, (object as bool) ? 1 : 0),
  );
}

/// A parser for string values with variable length.
///
/// [StringParser] serializes strings by first writing a length 
/// prefix and then the encoded byte sequence. The length prefix 
/// size is determined by the [limit].
///
/// ```dart
/// final parser = TypeParser.string();
/// final buffer = Uint8ListBuffer();
/// parser.write(buffer, "Hello Goo2d");
/// ```
///
/// See also:
/// * [Uint8ListParser] for raw byte array serialization.
/// * [TypeParser] for the base class.
class StringParser extends TypeParser {
  /// The text encoding used for serialization.
  ///
  /// This encoding is applied to the string before it is written 
  /// to the buffer, and it must match the encoding used by the peer.
  final Encoding encoding;

  /// The maximum allowed length for the string in bytes.
  ///
  /// If the encoded string exceeds this limit, an exception will 
  /// be thrown during serialization.
  final int limit;

  _LengthType get _lengthType => _LengthType.fromLimit(limit);

  /// Creates a string parser with the specified encoding and limit.
  ///
  /// This constructor allows for fine-grained control over how 
  /// strings are serialized and bounded.
  ///
  /// * [encoding]: The text encoding to use (defaults to utf8).
  /// * [limit]: The maximum string length (defaults to 65535).
  const StringParser({this.encoding = utf8, this.limit = 65535});

  @override
  ({int length, Object? object}) read(ByteData buffer, int offset) {
    final lengthResult = _readLength(buffer, offset, _lengthType);
    final bytes = buffer.buffer.asUint8List(
      buffer.offsetInBytes + lengthResult.offset,
      lengthResult.length,
    );
    return (
      length: _lengthType.size + lengthResult.length,
      object: encoding.decode(bytes),
    );
  }

  @override
  void write(Uint8ListBuffer buffer, Object? object) {
    final bytes = encoding.encode(object as String);
    if (bytes.length > limit) {
      throw Exception(
        'String length ${bytes.length} exceeds limit $limit',
      );
    }
    _writeLength(buffer, bytes.length, _lengthType);
    buffer.write(bytes.length, () {
      buffer.byteData.buffer.asUint8List().setRange(
        buffer.offset,
        buffer.offset + bytes.length,
        bytes,
      );
    });
  }
}

/// A parser for raw byte arrays.
///
/// [Uint8ListParser] serializes [Uint8List] objects by first writing 
/// a length prefix and then the raw bytes. The length prefix size 
/// is determined by the [limit].
///
/// ```dart
/// final parser = TypeParser.uint8List();
/// final buffer = Uint8ListBuffer();
/// parser.write(buffer, Uint8List.fromList([1, 2, 3]));
/// ```
///
/// See also:
/// * [StringParser] for text-based byte serialization.
/// * [TypeParser] for the base class.
class Uint8ListParser extends TypeParser {
  /// The maximum allowed number of bytes in the list.
  ///
  /// This limit is used to determine the size of the length 
  /// prefix and to prevent excessively large allocations.
  final int limit;

  _LengthType get _lengthType => _LengthType.fromLimit(limit);

  /// Creates a byte list parser with the specified limit.
  ///
  /// This constructor defines the upper bound for raw binary 
  /// data handled by this parser.
  ///
  /// * [limit]: The maximum byte length (defaults to 65535).
  const Uint8ListParser({this.limit = 65535});

  @override
  ({int length, Object? object}) read(ByteData buffer, int offset) {
    final lengthResult = _readLength(buffer, offset, _lengthType);
    final bytes = buffer.buffer.asUint8List(
      buffer.offsetInBytes + lengthResult.offset,
      lengthResult.length,
    );
    return (
      length: _lengthType.size + lengthResult.length,
      object: Uint8List.fromList(bytes),
    );
  }

  @override
  void write(Uint8ListBuffer buffer, Object? object) {
    final bytes = object as Uint8List;
    if (bytes.length > limit) {
      throw Exception(
        'Uint8List length ${bytes.length} exceeds limit $limit',
      );
    }
    _writeLength(buffer, bytes.length, _lengthType);
    buffer.write(bytes.length, () {
      buffer.byteData.buffer.asUint8List().setRange(
        buffer.offset,
        buffer.offset + bytes.length,
        bytes,
      );
    });
  }
}

/// A parser for lists of a specific type.
///
/// [ListParser] serializes generic [List] objects by writing a 
/// length prefix and then serializing each element sequentially 
/// using the [elementParser].
///
/// ```dart
/// final parser = TypeParser.list<int>(TypeParser.int32);
/// final buffer = Uint8ListBuffer();
/// parser.write(buffer, [1, 2, 3]);
/// ```
///
/// See also:
/// * [SetParser] for set-based collection serialization.
/// * [TypeParser] for the base class.
class ListParser<T> extends TypeParser {
  /// The parser used for individual elements in the list.
  ///
  /// This parser is called iteratively for each item in the 
  /// list during serialization and deserialization.
  final TypeParser elementParser;

  /// The maximum number of elements allowed in the list.
  ///
  /// This limit helps prevent denial-of-service attacks by 
  /// restricting the size of incoming collections.
  final int limit;

  _LengthType get _lengthType => _LengthType.fromLimit(limit);

  /// Creates a list parser for elements of type [T].
  ///
  /// This constructor initializes the parser with a specific 
  /// element handler and an optional length constraint.
  ///
  /// * [elementParser]: The parser for list items.
  /// * [limit]: The maximum number of items (defaults to 65535).
  const ListParser(this.elementParser, {this.limit = 65535});

  @override
  ({int length, Object? object}) read(ByteData buffer, int offset) {
    final lengthResult = _readLength(buffer, offset, _lengthType);
    var currentOffset = lengthResult.offset;
    final list = <T>[];
    for (var i = 0; i < lengthResult.length; i++) {
      final elementResult = elementParser.read(buffer, currentOffset);
      list.add(elementResult.object as T);
      currentOffset += elementResult.length;
    }
    return (length: currentOffset - offset, object: list);
  }

  @override
  void write(Uint8ListBuffer buffer, Object? object) {
    final list = object as List<T>;
    if (list.length > limit) {
      throw Exception('List length ${list.length} exceeds limit $limit');
    }
    _writeLength(buffer, list.length, _lengthType);
    for (final element in list) {
      elementParser.write(buffer, element);
    }
  }
}

/// A parser for sets of a specific type.
///
/// [SetParser] serializes [Set] objects by writing a length prefix 
/// and then serializing each unique element using the [elementParser].
///
/// ```dart
/// final parser = TypeParser.set<int>(TypeParser.int32);
/// final buffer = Uint8ListBuffer();
/// parser.write(buffer, {1, 2, 3});
/// ```
///
/// See also:
/// * [ListParser] for list-based collection serialization.
/// * [TypeParser] for the base class.
class SetParser<T> extends TypeParser {
  /// The parser used for individual elements in the set.
  ///
  /// This parser ensures that each unique item in the set is 
  /// correctly converted to and from binary data.
  final TypeParser elementParser;

  /// The maximum number of elements allowed in the set.
  ///
  /// Similar to the list parser, this limit protects the 
  /// application from handling unreasonably large sets.
  final int limit;

  _LengthType get _lengthType => _LengthType.fromLimit(limit);

  /// Creates a set parser for elements of type [T].
  ///
  /// This constructor enables the serialization of unique 
  /// collections with a predefined element parser.
  ///
  /// * [elementParser]: The parser for set items.
  /// * [limit]: The maximum number of items (defaults to 65535).
  const SetParser(this.elementParser, {this.limit = 65535});

  @override
  ({int length, Object? object}) read(ByteData buffer, int offset) {
    final lengthResult = _readLength(buffer, offset, _lengthType);
    var currentOffset = lengthResult.offset;
    final set = <T>{};
    for (var i = 0; i < lengthResult.length; i++) {
      final elementResult = elementParser.read(buffer, currentOffset);
      set.add(elementResult.object as T);
      currentOffset += elementResult.length;
    }
    return (length: currentOffset - offset, object: set);
  }

  @override
  void write(Uint8ListBuffer buffer, Object? object) {
    final set = object as Set<T>;
    if (set.length > limit) {
      throw Exception('Set length ${set.length} exceeds limit $limit');
    }
    _writeLength(buffer, set.length, _lengthType);
    for (final element in set) {
      elementParser.write(buffer, element);
    }
  }
}

/// A parser for maps with specific key and value types.
///
/// [MapParser] serializes [Map] objects by writing a length prefix 
/// and then alternating between key and value serialization for 
/// each entry.
///
/// ```dart
/// final parser = TypeParser.map<String, int>(
///   TypeParser.string(),
///   TypeParser.int32,
/// );
/// final buffer = Uint8ListBuffer();
/// parser.write(buffer, {"a": 1, "b": 2});
/// ```
///
/// See also:
/// * [ListParser] for single-value collection serialization.
/// * [TypeParser] for the base class.
class MapParser<K, V> extends TypeParser {
  /// The parser used for map keys.
  ///
  /// This parser is applied to each key in the map to maintain 
  /// type safety during transport.
  final TypeParser keyParser;

  /// The parser used for map values.
  ///
  /// This parser is applied to each value associated with a 
  /// key in the map.
  final TypeParser valueParser;

  /// The maximum number of entries allowed in the map.
  ///
  /// This limit restricts the overall size of the serialized 
  /// dictionary for security and performance.
  final int limit;

  _LengthType get _lengthType => _LengthType.fromLimit(limit);

  /// Creates a map parser with the specified key and value definitions.
  ///
  /// This constructor sets up the recursive parsing logic for 
  /// dictionary-like data structures.
  ///
  /// * [keyParser]: The parser for map keys.
  /// * [valueParser]: The parser for map values.
  /// * [limit]: The maximum number of entries (defaults to 65535).
  const MapParser(this.keyParser, this.valueParser, {this.limit = 65535});

  @override
  ({int length, Object? object}) read(ByteData buffer, int offset) {
    final lengthResult = _readLength(buffer, offset, _lengthType);
    var currentOffset = lengthResult.offset;
    final map = <K, V>{};
    for (var i = 0; i < lengthResult.length; i++) {
      final keyResult = keyParser.read(buffer, currentOffset);
      currentOffset += keyResult.length;
      final valueResult = valueParser.read(buffer, currentOffset);
      currentOffset += valueResult.length;
      map[keyResult.object as K] = valueResult.object as V;
    }
    return (length: currentOffset - offset, object: map);
  }

  @override
  void write(Uint8ListBuffer buffer, Object? object) {
    final map = object as Map<K, V>;
    if (map.length > limit) {
      throw Exception('Map length ${map.length} exceeds limit $limit');
    }
    _writeLength(buffer, map.length, _lengthType);
    map.forEach((key, value) {
      keyParser.write(buffer, key);
      valueParser.write(buffer, value);
    });
  }
}
