import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:goo2d/src/rpc/parser.dart';
import 'package:goo2d/src/rpc/registry.dart';
import 'package:goo2d/src/rpc/rpc.dart';

void main() {
  group('RPCRegistry', () {
    test('Round-trip function call', () async {
      int sum(int a, int b) => a + b;

      Uint8List? capturedData;
      final registry = RPCRegistry(
        functions: [
          sum.describe([
            TypeParser.int32,
            TypeParser.int32,
          ], returnType: TypeParser.int32),
        ],
        writer: (buffer) {
          capturedData = buffer.compact;
        },
      );

      // 1. Initiate RPC call (sends request)
      final future = registry[sum]([10, 20]);
      expect(capturedData, isNotNull);
      final request = capturedData!;

      // 2. Remote side receives request and sends back response
      // In this test, we use the same registry to simulate the remote side.
      // handleReadUint8List will execute the function and call writer() with the result.
      registry.handleReadUint8List(request);
      expect(capturedData, isNot(equals(request)));
      final response = capturedData!;

      // 3. Original side receives response
      registry.handleReadUint8List(response);

      final result = await future;
      expect(result, 30);
    });

    test('RPC timeout', () async {
      void testFunc() {}
      final registry = RPCRegistry(
        functions: [testFunc.describe([])],
        writer: (_) {},
      );

      final future = registry[testFunc]([], timeout: const Duration(milliseconds: 10));
      expect(() => future, throwsA(isA<Exception>()));
    });
  });

  group('NetworkManager', () {
    test('Polls data and handles RPC', () {
      final mockInterface = MockNetworkInterface();
      final manager = NetworkManager()..networkInterface = mockInterface;

      bool functionCalled = false;
      void testFunction() {
        functionCalled = true;
      }

      manager.functions = [testFunction.describe([])];

      // Prepare a request packet for testFunction (index 0)
      // Request format: uint16 requestId (1), uint16 functionIndex (0)
      final request = Uint8List(4);
      final bd = ByteData.view(request.buffer);
      bd.setUint16(0, 1); // requestId 1, isResponse = 0
      bd.setUint16(2, 0); // functionIndex 0

      mockInterface.incoming.add(request);

      manager.onUpdate(0);

      expect(functionCalled, true);
    });

    test('Sends data through NetworkInterface', () {
      final mockInterface = MockNetworkInterface();
      final manager = NetworkManager()..networkInterface = mockInterface;

      void testFunction() {}
      manager.functions = [testFunction.describe([])];

      // Initiate a call
      manager.call(testFunction, []);

      // Verify that data was sent through the interface
      expect(mockInterface.outgoing, isNotEmpty);
    });
  });
}

class MockNetworkInterface implements NetworkInterface {
  final List<Uint8List> outgoing = [];
  final List<Uint8List> incoming = [];

  @override
  Uint8List? pollData() => incoming.isEmpty ? null : incoming.removeAt(0);

  @override
  void sendData(Uint8List packet) => outgoing.add(packet);
}
