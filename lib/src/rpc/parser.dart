import 'dart:convert';
import 'dart:typed_data';

import 'package:goo2d/src/rpc/buffer.dart';
import 'package:goo2d/src/rpc/parsers.dart';

/// A registry interface for reading and writing RPC function calls.
///
/// [FunctionRegistry] defines the contract for serializing function 
/// identifiers and their arguments into a binary format, and for 
/// reconstructing those calls from a buffer. It is primarily implemented 
/// by [RPCRegistry].
///
/// ```dart
/// // Internal interface used by RPC systems
/// // abstract class MyRegistry implements FunctionRegistry {
/// //   @override
/// //   void writeFunctionCallRequest(Uint8ListBuffer b, {required Function function, required List<Object> parameters}) {}
/// //   @override
/// //   readFunctionCallRequest(ByteData b, [int o = 0]) => throw UnimplementedError();
/// // }
/// ```
///
/// See also:
/// * [RPCRegistry] for the concrete implementation of this interface.
abstract class FunctionRegistry {
  /// Reads a function call request from the provided buffer.
  ///
  /// Returns a record containing a closure that executes the function, 
  /// the number of bytes read, and the metadata for the function.
  ///
  /// * [buffer]: The binary data to read from.
  /// * [offset]: The starting position in the buffer.
  ({Object? Function() function, int length, FunctionEntry entry})
  readFunctionCallRequest(ByteData buffer, [int offset = 0]);

  /// Serializes a function call request into the provided [Uint8ListBuffer].
  ///
  /// This method packs the function identifier and all its parameters 
  /// according to the registered [TypeParser]s.
  ///
  /// * [buffer]: The destination byte buffer.
  /// * [function]: The local function reference to call.
  /// * [parameters]: The arguments to be serialized.
  void writeFunctionCallRequest(
    Uint8ListBuffer buffer, {
    required Function function,
    required List<Object> parameters,
  });
}

/// Metadata for an RPC-capable function.
///
/// [FunctionEntry] stores the actual [Function] reference along with 
/// [TypeParser]s for its return value and parameters. This information 
/// is used by the registry to handle type-safe serialization.
///
/// ```dart
/// void myFunc(int a, String b) {}
/// 
/// final entry = FunctionEntry(
///   function: myFunc,
///   returnType: TypeParser.voidType,
///   parameterTypes: [TypeParser.int32, TypeParser.string()],
/// );
/// ```
///
/// See also:
/// * [FunctionRegistry] for the manager that uses these entries.
/// * [TypeParser] for the system used to serialize individual types.
class FunctionEntry {
  /// The local function implementation.
  ///
  /// This reference is used by the registry to execute the function 
  /// after its arguments have been successfully deserialized.
  final Function function;

  /// The parser used to handle the function's return value.
  ///
  /// This parser is responsible for serializing the result of the 
  /// function call back into a binary format for the remote peer.
  final TypeParser returnType;

  /// The list of parsers used to handle the function's parameters.
  ///
  /// Each parser in this list corresponds to an argument in the 
  /// [function], ensuring type-safe deserialization of incoming data.
  final List<TypeParser> parameterTypes;

  /// Creates a new function entry with explicit type parsers.
  ///
  /// This constructor is used to define a function's signature for 
  /// both local registration and remote invocation.
  ///
  /// * [function]: The actual Dart function implementation.
  /// * [returnType]: The parser for the function's return value.
  /// * [parameterTypes]: The list of parsers for the function's parameters.
  const FunctionEntry({
    required this.function,
    required this.returnType,
    required this.parameterTypes,
  });
}

/// A callback that creates an instance of a specific type.
typedef TypeParserConstructor<T> = T Function();

/// The base class for all binary type serializers and deserializers.
///
/// [TypeParser] provides a unified interface for reading and writing 
/// fundamental Dart types (int, String, etc.) and complex objects 
/// into a binary format. It includes a wide range of static factories 
/// for common types.
///
/// ```dart
/// final parser = TypeParser.int32;
/// final buffer = Uint8ListBuffer();
/// 
/// parser.write(buffer, 42);
/// final result = parser.read(ByteData.sublistView(buffer.compact), 0);
/// // result.object == 42
/// ```
///
/// See also:
/// * [Uint8ListBuffer] for the destination of write operations.
/// * [FunctionEntry] for how these parsers are grouped for RPC.
abstract class TypeParser {
  /// A parser that handles 'void' return types by doing nothing.
  ///
  /// This parser is used for functions that do not return a value,
  /// consuming and producing zero bytes during serialization.
  static const voidType = _VoidTypeParser();

  /// Wraps a parser to handle nullable values by adding a prefix byte.
  ///
  /// This factory adds a one-byte header (1 for non-null, 0 for null)
  /// before delegating to the underlying [parser] if the value is present.
  ///
  /// * [parser]: The underlying parser for the non-null value.
  const factory TypeParser.nullable(TypeParser parser) = _NullableTypeParser;

  /// A parser for signed 8-bit integers.
  ///
  /// This parser handles values from -128 to 127 and is the most
  /// compact way to represent small signed numbers.
  static const int8 = Int8Parser();

  /// A parser for unsigned 8-bit integers.
  ///
  /// This parser handles values from 0 to 255, ideal for flags,
  /// small counts, or byte-oriented data.
  static const uint8 = Uint8Parser();

  /// A parser for signed 16-bit integers.
  ///
  /// This parser handles values from -32,768 to 32,767, providing
  /// a balance between range and memory usage.
  static const int16 = Int16Parser();

  /// A parser for unsigned 16-bit integers.
  ///
  /// This parser handles values from 0 to 65,535, often used for
  /// length prefixes or larger counts.
  static const uint16 = Uint16Parser();

  /// A parser for signed 32-bit integers.
  ///
  /// This is the default signed integer type, handling values up to
  /// approximately +/- 2.1 billion.
  static const int32 = Int32Parser();

  /// A parser for unsigned 32-bit integers.
  ///
  /// This parser handles values up to approximately 4.2 billion,
  /// suitable for large offsets or identifiers.
  static const uint32 = Uint32Parser();

  /// A parser for signed 64-bit integers.
  ///
  /// This parser handles the full range of Dart's 64-bit integers,
  /// used for very large numbers or high-precision timestamps.
  static const int64 = Int64Parser();

  /// A parser for unsigned 64-bit integers.
  ///
  /// This handles the full 64-bit unsigned range, typically used for
  /// unique global identifiers or raw memory addresses.
  static const uint64 = Uint64Parser();

  /// A parser for 32-bit floating-point numbers.
  ///
  /// This provides single-precision floating point serialization,
  /// saving 4 bytes over the default 64-bit double when high
  /// precision is not required.
  static const float32 = Float32Parser();

  /// A parser for 64-bit floating-point numbers.
  ///
  /// This is the default double-precision floating point parser,
  /// matching Dart's standard [double] type representation.
  static const float64 = Float64Parser();

  /// A parser for boolean values (1 byte).
  ///
  /// This parser encodes true as 1 and false as 0, using a single
  /// byte to minimize packet size.
  static const bool = BoolParser();

  /// Creates a parser for string values with an optional encoding and limit.
  ///
  /// * [encoding]: The text encoding to use (defaults to UTF-8).
  /// * [limit]: The maximum allowed length for the string.
  const factory TypeParser.string({Encoding encoding, int limit}) =
      StringParser;

  /// Creates a parser for raw byte arrays with an optional size limit.
  ///
  /// * [limit]: The maximum allowed number of bytes.
  const factory TypeParser.uint8List({int limit}) = Uint8ListParser;

  /// Creates a parser for lists of a specific type.
  ///
  /// * [elementParser]: The parser for individual list items.
  /// * [limit]: The maximum number of items in the list.
  static TypeParser list<T>(TypeParser elementParser, {int limit = 65535}) =>
      ListParser<T>(elementParser, limit: limit);

  /// Creates a parser for sets of a specific type.
  ///
  /// * [elementParser]: The parser for individual set items.
  /// * [limit]: The maximum number of items in the set.
  static TypeParser set<T>(TypeParser elementParser, {int limit = 65535}) =>
      SetParser<T>(elementParser, limit: limit);

  /// Creates a parser for maps with specific key and value types.
  ///
  /// * [keyParser]: The parser for map keys.
  /// * [valueParser]: The parser for map values.
  /// * [limit]: The maximum number of entries in the map.
  static TypeParser map<K, V>(
    TypeParser keyParser,
    TypeParser valueParser, {
    int limit = 65535,
  }) => MapParser<K, V>(keyParser, valueParser, limit: limit);

  /// Creates a custom parser for complex objects using mapping functions.
  ///
  /// * [serializer]: Converts the object into a list of fields.
  /// * [deserializer]: Reconstructs the object from a list of fields.
  /// * [fields]: The list of parsers for each field in order.
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
  /// This constructor is marked as const to allow for compile-time
  /// optimization of parser instances and their use in static fields.
  const TypeParser();

  /// Reads a value of type [T] from the buffer at the given offset.
  ///
  /// This method is called by the [RPCRegistry] to deserialize 
  /// function arguments and return values received from the network.
  /// It returns both the reconstructed object and the total number
  /// of bytes consumed from the buffer.
  ///
  /// * [buffer]: The binary data containing the serialized object.
  /// * [offset]: The position in the buffer where reading should start.
  ({Object? object, int length}) read(ByteData buffer, int offset);

  /// Writes a value of type [T] to the provided buffer.
  ///
  /// This method is called by the [RPCRegistry] to serialize 
  /// outgoing function calls and responses. It ensures that the
  /// buffer is correctly sized before performing the write operation.
  ///
  /// * [buffer]: The destination buffer for the serialized data.
  /// * [object]: The value to be written to the buffer.
  void write(Uint8ListBuffer buffer, Object? object);

  /// Returns the parser itself. 
  /// 
  /// This allows using the parser as a factory in some contexts,
  /// enabling a concise syntax when defining nested type parsers.
  ///
  /// It provides a common interface for fluent configuration of 
  /// type definitions within an RPC system.
  TypeParser call() {
    return this;
  }
}

/// Internal helper to retrieve a [Type] instance from a generic parameter.
///
/// This is used by the [TypeParserExtension] to identify specific
/// Dart types during the default parser lookup process.
Type _typeGetter<T>() {
  return T;
}

/// Extensions on [Type] to provide convenient access to default parsers.
///
/// This extension allows users to retrieve the registered [TypeParser] 
/// for a given Dart type using a property-like syntax.
extension TypeParserExtension on Type {
  /// Returns the default [TypeParser] associated with this type.
  ///
  /// The returned parser is the one registered in the global type 
  /// map for the specific Dart [Type].
  ///
  /// Throws an [UnimplementedError] if no default parser is registered 
  /// for the type.
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

  /// Returns a nullable version of the default [TypeParser] for this type.
  ///
  /// This method wraps the current parser in a decorator that 
  /// handles the one-byte nullability prefix.
  TypeParser get nullableParser => TypeParser.nullable(parser);
}

/// Extensions on [Function] to describe them for RPC registration.
///
/// This extension provides an ergonomic way to convert standard Dart 
/// function objects into [FunctionEntry] metadata using the [describe] 
/// method.
extension FunctionDescriptorExtension on Function {
  /// Creates a [FunctionEntry] metadata object for this function.
  ///
  /// This method allows for a declarative syntax when defining the 
  /// RPC API surface for a [NetworkManager].
  ///
  /// * [parameters]: The list of parsers for the function's arguments.
  /// * [returnType]: The parser for the function's return value (defaults to void).
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

/// Internal parser for 'void' return types.
///
/// This class provides a singleton-like implementation for [TypeParser.voidType],
/// ensuring that void functions do not consume any buffer space.
class _VoidTypeParser extends TypeParser {
  /// Creates a constant void type parser.
  ///
  /// This constructor is private to the library, as instances should
  /// be accessed via [TypeParser.voidType].
  const _VoidTypeParser();

  @override
  ({int length, Object? object}) read(ByteData buffer, int offset) {
    return (length: 0, object: null);
  }

  @override
  void write(Uint8ListBuffer buffer, Object? object) {}
}

/// Internal parser for nullable types.
///
/// This decorator class wraps an existing [TypeParser] and adds
/// logic to handle null values using a single-byte presence flag.
class _NullableTypeParser extends TypeParser {
  /// The underlying parser used when the value is not null.
  ///
  /// This parser is only invoked if the presence byte at the start
  /// of the field is set to 1.
  final TypeParser nonNullParser;

  /// Creates a nullable parser wrapping the [nonNullParser].
  ///
  /// This allows any existing parser to be upgraded to handle
  /// null values in a standardized way.
  const _NullableTypeParser(this.nonNullParser);

  @override
  ({int length, Object? object}) read(ByteData buffer, int offset) {
    final isNotNull = buffer.getUint8(offset) == 1;
    if (isNotNull) {
      final res = nonNullParser.read(buffer, offset + 1);
      return (length: res.length + 1, object: res.object);
    } else {
      return (length: 1, object: null);
    }
  }

  @override
  void write(Uint8ListBuffer buffer, Object? object) {
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

/// A callback that serializes an object into a list of fields.
typedef ObjectSerializer<T> = List<Object?> Function(T object);

/// A callback that reconstructs an object from a list of fields.
typedef ObjectDeserializer<T> = T Function(List<Object?> args);

/// A parser for custom object types that maps fields to binary data.
///
/// [ObjectTypeParser] allows for the serialization of complex Dart 
/// classes by decomposing them into a list of fields that can be 
/// individually handled by other [TypeParser]s.
///
/// ```dart
/// class Point {
///   final int x, y;
///   Point(this.x, this.y);
/// }
///
/// final pointParser = TypeParser.object<Point>(
///   fields: [TypeParser.int32, TypeParser.int32],
///   serializer: (p) => [p.x, p.y],
///   deserializer: (args) => Point(args[0] as int, args[1] as int),
/// );
/// ```
///
/// See also:
/// * [TypeParser] for the base class of all parsers.
/// * [RPCRegistry] for how objects are used in remote calls.
class ObjectTypeParser<T> extends TypeParser {
  /// The list of parsers for each field of the object.
  ///
  /// These parsers are applied sequentially during serialization 
  /// and deserialization to handle the object's constituent data.
  final List<TypeParser> parsers;

  /// The function that decomposes the object into fields.
  ///
  /// This callback is used by the [write] method to extract 
  /// values from an instance of [T] before they are serialized.
  final ObjectSerializer<T> serializer;

  /// The function that reassembles the object from fields.
  ///
  /// This callback is used by the [read] method to construct 
  /// a new instance of [T] from the deserialized field values.
  final ObjectDeserializer<T> deserializer;

  /// Creates an object parser with the specified field parsers.
  ///
  /// This constructor sets up the transformation logic required 
  /// to move data between Dart objects and binary buffers.
  ///
  /// * [parsers]: The list of parsers for each object field.
  /// * [serializer]: Function to decompose the object.
  /// * [deserializer]: Function to reassemble the object.
  const ObjectTypeParser({
    required this.parsers,
    required this.serializer,
    required this.deserializer,
  });

  @override
  ({int length, Object? object}) read(ByteData buffer, int offset) {
    final List<Object?> params = [];
    int totalLength = 0;
    for (int i = 0; i < parsers.length; i++) {
      final ({int length, Object? object}) result = parsers[i].read(
        buffer,
        offset + totalLength,
      );
      params.add(result.object);
      totalLength += result.length;
    }
    return (
      length: totalLength,
      object: deserializer(params),
    );
  }

  @override
  void write(Uint8ListBuffer buffer, Object? object) {
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
