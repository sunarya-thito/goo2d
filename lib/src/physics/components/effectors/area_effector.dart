import 'package:meta/meta.dart';
import 'package:goo2d/src/physics/worker/direct/direct_effector_ops.dart';
import 'package:goo2d/src/physics/worker/data/effector_type.dart';
import 'package:goo2d/goo2d.dart';

/// Applies forces within an area.
///
/// Equivalent to Unity's `AreaEffector2D`.
class AreaEffector extends Effector {
  @override
  EffectorType get effectorType => EffectorType.area;

  @override
  @protected
  void syncAllProperties() {
    super.syncAllProperties();
    worker.setEffectorProperty(handle, EffectorProp.forceMagnitude, _forceMagnitude);
    worker.setEffectorProperty(handle, EffectorProp.forceVariation, _forceVariation);
    worker.setEffectorProperty(handle, EffectorProp.forceTarget, _forceTarget.index);
    worker.setEffectorProperty(handle, EffectorProp.useGlobalAngle, _useGlobalAngle);
    worker.setEffectorProperty(handle, EffectorProp.angularDrag, _angularDamping);
    worker.setEffectorProperty(handle, EffectorProp.drag, _linearDamping);
    worker.setEffectorProperty(handle, EffectorProp.forceAngle, _forceAngle);
  }

  double _forceMagnitude = 10.0;
  double get forceMagnitude => _forceMagnitude;
  set forceMagnitude(double value) {
    _forceMagnitude = value;
    if (isAttached) worker.setEffectorProperty(handle, EffectorProp.forceMagnitude, value);
  }

  double _forceVariation = 0.0;
  double get forceVariation => _forceVariation;
  set forceVariation(double value) {
    _forceVariation = value;
    if (isAttached) worker.setEffectorProperty(handle, EffectorProp.forceVariation, value);
  }

  EffectorSelection _forceTarget = EffectorSelection.collider;
  EffectorSelection get forceTarget => _forceTarget;
  set forceTarget(EffectorSelection value) {
    _forceTarget = value;
    if (isAttached) worker.setEffectorProperty(handle, EffectorProp.forceTarget, value.index);
  }

  bool _useGlobalAngle = true;
  bool get useGlobalAngle => _useGlobalAngle;
  set useGlobalAngle(bool value) {
    _useGlobalAngle = value;
    if (isAttached) worker.setEffectorProperty(handle, EffectorProp.useGlobalAngle, value);
  }

  double _angularDamping = 0.0;
  double get angularDamping => _angularDamping;
  set angularDamping(double value) {
    _angularDamping = value;
    if (isAttached) worker.setEffectorProperty(handle, EffectorProp.angularDrag, value);
  }

  double _linearDamping = 0.0;
  double get linearDamping => _linearDamping;
  set linearDamping(double value) {
    _linearDamping = value;
    if (isAttached) worker.setEffectorProperty(handle, EffectorProp.drag, value);
  }

  double _forceAngle = 0.0;
  double get forceAngle => _forceAngle;
  set forceAngle(double value) {
    _forceAngle = value;
    if (isAttached) worker.setEffectorProperty(handle, EffectorProp.forceAngle, value);
  }
}
