import 'package:meta/meta.dart';
import 'package:goo2d/src/physics/worker/direct/direct_effector_ops.dart';
import 'package:goo2d/src/physics/worker/data/effector_type.dart';
import 'package:goo2d/goo2d.dart';

/// Applies platform-style behavior (one-way collisions).
///
/// Equivalent to Unity's `PlatformEffector2D`.
class PlatformEffector extends Effector {
  @override
  EffectorType get effectorType => EffectorType.platform;

  @override
  @protected
  void syncAllProperties() {
    super.syncAllProperties();
    worker.setEffectorProperty(handle, EffectorProp.useOneWay, _useOneWay);
    worker.setEffectorProperty(handle, EffectorProp.useOneWayGrouping, _useOneWayGrouping);
    worker.setEffectorProperty(handle, EffectorProp.surfaceArc, _surfaceArc);
    worker.setEffectorProperty(handle, EffectorProp.useSideFriction, _useSideFriction);
    worker.setEffectorProperty(handle, EffectorProp.useSideBounce, _useSideBounce);
    worker.setEffectorProperty(handle, EffectorProp.sideArc, _sideArc);
    worker.setEffectorProperty(handle, EffectorProp.rotationalOffset, _rotationalOffset);
  }

  bool _useOneWay = true;
  bool get useOneWay => _useOneWay;
  set useOneWay(bool value) {
    _useOneWay = value;
    if (isAttached) worker.setEffectorProperty(handle, EffectorProp.useOneWay, value);
  }

  bool _useOneWayGrouping = false;
  bool get useOneWayGrouping => _useOneWayGrouping;
  set useOneWayGrouping(bool value) {
    _useOneWayGrouping = value;
    if (isAttached) worker.setEffectorProperty(handle, EffectorProp.useOneWayGrouping, value);
  }

  double _surfaceArc = 180.0;
  double get surfaceArc => _surfaceArc;
  set surfaceArc(double value) {
    _surfaceArc = value;
    if (isAttached) worker.setEffectorProperty(handle, EffectorProp.surfaceArc, value);
  }

  bool _useSideFriction = true;
  bool get useSideFriction => _useSideFriction;
  set useSideFriction(bool value) {
    _useSideFriction = value;
    if (isAttached) worker.setEffectorProperty(handle, EffectorProp.useSideFriction, value);
  }

  bool _useSideBounce = true;
  bool get useSideBounce => _useSideBounce;
  set useSideBounce(bool value) {
    _useSideBounce = value;
    if (isAttached) worker.setEffectorProperty(handle, EffectorProp.useSideBounce, value);
  }

  double _sideArc = 0.0;
  double get sideArc => _sideArc;
  set sideArc(double value) {
    _sideArc = value;
    if (isAttached) worker.setEffectorProperty(handle, EffectorProp.sideArc, value);
  }

  double _rotationalOffset = 0.0;
  double get rotationalOffset => _rotationalOffset;
  set rotationalOffset(double value) {
    _rotationalOffset = value;
    if (isAttached) worker.setEffectorProperty(handle, EffectorProp.rotationalOffset, value);
  }
}
