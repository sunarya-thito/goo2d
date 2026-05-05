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
  void syncProperties() {
    super.syncProperties();
    handle.then((h) {
      worker.setEffectorProperty(h, EffectorProp.forceMagnitude, _forceMagnitude);
      worker.setEffectorProperty(h, EffectorProp.forceVariation, _forceVariation);
      worker.setEffectorProperty(h, EffectorProp.forceTarget, _forceTarget.index);
      worker.setEffectorProperty(h, EffectorProp.useGlobalAngle, _useGlobalAngle);
      worker.setEffectorProperty(h, EffectorProp.angularDrag, _angularDamping);
      worker.setEffectorProperty(h, EffectorProp.drag, _linearDamping);
      worker.setEffectorProperty(h, EffectorProp.forceAngle, _forceAngle);
    });
  }

  double _forceMagnitude = 10.0;
  /// The magnitude of the force to be applied.
  double get forceMagnitude => _forceMagnitude;
  set forceMagnitude(double value) {
    _forceMagnitude = value;
    handle.then((h) => worker.setEffectorProperty(h, EffectorProp.forceMagnitude, value));
  }

  double _forceVariation = 0.0;
  /// The variation of the magnitude of the force to be applied.
  double get forceVariation => _forceVariation;
  set forceVariation(double value) {
    _forceVariation = value;
    handle.then((h) => worker.setEffectorProperty(h, EffectorProp.forceVariation, value));
  }

  EffectorSelection _forceTarget = EffectorSelection.collider;
  /// The target for where the effector applies any force.
  EffectorSelection get forceTarget => _forceTarget;
  set forceTarget(EffectorSelection value) {
    _forceTarget = value;
    handle.then((h) => worker.setEffectorProperty(h, EffectorProp.forceTarget, value.index));
  }

  bool _useGlobalAngle = true;
  /// Should the forceAngle use global space?
  bool get useGlobalAngle => _useGlobalAngle;
  set useGlobalAngle(bool value) {
    _useGlobalAngle = value;
    handle.then((h) => worker.setEffectorProperty(h, EffectorProp.useGlobalAngle, value));
  }

  double _angularDamping = 0.0;
  /// The angular damping to apply to rigid-bodies.
  double get angularDamping => _angularDamping;
  set angularDamping(double value) {
    _angularDamping = value;
    handle.then((h) => worker.setEffectorProperty(h, EffectorProp.angularDrag, value));
  }

  double _linearDamping = 0.0;
  /// The linear damping to apply to rigid-bodies.
  double get linearDamping => _linearDamping;
  set linearDamping(double value) {
    _linearDamping = value;
    handle.then((h) => worker.setEffectorProperty(h, EffectorProp.drag, value));
  }

  double _forceAngle = 0.0;
  /// The angle of the force to be applied.
  double get forceAngle => _forceAngle;
  set forceAngle(double value) {
    _forceAngle = value;
    handle.then((h) => worker.setEffectorProperty(h, EffectorProp.forceAngle, value));
  }
}
