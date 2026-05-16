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
  void syncAllProperties() {
    super.syncAllProperties();
    worker.setEffectorProperty(handle, EffectorProp.buoyancyDensity, _density);
    worker.setEffectorProperty(handle, EffectorProp.surfaceLevel, _surfaceLevel);
    worker.setEffectorProperty(handle, EffectorProp.linearDrag, _linearDamping);
    worker.setEffectorProperty(handle, EffectorProp.angularDragBuoyancy, _angularDamping);
    worker.setEffectorProperty(handle, EffectorProp.flowAngle, _flowAngle);
    worker.setEffectorProperty(handle, EffectorProp.flowMagnitude, _flowMagnitude);
    worker.setEffectorProperty(handle, EffectorProp.flowVariation, _flowVariation);
  }

  double _density = 1.0;
  double get density => _density;
  set density(double value) {
    _density = value;
    if (isAttached) worker.setEffectorProperty(handle, EffectorProp.buoyancyDensity, value);
  }

  double _surfaceLevel = 0.0;
  double get surfaceLevel => _surfaceLevel;
  set surfaceLevel(double value) {
    _surfaceLevel = value;
    if (isAttached) worker.setEffectorProperty(handle, EffectorProp.surfaceLevel, value);
  }

  double _linearDamping = 1.0;
  double get linearDamping => _linearDamping;
  set linearDamping(double value) {
    _linearDamping = value;
    if (isAttached) worker.setEffectorProperty(handle, EffectorProp.linearDrag, value);
  }

  double _angularDamping = 1.0;
  double get angularDamping => _angularDamping;
  set angularDamping(double value) {
    _angularDamping = value;
    if (isAttached) worker.setEffectorProperty(handle, EffectorProp.angularDragBuoyancy, value);
  }

  double _flowAngle = 0.0;
  double get flowAngle => _flowAngle;
  set flowAngle(double value) {
    _flowAngle = value;
    if (isAttached) worker.setEffectorProperty(handle, EffectorProp.flowAngle, value);
  }

  double _flowMagnitude = 0.0;
  double get flowMagnitude => _flowMagnitude;
  set flowMagnitude(double value) {
    _flowMagnitude = value;
    if (isAttached) worker.setEffectorProperty(handle, EffectorProp.flowMagnitude, value);
  }

  double _flowVariation = 0.0;
  double get flowVariation => _flowVariation;
  set flowVariation(double value) {
    _flowVariation = value;
    if (isAttached) worker.setEffectorProperty(handle, EffectorProp.flowVariation, value);
  }
}
