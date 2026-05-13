import 'package:meta/meta.dart';
import 'package:goo2d/src/physics/worker/physics_worker.dart';
import 'package:goo2d/src/physics/worker/direct/direct_effector_ops.dart';
import 'package:goo2d/src/physics/worker/data/effector_type.dart';
import 'package:goo2d/goo2d.dart';

/// A base class for all 2D effectors.
///
/// Equivalent to Unity's `Effector2D`.
abstract class Effector extends Component {
  late int _handle;

  int get handle {
    assert(isAttached, 'Effector must be attached to a GameObject before accessing handle.');
    return _handle;
  }

  EffectorType get effectorType;

  @protected
  PhysicsWorker get worker => game.getSystem<PhysicsSystem>()!.worker;

  @override
  void internalAttach(GameObject gameObject) {
    super.internalAttach(gameObject);
    _handle = worker.createEffector(effectorType.index);
    syncAllProperties();
  }

  @override
  void internalDetach() {
    worker.destroyEffector(_handle);
    super.internalDetach();
  }

  @protected
  void syncAllProperties() {
    worker.setEffectorProperty(_handle, EffectorProp.useColliderMask, _useColliderMask);
    worker.setEffectorProperty(_handle, EffectorProp.colliderMask, _colliderMask);
  }

  bool _useColliderMask = false;
  bool get useColliderMask => _useColliderMask;
  set useColliderMask(bool value) {
    _useColliderMask = value;
    if (isAttached) worker.setEffectorProperty(_handle, EffectorProp.useColliderMask, value);
  }

  int _colliderMask = ~0;
  int get colliderMask => _colliderMask;
  set colliderMask(int value) {
    _colliderMask = value;
    if (isAttached) worker.setEffectorProperty(_handle, EffectorProp.colliderMask, value);
  }
}
