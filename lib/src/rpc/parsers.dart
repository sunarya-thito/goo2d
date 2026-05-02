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

class Int8Parser extends TypeParser {
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

class Uint8Parser extends TypeParser {
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

class Int16Parser extends TypeParser {
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

class Uint16Parser extends TypeParser {
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

class Int32Parser extends TypeParser {
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

class Uint32Parser extends TypeParser {
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

class Int64Parser extends TypeParser {
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

class Uint64Parser extends TypeParser {
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

class Float32Parser extends TypeParser {
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

class Float64Parser extends TypeParser {
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

class BoolParser extends TypeParser {
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

class StringParser extends TypeParser {
  final Encoding encoding;
  final int limit;

  _LengthType get _lengthType => _LengthType.fromLimit(limit);
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

class Uint8ListParser extends TypeParser {
  final int limit;

  _LengthType get _lengthType => _LengthType.fromLimit(limit);
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

class ListParser<T> extends TypeParser {
  final TypeParser elementParser;
  final int limit;

  _LengthType get _lengthType => _LengthType.fromLimit(limit);
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

class SetParser<T> extends TypeParser {
  final TypeParser elementParser;
  final int limit;

  _LengthType get _lengthType => _LengthType.fromLimit(limit);
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

class MapParser<K, V> extends TypeParser {
  final TypeParser keyParser;
  final TypeParser valueParser;
  final int limit;

  _LengthType get _lengthType => _LengthType.fromLimit(limit);
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
