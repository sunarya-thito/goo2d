import 'dart:typed_data';

import 'package:goo2d/goo2d.dart';
import 'package:goo2d/src/rpc/parser.dart';
import 'package:goo2d/src/rpc/registry.dart';

class NetworkManager extends Component with Tickable {
  NetworkInterface? networkInterface;
  RPCRegistry? _registry;

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

  List<FunctionEntry> get functions =>
      List.unmodifiable(_registry?.functions ?? const []);

  Future<T> call<T>(Function function, List<Object> args) {
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

abstract class NetworkInterface {
  void sendData(Uint8List packet);
  Uint8List? pollData();
}
