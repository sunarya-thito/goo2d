import 'dart:async';
import 'package:vector_math/vector_math_64.dart';
import 'package:meta/meta.dart';
import 'package:goo2d/src/physics/worker/physics_worker.dart';
import 'package:goo2d/src/physics/worker/direct/direct_joint_ops.dart';
import 'package:goo2d/goo2d.dart';

/// Parent class for joints to connect Rigidbody2D objects.
/// 
/// Equivalent to Unity's `Joint2D`.
abstract class Joint extends Component {
  Future<int>? _handleFuture;

  /// The internal physics handle for this joint.
  Future<int> get handle {
    if (_handleFuture == null) {
      throw StateError('Joint must be attached to a GameObject before accessing handle.');
    }
    return _handleFuture!;
  }

  /// The joint type ID of this component.
  int get jointType;

  @protected
  PhysicsWorker get worker => game.getSystem<PhysicsSystem>()!.worker;

  @override
  void internalAttach(GameObject gameObject) {
    super.internalAttach(gameObject);
    final rb = gameObject.getComponent<Rigidbody>();
    if (rb == null) {
      throw StateError('Joint requires a Rigidbody component on the same GameObject.');
    }

    _handleFuture = rb.handle.then((bodyHandle) => worker.createJoint(jointType, bodyHandle));
    syncProperties();
  }

  @override
  void internalDetach() {
    _handleFuture?.then((h) => worker.destroyJoint(h));
    _handleFuture = null;
    super.internalDetach();
  }

  /// Synchronizes properties with the physics worker.
  @protected
  void syncProperties() {
    _handleFuture?.then((h) {
      worker.setJointProperty(h, JointProp.enableCollision, _enableCollision);
      worker.setJointProperty(h, JointProp.breakForce, _breakForce);
      worker.setJointProperty(h, JointProp.breakTorque, _breakTorque);
      worker.setJointProperty(h, JointProp.breakAction, _breakAction);
      if (_connectedBody != null) {
        _connectedBody!.handle.then((ch) => worker.setJointProperty(h, JointProp.bodyHandleB, ch));
      }
    });
  }

  // --- Configuration Properties (Sync) ---

  bool _enableCollision = false;
  /// Should the two Rigidbody2D connected with this joint collide with each other?
  bool get enableCollision => _enableCollision;
  set enableCollision(bool value) {
    _enableCollision = value;
    _handleFuture?.then((h) => worker.setJointProperty(h, JointProp.enableCollision, value));
  }

  double _breakForce = double.infinity;
  /// The force that needs to be applied for this joint to break.
  double get breakForce => _breakForce;
  set breakForce(double value) {
    _breakForce = value;
    _handleFuture?.then((h) => worker.setJointProperty(h, JointProp.breakForce, value));
  }

  double _breakTorque = double.infinity;
  /// The torque that needs to be applied for this joint to break.
  double get breakTorque => _breakTorque;
  set breakTorque(double value) {
    _breakTorque = value;
    _handleFuture?.then((h) => worker.setJointProperty(h, JointProp.breakTorque, value));
  }

  int _breakAction = 0;
  /// The action to take when the joint breaks the breakForce or breakTorque.
  int get breakAction => _breakAction;
  set breakAction(int value) {
    _breakAction = value;
    _handleFuture?.then((h) => worker.setJointProperty(h, JointProp.breakAction, value));
  }

  Rigidbody? _connectedBody;
  /// The Rigidbody2D object to which the other end of the joint is attached (ie, the object without the joint component).
  Rigidbody? get connectedBody => _connectedBody;
  set connectedBody(Rigidbody? value) {
    _connectedBody = value;
    if (value != null) {
      handle.then((h) => value.handle.then((ch) => worker.setJointProperty(h, JointProp.bodyHandleB, ch)));
    } else {
      handle.then((h) => worker.setJointProperty(h, JointProp.bodyHandleB, -1));
    }
  }

  // --- Read-Only / Computed Properties ---

  /// Gets the reaction torque of the joint.
  Future<double> get reactionTorque async => (await worker.getJointProperty(await handle, JointProp.reactionTorque)) as double;

  /// Gets the reaction force of the joint.
  Future<Vector2> get reactionForce async => (await worker.getJointProperty(await handle, JointProp.reactionForce)) as Vector2;

  /// The Rigidbody2D attached to the Joint2D.
  Rigidbody get attachedRigidbody => gameObject.getComponent<Rigidbody>()!;

  // --- Methods ---

  /// Gets the reaction torque of the joint given the specified timeStep.
  Future<double> getReactionTorque(double timeStep) async => (await worker.getJointProperty(await handle, JointProp.reactionTorque)) as double; // TODO: handle timeStep in worker

  /// Gets the reaction force of the joint given the specified timeStep.
  Future<Vector2> getReactionForce(double timeStep) async => (await worker.getJointProperty(await handle, JointProp.reactionForce)) as Vector2; // TODO: handle timeStep in worker
}