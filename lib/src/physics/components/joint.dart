import 'package:vector_math/vector_math_64.dart';
import 'package:meta/meta.dart';
import 'package:goo2d/src/physics/worker/physics_worker.dart';
import 'package:goo2d/src/physics/worker/direct/direct_joint_ops.dart';
import 'package:goo2d/goo2d.dart';

/// Parent class for joints to connect Rigidbody2D objects.
///
/// Equivalent to Unity's `Joint2D`.
abstract class Joint extends Component {
  late int _handle;

  /// The internal physics handle for this joint.
  int get handle {
    assert(isAttached, 'Joint must be attached to a GameObject before accessing handle.');
    return _handle;
  }

  /// The joint type ID of this component.
  int get jointType;

  @protected
  PhysicsWorker get worker => game.getSystem<PhysicsSystem>()!.worker;

  @override
  void internalAttach(GameObject gameObject) {
    super.internalAttach(gameObject);
    final rb = gameObject.getComponent<Rigidbody>();
    _handle = worker.createJoint(jointType, rb.handle);
    syncAllProperties();
  }

  @override
  void internalDetach() {
    worker.destroyJoint(_handle);
    super.internalDetach();
  }

  @protected
  void syncAllProperties() {
    worker.setJointProperty(_handle, JointProp.enableCollision, _enableCollision);
    worker.setJointProperty(_handle, JointProp.breakForce, _breakForce);
    worker.setJointProperty(_handle, JointProp.breakTorque, _breakTorque);
    worker.setJointProperty(_handle, JointProp.breakAction, _breakAction);
    final cb = _connectedBody;
    if (cb != null) {
      worker.setJointProperty(_handle, JointProp.bodyHandleB, cb.handle);
    }
  }

  // --- Configuration Properties ---

  bool _enableCollision = false;
  bool get enableCollision => _enableCollision;
  set enableCollision(bool value) {
    _enableCollision = value;
    if (isAttached) worker.setJointProperty(_handle, JointProp.enableCollision, value);
  }

  double _breakForce = double.infinity;
  double get breakForce => _breakForce;
  set breakForce(double value) {
    _breakForce = value;
    if (isAttached) worker.setJointProperty(_handle, JointProp.breakForce, value);
  }

  double _breakTorque = double.infinity;
  double get breakTorque => _breakTorque;
  set breakTorque(double value) {
    _breakTorque = value;
    if (isAttached) worker.setJointProperty(_handle, JointProp.breakTorque, value);
  }

  int _breakAction = 0;
  int get breakAction => _breakAction;
  set breakAction(int value) {
    _breakAction = value;
    if (isAttached) worker.setJointProperty(_handle, JointProp.breakAction, value);
  }

  Rigidbody? _connectedBody;
  Rigidbody? get connectedBody => _connectedBody;
  set connectedBody(Rigidbody? value) {
    _connectedBody = value;
    if (isAttached) {
      worker.setJointProperty(_handle, JointProp.bodyHandleB, value?.handle ?? -1);
    }
  }

  // --- Read-Only / Computed Properties ---

  Future<double> get reactionTorque async => (await worker.getJointProperty(_handle, JointProp.reactionTorque)) as double;
  Future<Vector2> get reactionForce async => (await worker.getJointProperty(_handle, JointProp.reactionForce)) as Vector2;

  Rigidbody get attachedRigidbody => gameObject.getComponent<Rigidbody>();

  // --- Methods ---

  Future<double> getReactionTorque(double timeStep) async {
    final raw = (await worker.getJointProperty(_handle, JointProp.reactionTorque)) as double;
    return timeStep > 0 ? raw / timeStep : 0.0;
  }

  Future<Vector2> getReactionForce(double timeStep) async {
    final raw = (await worker.getJointProperty(_handle, JointProp.reactionForce)) as Vector2;
    return timeStep > 0 ? raw / timeStep : Vector2.zero();
  }
}
