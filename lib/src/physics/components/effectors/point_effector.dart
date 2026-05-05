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
  void syncProperties() {
    super.syncProperties();
    handle.then((h) {
      worker.setEffectorProperty(h, EffectorProp.pointForceMagnitude, _forceMagnitude);
      worker.setEffectorProperty(h, EffectorProp.pointForceVariation, _forceVariation);
      worker.setEffectorProperty(h, EffectorProp.distanceScale, _distanceScale);
      worker.setEffectorProperty(h, EffectorProp.pointForceSource, _forceSource.index);
      worker.setEffectorProperty(h, EffectorProp.pointForceTarget, _forceTarget.index);
      worker.setEffectorProperty(h, EffectorProp.pointForceMode, _forceMode.index);
      worker.setEffectorProperty(h, EffectorProp.pointAngularDrag, _angularDamping);
      worker.setEffectorProperty(h, EffectorProp.pointDrag, _linearDamping);
    });
  }

  double _forceMagnitude = 10.0;
  /// The magnitude of the force to be applied.
  double get forceMagnitude => _forceMagnitude;
  set forceMagnitude(double value) {
    _forceMagnitude = value;
    handle.then((h) => worker.setEffectorProperty(h, EffectorProp.pointForceMagnitude, value));
  }

  double _forceVariation = 0.0;
  /// The variation in force magnitude.
  double get forceVariation => _forceVariation;
  set forceVariation(double value) {
    _forceVariation = value;
    handle.then((h) => worker.setEffectorProperty(h, EffectorProp.pointForceVariation, value));
  }

  double _distanceScale = 1.0;
  /// Scale applied to the distance when calculating force.
  double get distanceScale => _distanceScale;
  set distanceScale(double value) {
    _distanceScale = value;
    handle.then((h) => worker.setEffectorProperty(h, EffectorProp.distanceScale, value));
  }

  EffectorSelection _forceSource = EffectorSelection.collider;
  /// Source of the force.
  EffectorSelection get forceSource => _forceSource;
  set forceSource(EffectorSelection value) {
    _forceSource = value;
    handle.then((h) => worker.setEffectorProperty(h, EffectorProp.pointForceSource, value.index));
  }

  EffectorSelection _forceTarget = EffectorSelection.collider;
  /// Target of the force.
  EffectorSelection get forceTarget => _forceTarget;
  set forceTarget(EffectorSelection value) {
    _forceTarget = value;
    handle.then((h) => worker.setEffectorProperty(h, EffectorProp.pointForceTarget, value.index));
  }

  EffectorForceMode _forceMode = EffectorForceMode.constant;
  /// How the force is applied over distance.
  EffectorForceMode get forceMode => _forceMode;
  set forceMode(EffectorForceMode value) {
    _forceMode = value;
    handle.then((h) => worker.setEffectorProperty(h, EffectorProp.pointForceMode, value.index));
  }

  double _angularDamping = 0.0;
  /// Angular damping applied to affected objects.
  double get angularDamping => _angularDamping;
  set angularDamping(double value) {
    _angularDamping = value;
    handle.then((h) => worker.setEffectorProperty(h, EffectorProp.pointAngularDrag, value));
  }

  double _linearDamping = 0.0;
  /// Linear damping applied to affected objects.
  double get linearDamping => _linearDamping;
  set linearDamping(double value) {
    _linearDamping = value;
    handle.then((h) => worker.setEffectorProperty(h, EffectorProp.pointDrag, value));
  }
}
