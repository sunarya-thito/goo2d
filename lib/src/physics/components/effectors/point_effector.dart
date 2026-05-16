import 'package:meta/meta.dart';
import 'package:goo2d/src/physics/worker/direct/direct_effector_ops.dart';
import 'package:goo2d/src/physics/worker/data/effector_type.dart';
import 'package:goo2d/goo2d.dart';

/// Applies forces that attract or repel relative to a source point.
///
/// Equivalent to Unity's `PointEffector2D`.
class PointEffector extends Effector {
  @override
  EffectorType get effectorType => EffectorType.point;

  @override
  @protected
  void syncAllProperties() {
    super.syncAllProperties();
    worker.setEffectorProperty(handle, EffectorProp.pointForceMagnitude, _forceMagnitude);
    worker.setEffectorProperty(handle, EffectorProp.pointForceVariation, _forceVariation);
    worker.setEffectorProperty(handle, EffectorProp.distanceScale, _distanceScale);
    worker.setEffectorProperty(handle, EffectorProp.pointForceSource, _forceSource.index);
    worker.setEffectorProperty(handle, EffectorProp.pointForceTarget, _forceTarget.index);
    worker.setEffectorProperty(handle, EffectorProp.pointForceMode, _forceMode.index);
    worker.setEffectorProperty(handle, EffectorProp.pointAngularDrag, _angularDamping);
    worker.setEffectorProperty(handle, EffectorProp.pointDrag, _linearDamping);
  }

  double _forceMagnitude = 10.0;
  double get forceMagnitude => _forceMagnitude;
  set forceMagnitude(double value) {
    _forceMagnitude = value;
    if (isAttached) worker.setEffectorProperty(handle, EffectorProp.pointForceMagnitude, value);
  }

  double _forceVariation = 0.0;
  double get forceVariation => _forceVariation;
  set forceVariation(double value) {
    _forceVariation = value;
    if (isAttached) worker.setEffectorProperty(handle, EffectorProp.pointForceVariation, value);
  }

  double _distanceScale = 1.0;
  double get distanceScale => _distanceScale;
  set distanceScale(double value) {
    _distanceScale = value;
    if (isAttached) worker.setEffectorProperty(handle, EffectorProp.distanceScale, value);
  }

  EffectorSelection _forceSource = EffectorSelection.collider;
  EffectorSelection get forceSource => _forceSource;
  set forceSource(EffectorSelection value) {
    _forceSource = value;
    if (isAttached) worker.setEffectorProperty(handle, EffectorProp.pointForceSource, value.index);
  }

  EffectorSelection _forceTarget = EffectorSelection.collider;
  EffectorSelection get forceTarget => _forceTarget;
  set forceTarget(EffectorSelection value) {
    _forceTarget = value;
    if (isAttached) worker.setEffectorProperty(handle, EffectorProp.pointForceTarget, value.index);
  }

  EffectorForceMode _forceMode = EffectorForceMode.constant;
  EffectorForceMode get forceMode => _forceMode;
  set forceMode(EffectorForceMode value) {
    _forceMode = value;
    if (isAttached) worker.setEffectorProperty(handle, EffectorProp.pointForceMode, value.index);
  }

  double _angularDamping = 0.0;
  double get angularDamping => _angularDamping;
  set angularDamping(double value) {
    _angularDamping = value;
    if (isAttached) worker.setEffectorProperty(handle, EffectorProp.pointAngularDrag, value);
  }

  double _linearDamping = 0.0;
  double get linearDamping => _linearDamping;
  set linearDamping(double value) {
    _linearDamping = value;
    if (isAttached) worker.setEffectorProperty(handle, EffectorProp.pointDrag, value);
  }
}
