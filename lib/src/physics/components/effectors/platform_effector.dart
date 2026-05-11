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
  void syncProperties() {
    super.syncProperties();
    handleIfAttached?.then((h) {
      worker.setEffectorProperty(h, EffectorProp.useOneWay, _useOneWay);
      worker.setEffectorProperty(h, EffectorProp.useOneWayGrouping, _useOneWayGrouping);
      worker.setEffectorProperty(h, EffectorProp.surfaceArc, _surfaceArc);
      worker.setEffectorProperty(h, EffectorProp.useSideFriction, _useSideFriction);
      worker.setEffectorProperty(h, EffectorProp.useSideBounce, _useSideBounce);
      worker.setEffectorProperty(h, EffectorProp.sideArc, _sideArc);
      worker.setEffectorProperty(h, EffectorProp.rotationalOffset, _rotationalOffset);
    });
  }

  bool _useOneWay = true;
  /// Should the effector use one-way collisions?
  bool get useOneWay => _useOneWay;
  set useOneWay(bool value) {
    _useOneWay = value;
    handleIfAttached?.then((h) => worker.setEffectorProperty(h, EffectorProp.useOneWay, value));
  }

  bool _useOneWayGrouping = false;
  /// Should the one-way behavior be grouped for all attached colliders?
  bool get useOneWayGrouping => _useOneWayGrouping;
  set useOneWayGrouping(bool value) {
    _useOneWayGrouping = value;
    handleIfAttached?.then((h) => worker.setEffectorProperty(h, EffectorProp.useOneWayGrouping, value));
  }

  double _surfaceArc = 180.0;
  /// The angle of the surface arc where collisions are allowed.
  double get surfaceArc => _surfaceArc;
  set surfaceArc(double value) {
    _surfaceArc = value;
    handleIfAttached?.then((h) => worker.setEffectorProperty(h, EffectorProp.surfaceArc, value));
  }

  bool _useSideFriction = true;
  /// Should friction be applied to the sides?
  bool get useSideFriction => _useSideFriction;
  set useSideFriction(bool value) {
    _useSideFriction = value;
    handleIfAttached?.then((h) => worker.setEffectorProperty(h, EffectorProp.useSideFriction, value));
  }

  bool _useSideBounce = true;
  /// Should bounciness be applied to the sides?
  bool get useSideBounce => _useSideBounce;
  set useSideBounce(bool value) {
    _useSideBounce = value;
    handleIfAttached?.then((h) => worker.setEffectorProperty(h, EffectorProp.useSideBounce, value));
  }

  double _sideArc = 0.0;
  /// The angle of the side arc.
  double get sideArc => _sideArc;
  set sideArc(double value) {
    _sideArc = value;
    handleIfAttached?.then((h) => worker.setEffectorProperty(h, EffectorProp.sideArc, value));
  }

  double _rotationalOffset = 0.0;
  /// The rotational offset of the effector.
  double get rotationalOffset => _rotationalOffset;
  set rotationalOffset(double value) {
    _rotationalOffset = value;
    handleIfAttached?.then((h) => worker.setEffectorProperty(h, EffectorProp.rotationalOffset, value));
  }
}
