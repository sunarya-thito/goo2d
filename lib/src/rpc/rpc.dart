import 'dart:typed_data';

import 'package:goo2d/src/component.dart';
import 'package:goo2d/src/ticker.dart';
import 'package:goo2d/src/rpc/parser.dart';
import 'package:goo2d/src/rpc/registry.dart';

/// A manager for network communication and RPC dispatching.
///
/// [NetworkManager] is a engine component that polls a [NetworkInterface]
/// for incoming data and dispatches it to an [RPCRegistry]. It provides
/// a high-level API for making remote procedure calls while allowing
/// the transport layer to remain decoupled.
///
/// ```dart
/// void myFunc() {}
///
/// class MySocket extends NetworkInterface {
///   @override
///   void sendData(Uint8List packet) {}
///   @override
///   Uint8List? pollData() => null;
/// }
///
/// class MyState extends GameState {
///   @override
///   void initState() {
///     super.initState();
///     gameObject.addComponent(NetworkManager()
///       ..networkInterface = MySocket()
///       ..functions = [myFunc.describe([])]);
///   }
///
///   @override
///   Iterable<Widget> build(BuildContext context) => [];
/// }
/// ```
class NetworkManager extends Component with Tickable {
  /// The low-level transport interface used for data transmission.
  ///
  /// This interface is polled every frame during the [onUpdate] cycle
  /// to check for incoming RPC packets. It must be provided before
  /// any remote functions are called.
  NetworkInterface? networkInterface;

  RPCRegistry? _registry;

  /// Sets the list of RPC-capable functions for this manager.
  ///
  /// This setter initializes the internal [RPCRegistry] with the
  /// provided function metadata and a writer callback that routes
  /// data through the [networkInterface].
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

  /// The list of functions currently registered with this manager.
  ///
  /// Returns an unmodifiable list of all [FunctionEntry] objects
  /// that have been defined for remote invocation.
  List<FunctionEntry> get functions =>
      List.unmodifiable(_registry?.functions ?? const []);

  /// Initiates a remote procedure call for the specified function.
  ///
  /// This method uses the internal registry to serialize the [args]
  /// and transmit them via the network interface. It returns a future
  /// that resolves when the remote peer returns a result.
  ///
  /// * [function]: The local Dart function to invoke remotely.
  /// * [args]: The list of arguments to pass to the function.
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

/// An abstraction for network transport layers.
///
/// [NetworkInterface] defines the minimum set of operations required
/// to support RPC communication. Implementing this class allows
/// [NetworkManager] to work with any underlying protocol.
///
/// ```dart
/// class MySocket extends NetworkInterface {
///   @override
///   void sendData(Uint8List packet) {
///     // Implementation here
///   }
///   @override
///   Uint8List? pollData() {
///     // Implementation here
///     return null;
///   }
/// }
/// ```
abstract class NetworkInterface {
  /// Transmits a raw byte packet over the network.
  ///
  /// * [packet]: The serialized RPC data to send.
  void sendData(Uint8List packet);

  /// Checks for any new data received from the network.
  ///
  /// Returns a [Uint8List] if a packet is available, or null otherwise.
  Uint8List? pollData();
}
