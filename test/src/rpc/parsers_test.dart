import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:goo2d/src/rpc/buffer.dart';
import 'package:goo2d/src/rpc/parser.dart';

void main() {
  group('RPC Parsers', () {
    late Uint8Buffer buffer;

    setUp(() {
      buffer = Uint8Buffer();
    });

    Object? roundTrip(TypeParser parser, Object? value) {
      buffer = Uint8Buffer();
      parser.write(buffer, value);
      final data = buffer.compact;
      final byteData = ByteData.view(data.buffer);
      final result = parser.read(byteData, 0);
      return result.object;
    }

    test('Numeric Parsers', () {
      expect(roundTrip(TypeParser.int8, 127), 127);
      expect(roundTrip(TypeParser.int8, -128), -128);
      expect(roundTrip(TypeParser.uint8, 255), 255);

      expect(roundTrip(TypeParser.int16, 32767), 32767);
      expect(roundTrip(TypeParser.int16, -32768), -32768);
      expect(roundTrip(TypeParser.uint16, 65535), 65535);

      expect(roundTrip(TypeParser.int32, 2147483647), 2147483647);
      expect(roundTrip(TypeParser.int32, -2147483648), -2147483648);
      expect(roundTrip(TypeParser.uint32, 4294967295), 4294967295);

      expect(
        roundTrip(TypeParser.int64, 9223372036854775807),
        9223372036854775807,
      );
      expect(
        roundTrip(TypeParser.uint64, 9223372036854775807),
        9223372036854775807,
      );

      expect(
        roundTrip(TypeParser.float32, 3.140000104904175),
        3.140000104904175,
      );
      expect(roundTrip(TypeParser.float64, 3.1415926535), 3.1415926535);
    });

    test('Bool Parser', () {
      expect(roundTrip(TypeParser.bool, true), true);
      expect(roundTrip(TypeParser.bool, false), false);
    });

    test('String Parser', () {
      expect(roundTrip(TypeParser.string(), 'Hello World'), 'Hello World');
      expect(roundTrip(TypeParser.string(encoding: ascii), 'ASCII'), 'ASCII');

      final limitedParser = TypeParser.string(limit: 5);
      expect(roundTrip(limitedParser, '12345'), '12345');
      expect(() => limitedParser.write(buffer, '123456'), throwsException);
    });

    test('Uint8List Parser', () {
      final list = Uint8List.fromList([1, 2, 3, 4, 5]);
      expect(roundTrip(TypeParser.uint8List(), list), list);
    });

    test('Collection Parsers', () {
      final list = [1, 2, 3];
      expect(roundTrip(TypeParser.list(TypeParser.int32), list), list);

      final set = {1, 2, 3};
      expect(roundTrip(TypeParser.set(TypeParser.int32), set), set);

      final map = {'a': 1, 'b': 2};
      expect(
        roundTrip(TypeParser.map(TypeParser.string(), TypeParser.int32), map),
        map,
      );
    });

    test('Nullable Parser', () {
      final nullableInt = TypeParser.nullable(TypeParser.int32);
      expect(roundTrip(nullableInt, 123), 123);
      expect(roundTrip(nullableInt, null), null);
    });

    test('Object Type Parser', () {
      final parser = TypeParser.object<TestObject>(
        serializer: (obj) => [obj.id, obj.name],
        deserializer: (args) =>
            TestObject(id: args[0] as int, name: args[1] as String),
        fields: [TypeParser.int32(), TypeParser.string()],
      );

      final obj = TestObject(id: 1, name: 'Test');
      final result = roundTrip(parser, obj) as TestObject;

      expect(result.id, obj.id);
      expect(result.name, obj.name);
    });

    test('Dynamic Length Prefix', () {
      // Test that uint8 prefix is used for small limit
      final smallLimit = TypeParser.string(limit: 255);
      smallLimit.write(buffer, 'a');
      expect(buffer.compact.length, 1 + 1); // 1 byte prefix + 1 byte char

      // Test that uint16 prefix is used for medium limit
      buffer = Uint8Buffer();
      final mediumLimit = TypeParser.string(limit: 65535);
      mediumLimit.write(buffer, 'a');
      expect(buffer.compact.length, 2 + 1); // 2 byte prefix + 1 byte char

      // Test that uint32 prefix is used for large limit
      buffer = Uint8Buffer();
      final largeLimit = TypeParser.string(
        limit: 4294967296,
      ); // limit > uint32 max
      largeLimit.write(buffer, 'a');
      expect(buffer.compact.length, 8 + 1); // 8 byte prefix + 1 byte char
    });
  });
}

class TestObject {
  final int id;
  final String name;
  TestObject({required this.id, required this.name});
}
