import 'dart:convert';
import 'dart:typed_data';

import 'package:goo2d/src/rpc/buffer.dart';
import 'package:goo2d/src/rpc/parsers.dart';

/// A registry that handles the serialization and deserialization of function calls.
/// 
/// [FunctionRegistry] defines the contract for mapping function references to 
/// unique identifiers and translating their arguments to and from binary data.
/// It works in conjunction with [FunctionEntry] and [TypeParser].
/// 
/// ```dart
/// class MyRegistry extends FunctionRegistry {
///   // Custom implementation here
/// }
/// ```
abstract class FunctionRegistry {
  /// Reads a function call request from a [buffer] at the given [offset].
  /// 
  /// Deserializes the function identifier and all its parameters. Returns 
  /// a record containing the closure and metadata.
  /// 
  /// * [buffer]: The raw binary data.
  /// * [offset]: The starting position in the buffer.
  ({Object? Function() function, int length, FunctionEntry entry})
  readFunctionCallRequest(ByteData buffer, [int offset = 0]);
  
  /// Serializes a [function] call with [parameters] into the provided [buffer].
  /// 
  /// Converts high-level arguments into binary format based on the registered 
  /// type parsers for that specific function.
  /// 
  /// * [buffer]: The target output stream.
  /// * [function]: The closure to be called remotely.
  /// * [parameters]: The list of arguments to serialize.
  void writeFunctionCallRequest(
    Uint8Buffer buffer, {
    required Function function,
    required List<Object> parameters,
  });
}

/// Metadata about a function that can be called via RPC.
/// 
/// [FunctionEntry] stores the type information necessary to correctly 
/// serialize arguments and deserialize return values. It links to [TypeParser] 
/// for data conversion logic.
/// 
/// ```dart
/// final entry = FunctionEntry(
///   function: (int x) => x * 2,
///   returnType: TypeParser.int32,
///   parameterTypes: [TypeParser.int32],
/// );
/// ```
class FunctionEntry {
  /// The actual function closure to be executed.
  /// 
  /// This reference is used locally when a call is received.
  final Function function;
  
  /// The parser for the function's return value.
  /// 
  /// Determines how the result of the call is encoded for transmission back.
  final TypeParser returnType;
  
  /// The list of parsers for the function's positional parameters.
  /// 
  /// Each parser corresponds to an argument in the [function] signature.
  final List<TypeParser> parameterTypes;

  /// Creates a [FunctionEntry].
  /// 
  /// Initializes the entry with the target function and its type metadata.
  /// 
  /// * [function]: The executable closure.
  /// * [returnType]: Metadata for the return value.
  /// * [parameterTypes]: Metadata for the input arguments.
  const FunctionEntry({
    required this.function,
    required this.returnType,
    required this.parameterTypes,
  });
}

/// A function that creates a new instance of a type parser.
typedef TypeParserConstructor<T> = T Function();

/// Base class for all types that can be serialized over the RPC system.
/// 
/// [TypeParser] provides a set of static constants and factory methods for 
/// common Dart types (integers, floats, strings, collections). It handles 
/// the conversion between high-level objects and low-level [ByteData].
/// 
/// You can extend this class to support custom complex types in your game. 
/// See [ObjectTypeParser] for an example of composite type parsing.
/// 
/// ```dart
/// const parser = TypeParser.int32;
/// parser.write(buffer, 42);
/// ```
abstract class TypeParser {
  /// Parser for `void` return types.
  /// 
  /// Consumes zero bytes and always returns `null`.
  static const voidType = _VoidTypeParser();
  
  /// Creates a parser that wraps another [parser] to support `null` values.
  /// 
  /// Uses a 1-byte prefix to indicate nullability.
  /// 
  /// * [parser]: The non-nullable parser to wrap.
  const factory TypeParser.nullable(TypeParser parser) = _NullableTypeParser;

  /// Parser for 8-bit signed integers.
  /// 
  /// Encodes values from -128 to 127.
  static const int8 = Int8Parser();
  
  /// Parser for 8-bit unsigned integers.
  /// 
  /// Encodes values from 0 to 255.
  static const uint8 = Uint8Parser();
  
  /// Parser for 16-bit signed integers.
  /// 
  /// Encodes values from -32,768 to 32,767.
  static const int16 = Int16Parser();
  
  /// Parser for 16-bit unsigned integers.
  /// 
  /// Encodes values from 0 to 65,535.
  static const uint16 = Uint16Parser();
  
  /// Parser for 32-bit signed integers.
  /// 
  /// Encodes standard Dart integers within 32-bit range.
  static const int32 = Int32Parser();
  
  /// Parser for 32-bit unsigned integers.
  /// 
  /// Encodes positive Dart integers within 32-bit range.
  static const uint32 = Uint32Parser();
  
  /// Parser for 64-bit signed integers.
  /// 
  /// Encodes large 64-bit integers.
  static const int64 = Int64Parser();
  
  /// Parser for 64-bit unsigned integers.
  /// 
  /// Encodes large positive 64-bit integers.
  static const uint64 = Uint64Parser();
  
  /// Parser for 32-bit floating point numbers.
  /// 
  /// Encodes single-precision floats.
  static const float32 = Float32Parser();
  
  /// Parser for 64-bit floating point numbers.
  /// 
  /// Encodes double-precision floats.
  static const float64 = Float64Parser();
  
  /// Parser for boolean values.
  /// 
  /// Encodes `true` or `false` using 1 byte.
  static const bool = BoolParser();

  /// Creates a parser for [String] data with a specific [encoding] and [limit].
  /// 
  /// Handles text serialization with optional length restrictions.
  /// 
  /// * [encoding]: The character encoding (defaults to UTF-8).
  /// * [limit]: Maximum allowed byte length.
  const factory TypeParser.string({Encoding encoding, int limit}) =
      StringParser;
      
  /// Creates a parser for raw [Uint8List] bytes with an optional [limit].
  /// 
  /// Ideal for transmitting blobs of binary data.
  /// 
  /// * [limit]: Maximum allowed byte length.
  const factory TypeParser.uint8List({int limit}) = Uint8ListParser;

  /// Creates a parser for a [List] of elements.
  /// 
  /// This factory initializes a [ListParser] that can serialize a 
  /// variable-length sequence of items of type [T].
  /// 
  /// * [elementParser]: The parser for individual list items.
  /// * [limit]: Maximum allowed list length.
  static TypeParser list<T>(TypeParser elementParser, {int limit = 65535}) =>
      ListParser<T>(elementParser, limit: limit);
      
  /// Creates a parser for a [Set] of elements.
  /// 
  /// This factory initializes a [SetParser] that can serialize a 
  /// unique collection of items of type [T].
  /// 
  /// * [elementParser]: The parser for individual set items.
  /// * [limit]: Maximum allowed set size.
  static TypeParser set<T>(TypeParser elementParser, {int limit = 65535}) =>
      SetParser<T>(elementParser, limit: limit);
      
  /// Creates a parser for a [Map] of key-value pairs.
  /// 
  /// This factory initializes a [MapParser] that can serialize an 
  /// associative array of keys and values of type [K] and [V].
  /// 
  /// * [keyParser]: The parser for map keys.
  /// * [valueParser]: The parser for map values.
  /// * [limit]: Maximum allowed map size.
  static TypeParser map<K, V>(
    TypeParser keyParser,
    TypeParser valueParser, {
    int limit = 65535,
  }) => MapParser<K, V>(keyParser, valueParser, limit: limit);

  /// Creates a parser for a custom object type [T].
  /// 
  /// Requires a [serializer] to decompose the object into a list of fields, 
  /// a [deserializer] to reconstruct it, and a list of [fields] parsers 
  /// for the constituent parts. Links to [ObjectTypeParser].
  /// 
  /// * [serializer]: Function to extract fields from [T].
  /// * [deserializer]: Function to build [T] from fields.
  /// * [fields]: Parsers for each serialized field.
  static TypeParser object<T>({
    required ObjectSerializer<T> serializer,
    required ObjectDeserializer<T> deserializer,
    required List<TypeParser> fields,
  }) => ObjectTypeParser<T>(
    serializer: serializer,
    deserializer: deserializer,
    parsers: fields,
  );

  /// Constant constructor for subclasses.
  /// 
  /// Initializes the base parser instance.
  const TypeParser();

  /// Decodes an object from the [buffer] at [offset].
  /// 
  /// Returns a record containing the decoded object and the number of 
  /// bytes consumed. Consumes [length] bytes.
  /// 
  /// * [buffer]: The binary data source.
  /// * [offset]: The starting position.
  ({Object? object, int length}) read(ByteData buffer, int offset);
  
  /// Encodes an [object] into the [buffer].
  /// 
  /// Appends the binary representation of the object to the stream.
  /// 
  /// * [buffer]: The target output stream.
  /// * [object]: The value to serialize.
  void write(Uint8Buffer buffer, Object? object);
  
  /// Allows the parser to be used as a callable, returning itself.
  /// 
  /// Provides a more concise syntax when defining [FunctionEntry] lists.
  TypeParser call() {
    return this;
  }
}

Type _typeGetter<T>() {
  return T;
}

/// Utility extension to retrieve a default [TypeParser] for a given [Type].
/// 
/// ```dart
/// final parser = int.parser;
/// ```
extension TypeParserExtension on Type {
  /// Returns a non-nullable [TypeParser] for this type, if a default exists.
  /// 
  /// Maps standard Dart types to their corresponding binary parsers.
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

  /// Returns a nullable [TypeParser] for this type.
  /// 
  /// Wraps the default parser in a [_NullableTypeParser].
  TypeParser get nullableParser => TypeParser.nullable(parser);
}

/// Utility extension to easily generate [FunctionEntry] metadata from a [Function].
/// 
/// ```dart
/// void myFunc(int x) => print(x);
/// final entry = myFunc.describe([TypeParser.int32]);
/// ```
extension FunctionDescriptorExtension on Function {
  /// Creates a [FunctionEntry] using this function as the target.
  /// 
  /// Links the function signature to its binary serialization metadata.
  /// 
  /// * [parameters]: The list of parsers for the function's arguments.
  /// * [returnType]: Optional parser for the return value (defaults to `void`).
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

/// Internal parser for `void` return types.
/// 
/// This parser is used to represent the absence of a return value in 
/// RPC signatures. It consumes no data during transmission.
/// 
/// ```dart
/// const parser = TypeParser.voidType;
/// ```
/// 
/// See also [TypeParser] for the base interface.
class _VoidTypeParser extends TypeParser {
  /// Creates a void type parser.
  /// 
  /// Used for functions that do not return a value.
  const _VoidTypeParser();

  @override
  ({int length, Object? object}) read(ByteData buffer, int offset) {
    return (length: 0, object: null);
  }

  @override
  void write(Uint8Buffer buffer, Object? object) {}
}

/// Internal parser that wraps another [parser] to support `null` values.
/// 
/// This parser adds a single byte prefix (1 for non-null, 0 for null) 
/// to the serialized stream, allowing any type to be nullable.
/// 
/// ```dart
/// const parser = TypeParser.nullable(TypeParser.int32);
/// ```
/// 
/// See also [TypeParser] for the base interface.
class _NullableTypeParser extends TypeParser {
  /// The underlying non-nullable parser.
  /// 
  /// Used to decode the actual value if the null byte is not set.
  final TypeParser nonNullParser;

  /// Creates a nullable type parser wrapping [nonNullParser].
  /// 
  /// Adds a boolean flag before the value to indicate presence.
  /// 
  /// * [nonNullParser]: The parser for the non-null value.
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

/// A function that decomposes an object of type [T] into a list of serializable fields.
typedef ObjectSerializer<T> = List<Object?> Function(T object);

/// A function that reconstructs an object of type [T] from a list of deserialized fields.
typedef ObjectDeserializer<T> = T Function(List<Object?> args);

/// A [TypeParser] implementation for custom composite objects.
/// 
/// ```dart
/// final parser = ObjectTypeParser(
///   parsers: [TypeParser.int32],
///   serializer: (o) => [o.val],
///   deserializer: (args) => MyObj(args[0] as int),
/// );
/// ```
class ObjectTypeParser<T> extends TypeParser {
  /// The list of parsers for the object's individual fields.
  /// 
  /// Defines the sequence and type of data members.
  final List<TypeParser> parsers;
  
  /// The function used to serialize the object.
  /// 
  /// Breaks down the instance of [T] into raw field values.
  final ObjectSerializer<T> serializer;
  
  /// The function used to deserialize the object.
  /// 
  /// Reconstructs the instance of [T] from raw field values.
  final ObjectDeserializer<T> deserializer;

  /// Creates an [ObjectTypeParser].
  /// 
  /// Initializes the parser with its field definitions and logic.
  /// 
  /// * [parsers]: The field metadata.
  /// * [serializer]: The encoding logic.
  /// * [deserializer]: The decoding logic.
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
