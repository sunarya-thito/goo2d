import 'dart:typed_data';

import 'package:goo2d/src/component.dart';
import 'package:goo2d/src/ticker.dart';
import 'package:goo2d/src/rpc/parser.dart';
import 'package:goo2d/src/rpc/registry.dart';

/// A component that manages Remote Procedure Calls (RPC) over a network interface.
///
/// [NetworkManager] provides a high-level API for registering local functions 
/// that can be called remotely and for invoking functions on a remote peer. 
/// it handles data serialization, request/response matching, and polling 
/// the underlying [NetworkInterface] for incoming packets.
///
/// ```dart
/// class MyGame extends StatefulGameWidget {
///   const MyGame({super.key});
///
///   @override
///   GameState createState() => MyGameState();
/// }
///
/// class MyGameState extends GameState<MyGame> {
///   void sayHello(String name) => print('Hello, $name!');
///
///   @override
///   void initState() {
///     super.initState();
///     
///     // Register and add the network manager directly
///     addComponent(NetworkManager()
///       ..functions = [
///         sayHello.describe([TypeParser.string()])
///       ]);
///   }
///
///   @override
///   Iterable<Widget> build(BuildContext context) sync* {}
/// }
/// ```
///
/// See also:
/// * [NetworkInterface] for the contract used to send/receive raw bytes.
/// * [FunctionEntry] for describing function signatures for RPC.
class NetworkManager extends Component with Tickable {
  /// The network communication layer used to transmit RPC data.
  ///
  /// This interface must be provided before calling any remote functions 
  /// or receiving incoming requests. It typically wraps a socket or 
  /// a message passing system.
  NetworkInterface? networkInterface;

  RPCRegistry? _registry;

  /// Sets the list of functions available for remote invocation.
  ///
  /// This automatically initializes the internal [RPCRegistry] with 
  /// the provided function entries and a writer callback that 
  /// directs serialized data to the [networkInterface].
  ///
  /// * [functions]: A list of [FunctionEntry] objects describing the API.
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

  /// Retrieves the list of functions currently registered in the manager.
  ///
  /// Returns an unmodifiable list of [FunctionEntry] objects. If no 
  /// functions have been registered, an empty list is returned.
  List<FunctionEntry> get functions =>
      List.unmodifiable(_registry?.functions ?? const []);

  /// Invokes a function on the remote peer and waits for its result.
  ///
  /// The provided [function] must have been registered in the [functions] 
  /// list to determine its signature and return type for serialization.
  ///
  /// * [function]: The local function reference used as an identifier.
  /// * [args]: The arguments to pass to the remote function.
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

/// An abstract interface for sending and receiving raw binary data over a network.
///
/// Implementations of this interface handle the low-level details of 
/// connection management, packet framing, and reliable delivery if required. 
/// [NetworkManager] uses this to exchange RPC requests and responses.
///
/// ```dart
/// class MySocketInterface implements NetworkInterface {
///   @override
///   void sendData(Uint8List packet) {
///     // Implementation for sending data
///   }
///   
///   @override
///   Uint8List? pollData() {
///     // Implementation for polling data
///     return null;
///   }
/// }
/// ```
///
/// See also:
/// * [NetworkManager] for the primary user of this interface.
abstract class NetworkInterface {
  /// Sends a packet of binary data to the remote peer.
  ///
  /// * [packet]: The raw bytes to be transmitted.
  void sendData(Uint8List packet);

  /// Polls the interface for the next available incoming packet.
  ///
  /// Returns a [Uint8List] containing the packet data, or null if 
  /// no new data is currently available in the receive buffer.
  Uint8List? pollData();
}
