import 'dart:async';
import 'dart:typed_data';

import 'package:goo2d/src/rpc/buffer.dart';
import 'package:goo2d/src/rpc/parser.dart';

/// A callback function used by the [RPCRegistry] to send raw binary data.
/// 
/// This callback is typically linked to a network socket or an isolate port.
typedef RPCBytesCallback = void Function(Uint8Buffer bytes);

/// A handle to a specific RPC function that can be invoked locally or remotely.
/// 
/// [RPC] objects are created by the [RPCRegistry] and provide a convenient 
/// way to trigger remote execution with type-safe arguments and return values.
/// Links to [FunctionEntry] for signature details.
/// 
/// ```dart
/// final rpc = registry[myFunc];
/// final result = await rpc.call([42]);
/// ```
class RPC {
  /// The registry that owns this RPC.
  /// 
  /// Handles the actual transmission and response tracking.
  final RPCRegistry registry;
  
  /// The metadata defining the function signature.
  /// 
  /// Used for serializing arguments correctly.
  final FunctionEntry entry;

  /// Internal constructor for [RPC] handles.
  /// 
  /// This constructor initializes the handle with the registry and 
  /// function entry required for remote invocation.
  /// 
  /// * [registry]: The registry that owns this handle.
  /// * [entry]: The function signature metadata.
  RPC._(this.registry, this.entry);

  /// Invokes the remote function with the given [args].
  /// 
  /// Encodes the arguments and sends them to the remote peer. Returns a 
  /// [Future] that completes when the response is received.
  /// 
  /// * [args]: The list of arguments to pass to the function.
  /// * [timeout]: The maximum time to wait for a response.
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

/// Internal representation of an active RPC request awaiting a response.
/// 
/// Tracks the original function and the completion status. Links to 
/// [RPCRegistry] for management.
/// 
/// ```dart
/// final request = RPCRequest._(entry, completer);
/// ```
class RPCRequest {
  /// The function metadata associated with the request.
  /// 
  /// Used to decode the return value when it arrives.
  final FunctionEntry function;
  
  /// The completer used to resolve the [Future] when a response arrives.
  /// 
  /// Links the incoming data to the original caller.
  final Completer<Object?> completer;

  /// Internal constructor for [RPCRequest].
  /// 
  /// This constructor initializes the metadata and completion handle for 
  /// an outgoing RPC call.
  /// 
  /// * [function]: The function metadata associated with the request.
  /// * [completer]: The completer used to resolve the response.
  RPCRequest._(this.function, this.completer);
}

/// The central registry that coordinates RPC dispatching and response handling.
/// 
/// [RPCRegistry] manages a mapping of unique function IDs to their 
/// [FunctionEntry] definitions. It handles both outgoing requests (via 
/// [RPC.call]) and incoming packets (via [handleReadData]).
/// 
/// It uses a 15-bit request ID system to track pending calls, allowing 
/// for asynchronous request/response cycles.
/// 
/// ```dart
/// final registry = RPCRegistry(functions: [entry], writer: (b) => socket.add(b));
/// ```
class RPCRegistry implements FunctionRegistry {
  /// The list of functions available in this registry.
  /// 
  /// Defines the set of callable procedures and their binary format.
  final List<FunctionEntry> functions;
  
  /// The callback used to transmit serialized packets.
  /// 
  /// Invoked whenever an RPC call or response is ready to be sent.
  final RPCBytesCallback writer;

  final Map<int, RPCRequest> _functionCallCompleters = {};

  int _requestCounter = 0;

  /// Creates an [RPCRegistry] with the given [functions] and [writer].
  /// 
  /// Initializes the registry for remote communication.
  /// 
  /// * [functions]: The list of supported remote procedures.
  /// * [writer]: The binary transmission sink.
  RPCRegistry({required this.functions, required this.writer});

  int get _nextRequestId {
    // limit to uint15 (max 32767)
    _requestCounter++;
    if (_requestCounter > 32767) {
      _requestCounter = 0;
    }
    return _requestCounter;
  }

  /// Processes a raw [ByteData] packet and handles either a request or a response.
  /// 
  /// If the packet is a request, it executes the local function and sends 
  /// a response back. If it's a response, it completes the corresponding 
  /// pending [RPCRequest].
  /// 
  /// * [data]: The incoming binary packet.
  /// * [offset]: The starting position in the buffer.
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

  /// Convenience method to handle a raw list of [bytes].
  /// 
  /// Wraps the byte list in a [ByteData] view and processes it.
  /// 
  /// * [bytes]: The raw byte sequence.
  void handleReadBytes(List<int> bytes) {
    final buffer = ByteData.sublistView(Uint8List.fromList(bytes));
    handleReadData(buffer);
  }

  /// Convenience method to handle a [Uint8List].
  /// 
  /// Directly processes the byte list as binary data.
  /// 
  /// * [list]: The raw byte array.
  void handleReadUint8List(Uint8List list) {
    handleReadData(ByteData.sublistView(list));
  }

  /// Looks up an [RPC] handle for a specific [function] closure.
  /// 
  /// Searches for the matching [FunctionEntry] in the registry.
  /// 
  /// * [function]: The target closure to look up.
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
