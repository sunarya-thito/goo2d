import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';
import 'package:goo2d/src/game.dart';
import 'package:goo2d/src/component.dart';
import 'package:goo2d/src/lifecycle.dart';
import 'package:vector_math/vector_math_64.dart';

class ObjectTransform extends Component with LifecycleListener {
  Offset _localPosition = Offset.zero;
  double _localAngle = 0.0;

  Offset _localScale = const Offset(1, 1);
  Offset get localPosition => _localPosition;
  set localPosition(Offset value) {
    if (_localPosition == value) return;
    _localPosition = value;
    _markDirty();
  }

  double get localAngle => _localAngle;
  set localAngle(double value) {
    if (_localAngle == value) return;
    _localAngle = value;
    _markDirty();
  }

  Offset get localScale => _localScale;
  set localScale(Offset value) {
    if (_localScale == value) return;
    _localScale = value;
    _markDirty();
  }

  ObjectTransform? _parentTransform;
  final List<ObjectTransform> _childTransforms = [];

  bool _isScreenSpace = false;
  bool get isScreenSpace => _isScreenSpace;

  @override
  void onMounted() {
    _parentTransform = gameObject.parentObject
        ?.tryGetComponentInParent<ObjectTransform>();
    _parentTransform?._childTransforms.add(this);
    _isScreenSpace = _parentTransform?.isScreenSpace ?? false;
  }

  @override
  void onUnmounted() {
    _parentTransform?._childTransforms.remove(this);
    _parentTransform = null;
  }

  Matrix4? _cachedLocal;
  Matrix4? _cachedWorld;
  Matrix4? _cachedWorldInverse;
  int version = 0;
  void _markDirty() {
    if (_cachedLocal == null && _cachedWorld == null) return; // already dirty
    _cachedLocal = null;
    _cachedWorld = null;
    _cachedWorldInverse = null;
    version++;
    for (final child in _childTransforms) {
      child._markDirty();
    }
  }

  Matrix4 get localMatrix {
    if (_cachedLocal != null) return _cachedLocal!;
    final m = Matrix4.identity();
    m.translateByDouble(_localPosition.dx, _localPosition.dy, 0.0, 1.0);
    if (_localAngle != 0.0) {
      m.rotateZ(_localAngle);
    }
    if (_localScale.dx != 1.0 || _localScale.dy != 1.0) {
      m.scaleByDouble(_localScale.dx, _localScale.dy, 1.0, 1.0);
    }
    _cachedLocal = m;
    return m;
  }

  Matrix4 get worldMatrix {
    if (_cachedWorld != null) return _cachedWorld!;
    if (_parentTransform != null) {
      _cachedWorld = _parentTransform!.worldMatrix * localMatrix;
    } else {
      _cachedWorld = localMatrix.clone();
    }
    return _cachedWorld!;
  }

  @internal
  Matrix4 get worldInverse {
    if (_cachedWorldInverse != null) return _cachedWorldInverse!;
    _cachedWorldInverse = Matrix4.inverted(worldMatrix);
    return _cachedWorldInverse!;
  }

  Offset get position {
    final t = worldMatrix.getTranslation();
    return Offset(t.x, t.y);
  }

  set position(Offset value) {
    if (_parentTransform != null) {
      final inv = _parentTransform!.worldInverse;
      final local = inv.transform3(Vector3(value.dx, value.dy, 0));
      _localPosition = Offset(local.x, local.y);
    } else {
      _localPosition = value;
    }
    _markDirty();
  }

  double get angle {
    if (_parentTransform != null) {
      return _parentTransform!.angle + _localAngle;
    }
    return _localAngle;
  }

  set angle(double value) {
    if (_parentTransform != null) {
      _localAngle = value - _parentTransform!.angle;
    } else {
      _localAngle = value;
    }
    _markDirty();
  }

  Offset get scale {
    final wm = worldMatrix;
    final sx = wm.getColumn(0).xyz.length;
    final sy = wm.getColumn(1).xyz.length;
    return Offset(sx, sy);
  }

  set scale(Offset value) {
    if (_parentTransform != null) {
      final ps = _parentTransform!.scale;
      _localScale = Offset(value.dx / ps.dx, value.dy / ps.dy);
    } else {
      _localScale = value;
    }
    _markDirty();
  }

  Offset localToWorld(Offset local) {
    final world = worldMatrix.transform3(Vector3(local.dx, local.dy, 0));
    return Offset(world.x, world.y);
  }

  Offset worldToLocal(Offset world) {
    final local = worldInverse.transform3(Vector3(world.dx, world.dy, 0));
    return Offset(local.x, local.y);
  }

  Matrix4 getPaintMatrix(GameEngine game, Size screenSize) => localMatrix;
  Size getSize(BoxConstraints constraints) {
    final biggest = constraints.biggest;
    if (biggest.isInfinite) return Size.zero;
    return biggest;
  }

  // ---------------------------------------------------------------------------
  // Convenience
  // ---------------------------------------------------------------------------
  void translate(Offset delta) {
    localPosition = _localPosition + delta;
  }

  void rotate(double deltaRadians) {
    localAngle = _localAngle + deltaRadians;
  }

  BoxConstraints getChildConstraints(BoxConstraints constraints) =>
      constraints.loosen();
  double computeMinIntrinsicWidth(double height) => 0;
  double computeMaxIntrinsicWidth(double height) => 0;
  double computeMinIntrinsicHeight(double width) => 0;
  double computeMaxIntrinsicHeight(double width) => 0;
  static double degrees(double deg) => deg * math.pi / 180.0;
}

class ScreenTransform extends ObjectTransform {
  BoxConstraints? constraints;

  @override
  bool get isScreenSpace => true;

  bool _isNestedScreenTransform = false;

  @override
  void onMounted() {
    super.onMounted();
    _isNestedScreenTransform = _parentTransform?.isScreenSpace ?? false;
  }

  @override
  Matrix4 getPaintMatrix(GameEngine game, Size screenSize) {
    final cameraSystem = game.getSystem<CameraSystem>();
    // Revert camera transform in main pass, but stay world-space in secondary passes
    if (cameraSystem == null ||
        cameraSystem.isSecondaryPass ||
        !cameraSystem.isReady) {
      return localMatrix;
    }

    if (_isNestedScreenTransform) {
      return localMatrix;
    }

    final invCamera = cameraSystem.main.getFullMatrixInverse(screenSize);
    return invCamera * localMatrix;
  }

  @override
  Size getSize(BoxConstraints constraints) {
    final effectiveConstraints =
        this.constraints?.enforce(constraints) ?? constraints;
    return effectiveConstraints.biggest;
  }

  @override
  BoxConstraints getChildConstraints(BoxConstraints constraints) {
    return this.constraints?.enforce(constraints) ?? constraints;
  }

  @override
  double computeMinIntrinsicWidth(double height) => constraints?.minWidth ?? 0;
  @override
  double computeMaxIntrinsicWidth(double height) => constraints?.maxWidth ?? 0;
  @override
  double computeMinIntrinsicHeight(double width) => constraints?.minHeight ?? 0;
  @override
  double computeMaxIntrinsicHeight(double width) => constraints?.maxHeight ?? 0;
}
