import 'dart:convert';
import 'dart:typed_data';

import 'package:goo2d/src/rpc/buffer.dart';
import 'package:goo2d/src/rpc/parser.dart';

enum _LengthType {
  uint8(1),
  uint16(2),
  uint32(4),
  uint64(8)
  ;

  final int size;
  const _LengthType(this.size);

  /// Determines the appropriate length type based on the given [limit].
  /// 
  /// This mapping ensures that the smallest sufficient unsigned integer 
  /// type is used for length prefixing in variable-length fields.
  /// 
  /// * [limit]: The maximum value that needs to be represented.
  static _LengthType fromLimit(int limit) => switch (limit) {
    <= 255 => _LengthType.uint8,
    <= 65535 => _LengthType.uint16,
    <= 4294967295 => _LengthType.uint32,
    _ => _LengthType.uint64,
  };
}

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

void _writeLength(Uint8Buffer buffer, int length, _LengthType type) {
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

/// Parser for 8-bit signed integers.
/// 
/// Handles values in the range [-128, 127]. Links to [TypeParser.int8]. 
/// See also [TypeParser] for the base interface.
/// 
/// ```dart
/// const parser = Int8Parser();
/// ```
class Int8Parser extends TypeParser {
  /// Creates an [Int8Parser].
  /// 
  /// Initializes the 8-bit signed integer parser.
  const Int8Parser();
  @override
  ({int length, Object? object}) read(ByteData buffer, int offset) =>
      (length: 1, object: buffer.getInt8(offset));
  @override
  void write(Uint8Buffer buffer, Object? object) => buffer.write(
    1,
    () => buffer.byteData.setInt8(buffer.offset, object as int),
  );
}

/// Parser for 8-bit unsigned integers.
/// 
/// Handles values in the range [0, 255]. Links to [TypeParser.uint8]. 
/// See also [TypeParser] for the base interface.
/// 
/// ```dart
/// const parser = Uint8Parser();
/// ```
class Uint8Parser extends TypeParser {
  /// Creates a [Uint8Parser].
  /// 
  /// Initializes the 8-bit unsigned integer parser.
  const Uint8Parser();
  @override
  ({int length, Object? object}) read(ByteData buffer, int offset) =>
      (length: 1, object: buffer.getUint8(offset));
  @override
  void write(Uint8Buffer buffer, Object? object) => buffer.write(
    1,
    () => buffer.byteData.setUint8(buffer.offset, object as int),
  );
}

/// Parser for 16-bit signed integers.
/// 
/// Handles values in the range [-32,768, 32,767]. Links to [TypeParser.int16]. 
/// See also [TypeParser] for the base interface.
/// 
/// ```dart
/// const parser = Int16Parser();
/// ```
class Int16Parser extends TypeParser {
  /// Creates an [Int16Parser].
  /// 
  /// Initializes the 16-bit signed integer parser.
  const Int16Parser();
  @override
  ({int length, Object? object}) read(ByteData buffer, int offset) =>
      (length: 2, object: buffer.getInt16(offset));
  @override
  void write(Uint8Buffer buffer, Object? object) => buffer.write(
    2,
    () => buffer.byteData.setInt16(buffer.offset, object as int),
  );
}

/// Parser for 16-bit unsigned integers.
/// 
/// Handles values in the range [0, 65,535]. Links to [TypeParser.uint16]. 
/// See also [TypeParser] for the base interface.
/// 
/// ```dart
/// const parser = Uint16Parser();
/// ```
class Uint16Parser extends TypeParser {
  /// Creates a [Uint16Parser].
  /// 
  /// Initializes the 16-bit unsigned integer parser.
  const Uint16Parser();
  @override
  ({int length, Object? object}) read(ByteData buffer, int offset) =>
      (length: 2, object: buffer.getUint16(offset));
  @override
  void write(Uint8Buffer buffer, Object? object) => buffer.write(
    2,
    () => buffer.byteData.setUint16(buffer.offset, object as int),
  );
}

/// Parser for 32-bit signed integers.
/// 
/// Handles standard Dart integers. Links to [TypeParser.int32]. 
/// See also [TypeParser] for the base interface.
/// 
/// ```dart
/// const parser = Int32Parser();
/// ```
class Int32Parser extends TypeParser {
  /// Creates an [Int32Parser].
  /// 
  /// Initializes the 32-bit signed integer parser.
  const Int32Parser();
  @override
  ({int length, Object? object}) read(ByteData buffer, int offset) =>
      (length: 4, object: buffer.getInt32(offset));
  @override
  void write(Uint8Buffer buffer, Object? object) => buffer.write(
    4,
    () => buffer.byteData.setInt32(buffer.offset, object as int),
  );
}

/// Parser for 32-bit unsigned integers.
/// 
/// Handles positive 32-bit integers. Links to [TypeParser.uint32]. 
/// See also [TypeParser] for the base interface.
/// 
/// ```dart
/// const parser = Uint32Parser();
/// ```
class Uint32Parser extends TypeParser {
  /// Creates a [Uint32Parser].
  /// 
  /// Initializes the 32-bit unsigned integer parser.
  const Uint32Parser();
  @override
  ({int length, Object? object}) read(ByteData buffer, int offset) =>
      (length: 4, object: buffer.getUint32(offset));
  @override
  void write(Uint8Buffer buffer, Object? object) => buffer.write(
    4,
    () => buffer.byteData.setUint32(buffer.offset, object as int),
  );
}

/// Parser for 64-bit signed integers.
/// 
/// Handles large integers. Links to [TypeParser.int64]. 
/// See also [TypeParser] for the base interface.
/// 
/// ```dart
/// const parser = Int64Parser();
/// ```
class Int64Parser extends TypeParser {
  /// Creates an [Int64Parser].
  /// 
  /// Initializes the 64-bit signed integer parser.
  const Int64Parser();
  @override
  ({int length, Object? object}) read(ByteData buffer, int offset) =>
      (length: 8, object: buffer.getInt64(offset));
  @override
  void write(Uint8Buffer buffer, Object? object) => buffer.write(
    8,
    () => buffer.byteData.setInt64(buffer.offset, object as int),
  );
}

/// Parser for 64-bit unsigned integers.
/// 
/// Handles large positive integers. Links to [TypeParser.uint64]. 
/// See also [TypeParser] for the base interface.
/// 
/// ```dart
/// const parser = Uint64Parser();
/// ```
class Uint64Parser extends TypeParser {
  /// Creates a [Uint64Parser].
  /// 
  /// Initializes the 64-bit unsigned integer parser.
  const Uint64Parser();
  @override
  ({int length, Object? object}) read(ByteData buffer, int offset) =>
      (length: 8, object: buffer.getUint64(offset));
  @override
  void write(Uint8Buffer buffer, Object? object) => buffer.write(
    8,
    () => buffer.byteData.setUint64(buffer.offset, object as int),
  );
}

/// Parser for 32-bit floating point numbers.
/// 
/// Handles single-precision floats. Links to [TypeParser.float32]. 
/// See also [TypeParser] for the base interface.
/// 
/// ```dart
/// const parser = Float32Parser();
/// ```
class Float32Parser extends TypeParser {
  /// Creates a [Float32Parser].
  /// 
  /// Initializes the 32-bit float parser.
  const Float32Parser();
  @override
  ({int length, Object? object}) read(ByteData buffer, int offset) =>
      (length: 4, object: buffer.getFloat32(offset));
  @override
  void write(Uint8Buffer buffer, Object? object) => buffer.write(
    4,
    () => buffer.byteData.setFloat32(buffer.offset, object as double),
  );
}

/// Parser for 64-bit floating point numbers.
/// 
/// Handles double-precision floats. Links to [TypeParser.float64]. 
/// See also [TypeParser] for the base interface.
/// 
/// ```dart
/// const parser = Float64Parser();
/// ```
class Float64Parser extends TypeParser {
  /// Creates a [Float64Parser].
  /// 
  /// Initializes the 64-bit float parser.
  const Float64Parser();
  @override
  ({int length, Object? object}) read(ByteData buffer, int offset) =>
      (length: 8, object: buffer.getFloat64(offset));
  @override
  void write(Uint8Buffer buffer, Object? object) => buffer.write(
    8,
    () => buffer.byteData.setFloat64(buffer.offset, object as double),
  );
}

/// Parser for boolean values.
/// 
/// Uses a single byte (1 for true, 0 for false). Links to [TypeParser.bool]. 
/// See also [TypeParser] for the base interface.
/// 
/// ```dart
/// const parser = BoolParser();
/// ```
class BoolParser extends TypeParser {
  /// Creates a [BoolParser].
  /// 
  /// Initializes the boolean parser.
  const BoolParser();
  @override
  ({int length, Object? object}) read(ByteData buffer, int offset) =>
      (length: 1, object: buffer.getUint8(offset) == 1);
  @override
  void write(Uint8Buffer buffer, Object? object) => buffer.write(
    1,
    () => buffer.byteData.setUint8(buffer.offset, (object as bool) ? 1 : 0),
  );
}

/// Parser for [String] data with configurable encoding and length limits.
/// 
/// Handles text serialization with variable length prefixing. Links to 
/// [TypeParser.string].
/// 
/// ```dart
/// const parser = StringParser(limit: 1024);
/// ```
class StringParser extends TypeParser {
  /// The encoding to use for the string (defaults to UTF-8).
  /// 
  /// Affects the byte count and character representation.
  final Encoding encoding;
  
  /// The maximum length of the string in bytes.
  /// 
  /// Determines the size of the length prefix (uint8, uint16, etc.).
  final int limit;
  
  _LengthType get _lengthType => _LengthType.fromLimit(limit);

  /// Creates a [StringParser].
  /// 
  /// Initializes the string parser with specific constraints.
  /// 
  /// * [encoding]: The text encoding strategy.
  /// * [limit]: The maximum allowed byte size.
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
  void write(Uint8Buffer buffer, Object? object) {
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

/// Parser for raw [Uint8List] binary data.
/// 
/// Ideal for transmitting blobs of binary data. Links to 
/// [TypeParser.uint8List].
/// 
/// ```dart
/// const parser = Uint8ListParser(limit: 1024);
/// ```
class Uint8ListParser extends TypeParser {
  /// The maximum size of the byte list.
  /// 
  /// Determines the size of the length prefix.
  final int limit;
  
  _LengthType get _lengthType => _LengthType.fromLimit(limit);

  /// Creates a [Uint8ListParser].
  /// 
  /// Initializes the binary blob parser with a specific limit.
  /// 
  /// * [limit]: The maximum allowed byte size.
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
  void write(Uint8Buffer buffer, Object? object) {
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

/// Parser for a generic [List] of elements.
/// 
/// Serializes a variable-length sequence of items of type [T]. Links to [TypeParser.list]. 
/// See also [TypeParser] for the base interface.
/// 
/// ```dart
/// final parser = ListParser(TypeParser.int32);
/// ```
class ListParser<T> extends TypeParser {
  /// The parser used for individual elements in the list.
  /// 
  /// Defines how each item is encoded/decoded.
  final TypeParser elementParser;
  
  /// The maximum number of elements in the list.
  /// 
  /// Determines the size of the length prefix.
  final int limit;
  
  _LengthType get _lengthType => _LengthType.fromLimit(limit);

  /// Creates a [ListParser].
  /// 
  /// Initializes the list parser with an element strategy and size limit.
  /// 
  /// * [elementParser]: The strategy for individual items.
  /// * [limit]: The maximum allowed element count.
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
  void write(Uint8Buffer buffer, Object? object) {
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

/// Parser for a [Set] of unique elements.
/// 
/// Serializes a collection where each item of type [T] is unique. Links to [TypeParser.set]. 
/// See also [TypeParser] for the base interface.
/// 
/// ```dart
/// final parser = SetParser(TypeParser.int32);
/// ```
class SetParser<T> extends TypeParser {
  /// The parser used for individual elements in the set.
  /// 
  /// Defines how each unique item is encoded.
  final TypeParser elementParser;
  
  /// The maximum number of elements in the set.
  /// 
  /// Determines the size of the length prefix.
  final int limit;
  
  _LengthType get _lengthType => _LengthType.fromLimit(limit);

  /// Creates a [SetParser].
  /// 
  /// Initializes the set parser with an element strategy and size limit.
  /// 
  /// * [elementParser]: The strategy for individual items.
  /// * [limit]: The maximum allowed element count.
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
  void write(Uint8Buffer buffer, Object? object) {
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

/// Parser for a [Map] of key-value pairs.
/// 
/// Serializes an associative array of entries. Links to [TypeParser.map].
/// 
/// ```dart
/// final parser = MapParser<String, int>(TypeParser.string(), TypeParser.int32);
/// ```
class MapParser<K, V> extends TypeParser {
  /// The parser used for keys.
  /// 
  /// Defines the encoding strategy for map keys.
  final TypeParser keyParser;
  
  /// The parser used for values.
  /// 
  /// Defines the encoding strategy for map values.
  final TypeParser valueParser;
  
  /// The maximum number of entries in the map.
  /// 
  /// Determines the size of the length prefix.
  final int limit;
  
  _LengthType get _lengthType => _LengthType.fromLimit(limit);

  /// Creates a [MapParser].
  /// 
  /// Initializes the map parser with key/value strategies and size limit.
  /// 
  /// * [keyParser]: The strategy for keys.
  /// * [valueParser]: The strategy for values.
  /// * [limit]: The maximum allowed entry count.
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
  void write(Uint8Buffer buffer, Object? object) {
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
