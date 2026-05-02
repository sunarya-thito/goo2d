import 'dart:ui';
import 'package:flutter/material.dart' show Colors;
import 'package:meta/meta.dart';
import 'package:goo2d/src/game.dart';
import 'package:goo2d/src/component.dart';
import 'package:goo2d/src/lifecycle.dart';
import 'package:goo2d/src/transform.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

enum CameraClearFlags {
  skybox,
  solidColor,
  depth,
  nothing,
}

class Camera extends Behavior with LifecycleListener {
  double orthographicSize = 10.0;
  Color backgroundColor = Colors.transparent;
  CameraClearFlags clearFlags = CameraClearFlags.solidColor;
  int cullingMask = -1;
  double nearClipPlane = -100.0;
  double farClipPlane = 100.0;

  double _depth = 0.0;

  Matrix4? _cachedProjectionMatrix;
  Size? _cachedProjectionSize;
  double? _cachedOrthographicSize;

  Matrix4? _cachedFullMatrix;
  Matrix4? _cachedFullMatrixInverse;
  Size? _cachedFullMatrixSize;
  int? _cachedFullMatrixTransformVersion;
  double get depth => _depth;
  set depth(double value) {
    if (_depth == value) return;
    _depth = value;
    if (isAttached) {
      game.getSystem<CameraSystem>()?.notifyDepthChanged();
    }
  }

  @override
  void onMounted() {
    game.getSystem<CameraSystem>()?.registerCamera(this);
  }

  @override
  void onUnmounted() {
    game.getSystem<CameraSystem>()?.unregisterCamera(this);
  }

  Matrix4 get worldToCameraMatrix {
    final transform = gameObject.tryGetComponent<ObjectTransform>();
    if (transform == null) return Matrix4.identity();
    return transform.worldInverse;
  }

  Matrix4 get cameraToWorldMatrix {
    final transform = gameObject.tryGetComponent<ObjectTransform>();
    if (transform == null) return Matrix4.identity();
    return transform.worldMatrix;
  }

  Matrix4 projectionMatrix(Size screenSize) {
    if (_cachedProjectionMatrix != null &&
        _cachedProjectionSize == screenSize &&
        _cachedOrthographicSize == orthographicSize) {
      return _cachedProjectionMatrix!;
    }

    final aspect = screenSize.width / screenSize.height;
    final halfHeight = orthographicSize;
    final halfWidth = halfHeight * aspect;
    final r = Matrix4.identity();
    setOrthographicMatrix(
      r,
      -halfWidth,
      halfWidth,
      -halfHeight,
      halfHeight,
      nearClipPlane,
      farClipPlane,
    );

    _cachedProjectionMatrix = r;
    _cachedProjectionSize = screenSize;
    _cachedOrthographicSize = orthographicSize;

    return r;
  }

  @internal
  Matrix4 getFullMatrix(Size screenSize) {
    final transform = gameObject.tryGetComponent<ObjectTransform>();
    final transformVersion = transform?.version ?? -1;

    if (_cachedFullMatrix != null &&
        _cachedFullMatrixSize == screenSize &&
        _cachedFullMatrixTransformVersion == transformVersion &&
        _cachedOrthographicSize == orthographicSize) {
      return _cachedFullMatrix!;
    }

    final viewMatrix = transform == null
        ? Matrix4.identity()
        : transform.worldInverse;
    final projMatrix = projectionMatrix(screenSize);

    final viewportMatrix = Matrix4.identity()
      ..translateByDouble(screenSize.width / 2, screenSize.height / 2, 0.0, 1.0)
      ..scaleByDouble(screenSize.width / 2, -screenSize.height / 2, 1.0, 1.0);

    _cachedFullMatrix = viewportMatrix * projMatrix * viewMatrix;
    _cachedFullMatrixInverse = null; // Clear inverse cache
    _cachedFullMatrixSize = screenSize;
    _cachedFullMatrixTransformVersion = transformVersion;

    return _cachedFullMatrix!;
  }

  @internal
  Matrix4 getFullMatrixInverse(Size screenSize) {
    if (_cachedFullMatrixInverse != null &&
        _cachedFullMatrixSize == screenSize &&
        _cachedFullMatrixTransformVersion ==
            (gameObject.tryGetComponent<ObjectTransform>()?.version ?? -1) &&
        _cachedOrthographicSize == orthographicSize) {
      return _cachedFullMatrixInverse!;
    }

    final full = getFullMatrix(screenSize);
    _cachedFullMatrixInverse = Matrix4.inverted(full);
    return _cachedFullMatrixInverse!;
  }

  Offset worldToScreenPoint(Offset worldPoint, Size screenSize) {
    final fullMatrix = getFullMatrix(screenSize);
    final worldVec = Vector4(worldPoint.dx, worldPoint.dy, 0.0, 1.0);
    final screenVec = fullMatrix.transform(worldVec);

    return Offset(screenVec.x / screenVec.w, screenVec.y / screenVec.w);
  }

  Offset screenToWorldPoint(Offset screenPoint, Size screenSize) {
    final invMatrix = getFullMatrixInverse(screenSize);
    final screenVec = Vector4(screenPoint.dx, screenPoint.dy, 0.0, 1.0);
    final worldVec = invMatrix.transform(screenVec);

    return Offset(worldVec.x / worldVec.w, worldVec.y / worldVec.w);
  }
}
