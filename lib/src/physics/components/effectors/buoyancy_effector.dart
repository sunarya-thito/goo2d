import 'package:meta/meta.dart';
import 'package:goo2d/src/physics/worker/direct/direct_effector_ops.dart';
import 'package:goo2d/src/physics/worker/data/effector_type.dart';
import 'package:goo2d/goo2d.dart';

/// Applies forces that simulate buoyancy (floating).
///
/// Equivalent to Unity's `BuoyancyEffector2D`.
class BuoyancyEffector extends Effector {
  @override
  EffectorType get effectorType => EffectorType.buoyancy;

  @override
  @protected
  void syncProperties() {
    super.syncProperties();
    handle.then((h) {
      worker.setEffectorProperty(h, EffectorProp.buoyancyDensity, _density);
      worker.setEffectorProperty(h, EffectorProp.surfaceLevel, _surfaceLevel);
      worker.setEffectorProperty(h, EffectorProp.linearDrag, _linearDamping);
      worker.setEffectorProperty(h, EffectorProp.angularDragBuoyancy, _angularDamping);
      worker.setEffectorProperty(h, EffectorProp.flowAngle, _flowAngle);
      worker.setEffectorProperty(h, EffectorProp.flowMagnitude, _flowMagnitude);
      worker.setEffectorProperty(h, EffectorProp.flowVariation, _flowVariation);
    });
  }

  double _density = 1.0;
  /// The density of the fluid.
  double get density => _density;
  set density(double value) {
    _density = value;
    handle.then((h) => worker.setEffectorProperty(h, EffectorProp.buoyancyDensity, value));
  }

  double _surfaceLevel = 0.0;
  /// The height of the fluid surface.
  double get surfaceLevel => _surfaceLevel;
  set surfaceLevel(double value) {
    _surfaceLevel = value;
    handle.then((h) => worker.setEffectorProperty(h, EffectorProp.surfaceLevel, value));
  }

  double _linearDamping = 1.0;
  /// Linear damping applied to objects in the fluid.
  double get linearDamping => _linearDamping;
  set linearDamping(double value) {
    _linearDamping = value;
    handle.then((h) => worker.setEffectorProperty(h, EffectorProp.linearDrag, value));
  }

  double _angularDamping = 1.0;
  /// Angular damping applied to objects in the fluid.
  double get angularDamping => _angularDamping;
  set angularDamping(double value) {
    _angularDamping = value;
    handle.then((h) => worker.setEffectorProperty(h, EffectorProp.angularDragBuoyancy, value));
  }

  double _flowAngle = 0.0;
  /// The angle of fluid flow.
  double get flowAngle => _flowAngle;
  set flowAngle(double value) {
    _flowAngle = value;
    handle.then((h) => worker.setEffectorProperty(h, EffectorProp.flowAngle, value));
  }

  double _flowMagnitude = 0.0;
  /// The magnitude of fluid flow.
  double get flowMagnitude => _flowMagnitude;
  set flowMagnitude(double value) {
    _flowMagnitude = value;
    handle.then((h) => worker.setEffectorProperty(h, EffectorProp.flowMagnitude, value));
  }

  double _flowVariation = 0.0;
  /// The variation in fluid flow magnitude.
  double get flowVariation => _flowVariation;
  set flowVariation(double value) {
    _flowVariation = value;
    handle.then((h) => worker.setEffectorProperty(h, EffectorProp.flowVariation, value));
  }
}
