import 'dart:typed_data';

import 'package:goo2d/goo2d.dart';
import 'package:goo2d/src/rpc/parser.dart';
import 'package:goo2d/src/rpc/registry.dart';

/// A component that manages Remote Procedure Calls (RPC) over a network.
/// 
/// [NetworkManager] provides a high-level API for calling functions on remote 
/// clients and receiving calls from them. It coordinates between a 
/// [NetworkInterface] (transport layer) and an [RPCRegistry] (serialization layer).
/// 
/// To use RPC, you must provide a list of [FunctionEntry]s via the [functions] 
/// setter. These entries define the signatures of the functions that can be 
/// called remotely.
/// 
/// ```dart
/// final net = gameObject.addComponent(NetworkManager())
///   ..networkInterface = mySteamBridge
///   ..functions = [
///     doSomething.describe([TypeParser.string]),
///   ];
/// 
/// // Call a function on the remote client
/// await net.callRemoteFunction(doSomething, ['Hello World']);
/// ```
class NetworkManager extends Component with Tickable {
  /// The underlying transport layer used to send and receive binary packets.
  /// 
  /// Must be initialized before making any RPC calls.
  NetworkInterface? networkInterface;
  
  RPCRegistry? _registry;

  /// Defines the set of functions available for remote execution.
  /// 
  /// Setting this property initializes the internal [RPCRegistry]. Each entry 
  /// in the list must specify the function reference and its parameter types. 
  /// Links to [FunctionEntry].
  /// 
  /// * [functions]: The list of supported remote procedures.
  set functions(List<FunctionEntry> functions) {
    _registry = RPCRegistry(
      functions: functions,
      writer: (bytes) {
        assert(
          networkInterface != null,
          'You must provide a NetworkInterface before using RPC functions.',
        );
        networkInterface!.sendData(bytes.compact);
      },
    );
  }

  /// Returns the current list of registered functions.
  /// 
  /// Provides a read-only view of the active [RPCRegistry] entries.
  List<FunctionEntry> get functions =>
      List.unmodifiable(_registry?.functions ?? const []);

  /// Invokes a [function] on the remote client with the given [args].
  /// 
  /// This method serializes the function ID and arguments into a packet and 
  /// sends it via the [networkInterface]. It returns a [Future] that completes 
  /// when a response is received from the remote side.
  /// 
  /// * [function]: The registered closure to call.
  /// * [args]: The list of arguments to serialize.
  Future<T> callRemoteFunction<T>(Function function, List<Object> args) {
    assert(
      _registry != null,
      'You must provide a list of functions before using RPC functions.',
    );
    return _registry![function].call<T>(args);
  }

  @override
  void onUpdate(double dt) {
    final netInf = networkInterface;
    if (netInf == null) return;
    final data = netInf.pollData();
    if (data != null) {
      assert(
        _registry != null,
        'You must provide a list of functions before using RPC functions.',
      );
      _registry!.handleReadUint8List(data);
    }
  }
}

/// An abstract interface for the network transport layer.
/// 
/// Implementations of [NetworkInterface] handle the raw binary communication 
/// between clients (e.g., via WebSockets or Steamworks). Links to [NetworkManager].
/// 
/// ```dart
/// class MyNetwork extends NetworkInterface {
///   @override
///   void sendData(Uint8List packet) => socket.send(packet);
///   
///   @override
///   Uint8List? pollData() => socket.receive();
/// }
/// ```
abstract class NetworkInterface {
  /// Sends a binary [packet] to the remote peer.
  /// 
  /// Transmits the raw byte array over the active connection.
  /// 
  /// * [packet]: The data to transmit.
  void sendData(Uint8List packet);
  
  /// Polls for the next available packet from the network buffer.
  /// 
  /// Checks for incoming data and returns it as a [Uint8List]. Returns `null` 
  /// if no data is available.
  Uint8List? pollData();
}
