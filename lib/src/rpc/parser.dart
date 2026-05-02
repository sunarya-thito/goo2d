import 'dart:convert';
import 'dart:typed_data';

import 'package:goo2d/src/rpc/buffer.dart';
import 'package:goo2d/src/rpc/parsers.dart';

abstract class FunctionRegistry {
  ({Object? Function() function, int length, FunctionEntry entry})
  readFunctionCallRequest(ByteData buffer, [int offset = 0]);
  void writeFunctionCallRequest(
    Uint8Buffer buffer, {
    required Function function,
    required List<Object> parameters,
  });
}

class FunctionEntry {
  final Function function;
  final TypeParser returnType;
  final List<TypeParser> parameterTypes;
  const FunctionEntry({
    required this.function,
    required this.returnType,
    required this.parameterTypes,
  });
}

typedef TypeParserConstructor<T> = T Function();

abstract class TypeParser {
  static const voidType = _VoidTypeParser();
  const factory TypeParser.nullable(TypeParser parser) = _NullableTypeParser;
  static const int8 = Int8Parser();
  static const uint8 = Uint8Parser();
  static const int16 = Int16Parser();
  static const uint16 = Uint16Parser();
  static const int32 = Int32Parser();
  static const uint32 = Uint32Parser();
  static const int64 = Int64Parser();
  static const uint64 = Uint64Parser();
  static const float32 = Float32Parser();
  static const float64 = Float64Parser();
  static const bool = BoolParser();
  const factory TypeParser.string({Encoding encoding, int limit}) =
      StringParser;
  const factory TypeParser.uint8List({int limit}) = Uint8ListParser;
  static TypeParser list<T>(TypeParser elementParser, {int limit = 65535}) =>
      ListParser<T>(elementParser, limit: limit);
  static TypeParser set<T>(TypeParser elementParser, {int limit = 65535}) =>
      SetParser<T>(elementParser, limit: limit);
  static TypeParser map<K, V>(
    TypeParser keyParser,
    TypeParser valueParser, {
    int limit = 65535,
  }) => MapParser<K, V>(keyParser, valueParser, limit: limit);
  static TypeParser object<T>({
    required ObjectSerializer<T> serializer,
    required ObjectDeserializer<T> deserializer,
    required List<TypeParser> fields,
  }) => ObjectTypeParser<T>(
    serializer: serializer,
    deserializer: deserializer,
    parsers: fields,
  );
  const TypeParser();
  ({Object? object, int length}) read(ByteData buffer, int offset);
  void write(Uint8Buffer buffer, Object? object);
  TypeParser call() {
    return this;
  }
}

Type _typeGetter<T>() {
  return T;
}

extension TypeParserExtension on Type {
  TypeParser get parser {
    if (_typeGetter<void>() == this) {
      return TypeParser.voidType;
    }
    return switch (this) {
      const (int) => TypeParser.int32,
      const (double) => TypeParser.float64,
      const (bool) => TypeParser.bool,
      const (String) => TypeParser.string(),
      const (Uint8List) => TypeParser.uint8List(),
      _ => throw UnimplementedError('No default parser for type $this'),
    };
  }

  TypeParser get nullableParser => TypeParser.nullable(parser);
}

extension FunctionDescriptorExtension on Function {
  FunctionEntry describe(
    List<TypeParser> parameters, {
    TypeParser? returnType,
  }) {
    return FunctionEntry(
      function: this,
      returnType: returnType ?? TypeParser.voidType,
      parameterTypes: parameters,
    );
  }
}

class _VoidTypeParser extends TypeParser {
  const _VoidTypeParser();

  @override
  ({int length, Object? object}) read(ByteData buffer, int offset) {
    return (length: 0, object: null);
  }

  @override
  void write(Uint8Buffer buffer, Object? object) {}
}

class _NullableTypeParser extends TypeParser {
  final TypeParser nonNullParser;
  const _NullableTypeParser(this.nonNullParser);

  @override
  ({int length, Object? object}) read(ByteData buffer, int offset) {
    final isNotNull = buffer.getUint8(offset) == 1;
    if (isNotNull) {
      return nonNullParser.read(buffer, offset + 1);
    } else {
      return (length: 1, object: null);
    }
  }

  @override
  void write(Uint8Buffer buffer, Object? object) {
    if (object == null) {
      buffer.write(1, () {
        buffer.byteData.setUint8(buffer.offset, 0);
      });
    } else {
      buffer.write(1, () {
        buffer.byteData.setUint8(buffer.offset, 1);
      });
      nonNullParser.write(buffer, object);
    }
  }
}

typedef ObjectSerializer<T> = List<Object?> Function(T object);
typedef ObjectDeserializer<T> = T Function(List<Object?> args);

class ObjectTypeParser<T> extends TypeParser {
  final List<TypeParser> parsers;
  final ObjectSerializer<T> serializer;
  final ObjectDeserializer<T> deserializer;
  const ObjectTypeParser({
    required this.parsers,
    required this.serializer,
    required this.deserializer,
  });

  @override
  ({int length, Object? object}) read(ByteData buffer, int offset) {
    final List<Object> params = [];
    int totalLength = 0;
    for (int i = 0; i < parsers.length; i++) {
      final ({int length, Object? object}) result = parsers[i].read(
        buffer,
        offset + totalLength,
      );
      params.add(result.object!);
      totalLength += result.length;
    }
    return (
      length: totalLength,
      object: deserializer(params),
    );
  }

  @override
  void write(Uint8Buffer buffer, Object? object) {
    final params = serializer(object as T);
    assert(
      params.length == parsers.length,
      'Serializer and deserializer must return the same number of parameters.',
    );
    for (int i = 0; i < parsers.length; i++) {
      parsers[i].write(buffer, params[i]);
    }
  }
}
