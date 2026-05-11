import 'dart:async';
import 'package:meta/meta.dart';
import 'package:goo2d/src/physics/worker/physics_worker.dart';
import 'package:goo2d/src/physics/worker/direct/direct_effector_ops.dart';
import 'package:goo2d/src/physics/worker/data/effector_type.dart';
import 'package:goo2d/goo2d.dart';

/// A base class for all 2D effectors.
///
/// Equivalent to Unity's `Effector2D`.
abstract class Effector extends Component {
  Future<int>? _handleFuture;

  /// The internal physics handle for this effector.
  Future<int> get handle {
    if (_handleFuture == null) {
      throw StateError('Effector must be attached to a GameObject before accessing handle.');
    }
    return _handleFuture!;
  }

  @protected
  Future<int>? get handleIfAttached => _handleFuture;

  /// The effector type of this component.
  EffectorType get effectorType;

  @protected
  PhysicsWorker get worker => game.getSystem<PhysicsSystem>()!.worker;

  @override
  void internalAttach(GameObject gameObject) {
    super.internalAttach(gameObject);
    _handleFuture = worker.createEffector(effectorType.index);
    syncProperties();
  }

  @override
  void internalDetach() {
    final w = worker;
    _handleFuture?.then((h) => w.destroyEffector(h));
    _handleFuture = null;
    super.internalDetach();
  }

  /// Synchronizes properties with the physics worker.
  @protected
  void syncProperties() {
    _handleFuture?.then((h) {
      worker.setEffectorProperty(h, EffectorProp.useColliderMask, _useColliderMask);
      worker.setEffectorProperty(h, EffectorProp.colliderMask, _colliderMask);
    });
  }

  bool _useColliderMask = false;
  /// Should the collider-mask be used or the global collision matrix?
  bool get useColliderMask => _useColliderMask;
  set useColliderMask(bool value) {
    _useColliderMask = value;
    _handleFuture?.then((h) => worker.setEffectorProperty(h, EffectorProp.useColliderMask, value));
  }

  int _colliderMask = ~0;
  /// The mask used to select specific layers allowed to interact with the effector.
  int get colliderMask => _colliderMask;
  set colliderMask(int value) {
    _colliderMask = value;
    _handleFuture?.then((h) => worker.setEffectorProperty(h, EffectorProp.colliderMask, value));
  }
}
