import 'dart:async';
import 'dart:typed_data';

import 'package:goo2d/src/rpc/buffer.dart';
import 'package:goo2d/src/rpc/parser.dart';

/// A callback function used to transmit serialized RPC data.
///
/// This is typically provided to the [RPCRegistry] to define how 
/// binary packets should be sent over the network (e.g., via a socket). 
/// The callback receives a [Uint8Buffer] which contains the complete 
/// packet ready for transmission.
typedef RPCBytesCallback = void Function(Uint8Buffer bytes);

/// Represents a handle to a remote-callable function.
///
/// [RPC] objects are obtained from an [RPCRegistry] using the index 
/// operator. They provide a [call] method that handles the complexities 
/// of asynchronous request/response tracking and serialization.
///
/// ```dart
/// void myFunc(int a) {}
/// 
/// void main() async {
///   final registry = RPCRegistry(
///     functions: [myFunc.describe([TypeParser.int32])],
///     writer: (bytes) {},
///   );
///   
///   final rpc = registry[myFunc];
///   await rpc.call([42]);
/// }
/// ```
///
/// See also:
/// * [RPCRegistry] for the manager that creates these objects.
class RPC {
  /// The registry that owns this RPC handle.
  ///
  /// This registry provides the context for serialization and 
  /// request ID management when making calls through this handle.
  final RPCRegistry registry;

  /// The function entry containing metadata about the remote function.
  ///
  /// This entry defines the parameter types and return type required 
  /// to correctly pack and unpack the data for this specific RPC.
  final FunctionEntry entry;

  RPC._(this.registry, this.entry);

  /// Invokes the remote function with the specified arguments.
  ///
  /// This method serializes the [args], generates a unique request ID, 
  /// and waits for the remote peer to return a response or for the 
  /// [timeout] to expire.
  ///
  /// * [args]: The list of arguments to pass to the remote function.
  /// * [timeout]: The maximum duration to wait for a response.
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

/// Internal state for an ongoing RPC request.
///
/// This class tracks the original [FunctionEntry] and a [Completer] 
/// that will be resolved when the corresponding response arrives. 
/// It is used internally by [RPCRegistry] to manage the lifecycle 
/// of asynchronous calls.
///
/// ```dart
/// // This class is handled internally by the RPC system.
/// // final request = RPCRequest._(entry, completer);
/// ```
///
/// See also:
/// * [RPCRegistry] for the manager that creates these requests.
/// * [FunctionEntry] for the metadata stored in this request.
class RPCRequest {
  /// The metadata of the function that was called.
  ///
  /// This is used to determine how to deserialize the incoming 
  /// response data when it arrives from the network.
  final FunctionEntry function;

  /// The completer used to resolve the asynchronous call.
  ///
  /// This completer is completed with the return value of the remote 
  /// function, allowing the caller to await the result.
  final Completer<Object?> completer;

  RPCRequest._(this.function, this.completer);
}

/// A registry for managing local and remote function signatures.
///
/// [RPCRegistry] acts as a central hub for RPC operations. It maintains 
/// a list of [FunctionEntry] objects and handles the low-level 
/// dispatching of incoming binary packets to local function calls 
/// or response completers.
///
/// ```dart
/// void myFunc() {}
///
/// void main() {
///   final registry = RPCRegistry(
///     functions: [myFunc.describe([])],
///     writer: (bytes) => print('Sending ${bytes.length} bytes'),
///   );
///   
///   // RPC calls are usually made through the [] operator
///   // final rpc = registry[myFunc];
/// }
/// ```
///
/// See also:
/// * [RPC] for the interface used to invoke specific functions.
/// * [FunctionEntry] for describing individual function signatures.
class RPCRegistry implements FunctionRegistry {
  /// The list of functions supported by this registry.
  ///
  /// This collection defines the entire RPC API surface for the registry, 
  /// including both local implementations and remote handles.
  final List<FunctionEntry> functions;

  /// The callback used to send raw bytes when a call is initiated or responded to.
  ///
  /// This allows the registry to remain transport-agnostic, deferring 
  /// the actual transmission of data to an external communication layer.
  final RPCBytesCallback writer;

  final Map<int, RPCRequest> _functionCallCompleters = {};

  int _requestCounter = 0;

  /// Creates a new RPC registry with the specified functions and writer.
  ///
  /// * [functions]: The API definition for this registry.
  /// * [writer]: The transport layer callback.
  RPCRegistry({required this.functions, required this.writer});

  int get _nextRequestId {
    // limit to uint15 (max 32767)
    _requestCounter++;
    if (_requestCounter > 32767) {
      _requestCounter = 0;
    }
    return _requestCounter;
  }

  /// Processes raw binary data and dispatches it to the appropriate handler.
  ///
  /// This method distinguishes between new requests and responses to 
  /// previous calls based on the packet header. It returns the number 
  /// of bytes consumed from the data buffer.
  ///
  /// * [data]: The incoming binary data.
  /// * [offset]: The starting position within the data buffer.
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

  /// Helper method to process a list of bytes as RPC data.
  ///
  /// * [bytes]: The raw byte sequence to read.
  void handleReadBytes(List<int> bytes) {
    final buffer = ByteData.sublistView(Uint8List.fromList(bytes));
    handleReadData(buffer);
  }

  /// Helper method to process a [Uint8List] as RPC data.
  ///
  /// * [list]: The raw binary list to read.
  void handleReadUint8List(Uint8List list) {
    handleReadData(ByteData.sublistView(list));
  }

  /// Retrieves an [RPC] handle for the specified function.
  ///
  /// Throws an exception if the function is not found in the [functions] list.
  ///
  /// * [function]: The local function reference to look up.
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
