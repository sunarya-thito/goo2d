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
  void syncProperties() {
    super.syncProperties();
    handleIfAttached?.then((h) {
      worker.setEffectorProperty(h, EffectorProp.speed, _speed);
      worker.setEffectorProperty(h, EffectorProp.speedVariation, _speedVariation);
      worker.setEffectorProperty(h, EffectorProp.forceScale, _forceScale);
      worker.setEffectorProperty(h, EffectorProp.useContactForce, _useContactForce);
      worker.setEffectorProperty(h, EffectorProp.useFriction, _useFriction);
      worker.setEffectorProperty(h, EffectorProp.useBounce, _useBounce);
    });
  }

  double _speed = 1.0;
  /// Speed to maintain along the surface.
  double get speed => _speed;
  set speed(double value) {
    _speed = value;
    handleIfAttached?.then((h) => worker.setEffectorProperty(h, EffectorProp.speed, value));
  }

  double _speedVariation = 0.0;
  /// Variation in surface speed.
  double get speedVariation => _speedVariation;
  set speedVariation(double value) {
    _speedVariation = value;
    handleIfAttached?.then((h) => worker.setEffectorProperty(h, EffectorProp.speedVariation, value));
  }

  double _forceScale = 1.0;
  /// Scale applied to the force.
  double get forceScale => _forceScale;
  set forceScale(double value) {
    _forceScale = value;
    handleIfAttached?.then((h) => worker.setEffectorProperty(h, EffectorProp.forceScale, value));
  }

  bool _useContactForce = true;
  /// Should the force be applied at the contact point?
  bool get useContactForce => _useContactForce;
  set useContactForce(bool value) {
    _useContactForce = value;
    handleIfAttached?.then((h) => worker.setEffectorProperty(h, EffectorProp.useContactForce, value));
  }

  bool _useFriction = true;
  /// Should friction be used?
  bool get useFriction => _useFriction;
  set useFriction(bool value) {
    _useFriction = value;
    handleIfAttached?.then((h) => worker.setEffectorProperty(h, EffectorProp.useFriction, value));
  }

  bool _useBounce = true;
  /// Should bounciness be used?
  bool get useBounce => _useBounce;
  set useBounce(bool value) {
    _useBounce = value;
    handleIfAttached?.then((h) => worker.setEffectorProperty(h, EffectorProp.useBounce, value));
  }
}
