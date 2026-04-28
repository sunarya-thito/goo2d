import 'package:flutter/painting.dart';
import 'package:goo2d/goo2d.dart';

enum RigidbodyType {
  dynamic,
  kinematic,
  static,
}

class Rigidbody extends Component with LifecycleListener {
  RigidbodyType type = RigidbodyType.dynamic;

  double _mass = 1.0;
  double _drag = 0.0;
  double _angularDrag = 0.05;
  double _gravityScale = 1.0;
  bool _freezeRotation = false;

  double get mass => _mass;
  set mass(double value) {
    if (_mass == value) return;
    _mass = value;
    if (isAttached) game.physics.updateRigidbody(this);
  }

  double get drag => _drag;
  set drag(double value) {
    if (_drag == value) return;
    _drag = value;
    if (isAttached) game.physics.updateRigidbody(this);
  }

  double get angularDrag => _angularDrag;
  set angularDrag(double value) {
    if (_angularDrag == value) return;
    _angularDrag = value;
    if (isAttached) game.physics.updateRigidbody(this);
  }

  double get gravityScale => _gravityScale;
  set gravityScale(double value) {
    if (_gravityScale == value) return;
    _gravityScale = value;
    if (isAttached) game.physics.updateRigidbody(this);
  }

  bool get freezeRotation => _freezeRotation;
  set freezeRotation(bool value) {
    if (_freezeRotation == value) return;
    _freezeRotation = value;
    if (isAttached) game.physics.updateRigidbody(this);
  }

  Offset _velocity = Offset.zero;
  double _angularVelocity = 0.0;

  Offset get velocity => _velocity;
  set velocity(Offset value) {
    if (_velocity == value) return;
    _velocity = value;
    if (isAttached) game.physics.internalSyncVelocity(this, value);
  }

  double get angularVelocity => _angularVelocity;
  set angularVelocity(double value) {
    if (_angularVelocity == value) return;
    _angularVelocity = value;
    if (isAttached) game.physics.internalSyncAngularVelocity(this, value);
  }

  /// Internal method used by PhysicsSystem to update velocity without triggering a sync.
  void internalSetVelocity(Offset vel, double angVel) {
    _velocity = vel;
    _angularVelocity = angVel;
  }

  bool get isKinematic => type == RigidbodyType.kinematic;
  bool get isDynamic => type == RigidbodyType.dynamic;
  bool get isStatic => type == RigidbodyType.static;

  ObjectTransform get transform => gameObject.getComponent<ObjectTransform>();
  ObjectTransform? get tryTransform =>
      gameObject.tryGetComponent<ObjectTransform>();

  @override
  void onMounted() {
    game.physics.registerRigidbody(this);
  }

  @override
  void onUnmounted() {
    game.physics.unregisterRigidbody(this);
  }

  void addForce(Offset force) {
    game.physics.internalQueueForce(this, force);
  }

  void addImpulse(Offset impulse) {
    game.physics.internalQueueImpulse(this, impulse);
  }

  void addAngularImpulse(double impulse) {
    game.physics.internalQueueAngularImpulse(this, impulse);
  }
}
