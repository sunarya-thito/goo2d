import 'package:meta/meta.dart';
import 'package:goo2d/src/physics/worker/direct/direct_effector_ops.dart';
import 'package:goo2d/src/physics/worker/data/effector_type.dart';
import 'package:goo2d/goo2d.dart';

/// Applies force along the surface of a collider.
///
/// Equivalent to Unity's `SurfaceEffector2D`.
class SurfaceEffector extends Effector {
  @override
  EffectorType get effectorType => EffectorType.surface;

  @override
  @protected
  void syncAllProperties() {
    super.syncAllProperties();
    worker.setEffectorProperty(handle, EffectorProp.speed, _speed);
    worker.setEffectorProperty(handle, EffectorProp.speedVariation, _speedVariation);
    worker.setEffectorProperty(handle, EffectorProp.forceScale, _forceScale);
    worker.setEffectorProperty(handle, EffectorProp.useContactForce, _useContactForce);
    worker.setEffectorProperty(handle, EffectorProp.useFriction, _useFriction);
    worker.setEffectorProperty(handle, EffectorProp.useBounce, _useBounce);
  }

  double _speed = 1.0;
  double get speed => _speed;
  set speed(double value) {
    _speed = value;
    if (isAttached) worker.setEffectorProperty(handle, EffectorProp.speed, value);
  }

  double _speedVariation = 0.0;
  double get speedVariation => _speedVariation;
  set speedVariation(double value) {
    _speedVariation = value;
    if (isAttached) worker.setEffectorProperty(handle, EffectorProp.speedVariation, value);
  }

  double _forceScale = 1.0;
  double get forceScale => _forceScale;
  set forceScale(double value) {
    _forceScale = value;
    if (isAttached) worker.setEffectorProperty(handle, EffectorProp.forceScale, value);
  }

  bool _useContactForce = true;
  bool get useContactForce => _useContactForce;
  set useContactForce(bool value) {
    _useContactForce = value;
    if (isAttached) worker.setEffectorProperty(handle, EffectorProp.useContactForce, value);
  }

  bool _useFriction = true;
  bool get useFriction => _useFriction;
  set useFriction(bool value) {
    _useFriction = value;
    if (isAttached) worker.setEffectorProperty(handle, EffectorProp.useFriction, value);
  }

  bool _useBounce = true;
  bool get useBounce => _useBounce;
  set useBounce(bool value) {
    _useBounce = value;
    if (isAttached) worker.setEffectorProperty(handle, EffectorProp.useBounce, value);
  }
}
