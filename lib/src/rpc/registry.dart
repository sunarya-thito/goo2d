import 'dart:async';
import 'dart:typed_data';

import 'package:goo2d/src/rpc/buffer.dart';
import 'package:goo2d/src/rpc/parser.dart';

typedef RPCBytesCallback = void Function(Uint8Buffer bytes);

class RPC {
  final RPCRegistry registry;
  final FunctionEntry entry;
  RPC._(this.registry, this.entry);
  Future<T> call<T>(
    List<Object> args, {
    Duration timeout = const Duration(seconds: 30),
  }) {
    final requestId = registry._nextRequestId;
    final completer = Completer<Object?>();
    registry._functionCallCompleters[requestId] = RPCRequest._(
      entry,
      completer,
    );

    final buffer = Uint8Buffer();
    buffer.write(2, () {
      buffer.byteData.setUint16(0, requestId);
    });
    registry.writeFunctionCallRequest(
      buffer,
      function: entry.function,
      parameters: args,
    );
    registry.writer(buffer);
    return completer.future
        .timeout(
          timeout,
          onTimeout: () {
            registry._functionCallCompleters.remove(requestId);
            throw Exception('RPC call timed out');
          },
        )
        .then((obj) => obj as T);
  }
}

class RPCRequest {
  final FunctionEntry function;
  final Completer<Object?> completer;
  RPCRequest._(this.function, this.completer);
}

class RPCRegistry implements FunctionRegistry {
  final List<FunctionEntry> functions;
  final RPCBytesCallback writer;

  final Map<int, RPCRequest> _functionCallCompleters = {};

  int _requestCounter = 0;
  RPCRegistry({required this.functions, required this.writer});

  int get _nextRequestId {
    // limit to uint15 (max 32767)
    _requestCounter++;
    if (_requestCounter > 32767) {
      _requestCounter = 0;
    }
    return _requestCounter;
  }

  int handleReadData(ByteData data, [int offset = 0]) {
    final packed = data.getUint16(offset);
    final isResponse = packed & 0x8000;
    final requestId = packed & 0x7fff;
    offset += 2;

    if (isResponse == 0) {
      // request
      final result = readFunctionCallRequest(data, offset);
      final buffer = Uint8Buffer();
      buffer.write(2, () {
        buffer.byteData.setUint16(0, requestId | 0x8000);
      });
      result.entry.returnType.write(buffer, result.function());
      writer(buffer);
      return result.length;
    } else {
      // response
      final request = _functionCallCompleters.remove(requestId);
      if (request == null) {
        // handle timeout or invalid request
        return 0;
      }

      final result = request.function.returnType.read(data, offset);
      request.completer.complete(result.object);
      return result.length;
    }
  }

  void handleReadBytes(List<int> bytes) {
    final buffer = ByteData.sublistView(Uint8List.fromList(bytes));
    handleReadData(buffer);
  }

  void handleReadUint8List(Uint8List list) {
    handleReadData(ByteData.sublistView(list));
  }

  RPC operator [](Function function) {
    return RPC._(
      this,
      functions.firstWhere(
        (entry) => entry.function == function,
        orElse: () {
          throw Exception('Function not found: ${function.toString()}');
        },
      ),
    );
  }

  @override
  ({Object? Function() function, int length, FunctionEntry entry})
  readFunctionCallRequest(ByteData buffer, [int offset = 0]) {
    final index = buffer.getUint16(offset);
    final entry = functions[index];
    final paramLength = entry.parameterTypes.length;
    var length = 2;
    final arguments = <Object?>[];
    for (int i = 0; i < paramLength; i++) {
      final parser = entry.parameterTypes[i];
      final result = parser.read(buffer, offset + length);
      length += result.length;
      arguments.add(result.object);
    }
    return (
      length: length,
      function: () {
        return Function.apply(entry.function, arguments);
      },
      entry: entry,
    );
  }

  @override
  void writeFunctionCallRequest(
    Uint8Buffer buffer, {
    required Function function,
    required List<Object> parameters,
  }) {
    final index = functions.indexWhere((entry) => entry.function == function);
    assert(index != -1, 'Function not found');
    buffer.write(2, () {
      buffer.byteData.setUint16(buffer.offset, index);
    });
    for (int i = 0; i < parameters.length; i++) {
      final parser = functions[index].parameterTypes[i];
      parser.write(buffer, parameters[i]);
    }
  }
}
