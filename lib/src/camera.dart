import 'dart:ui';
import 'package:flutter/material.dart' show Colors;
import 'package:goo2d/goo2d.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

enum CameraClearFlags { skybox, solidColor, depth, nothing }

class Camera extends Behavior with LifecycleListener {
  /// Camera's half-size (half of the vertical viewing volume).
  double orthographicSize = 10.0;

  /// The color with which the screen will be cleared.
  Color backgroundColor = Colors.transparent;

  /// How the camera clears the background.
  CameraClearFlags clearFlags = CameraClearFlags.solidColor;

  /// This is used to render parts of the scene selectively.
  int cullingMask = -1;

  /// Near clipping plane distance.
  double nearClipPlane = -100.0;

  /// Far clipping plane distance.
  double farClipPlane = 100.0;

  double _depth = 0.0;

  /// Camera's rendering priority. Higher values are rendered later.
  /// The camera with the highest depth is treated as the MainCamera.
  double get depth => _depth;
  set depth(double value) {
    if (_depth == value) return;
    _depth = value;
    if (isAttached) {
      game.cameras.notifyDepthChanged();
    }
  }

  @override
  void onMounted() {
    game.cameras.registerCamera(this);
  }

  @override
  void onUnmounted() {
    game.cameras.unregisterCamera(this);
  }

  /// Matrix that transforms from world to camera space.
  Matrix4 get worldToCameraMatrix {
    final transform =
        gameObject.tryGetComponent<ObjectTransform>() ?? ObjectTransform();
    return Matrix4.inverted(transform.worldMatrix);
  }

  /// Matrix that transforms from camera to world space.
  Matrix4 get cameraToWorldMatrix {
    final transform =
        gameObject.tryGetComponent<ObjectTransform>() ?? ObjectTransform();
    return transform.worldMatrix.clone();
  }

  /// The projection matrix (strictly orthographic).
  Matrix4 projectionMatrix(Size screenSize) {
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
    return r;
  }

  /// Converts a world space point to screen space point.
  Offset worldToScreenPoint(Offset worldPoint, Size screenSize) {
    final viewMatrix = worldToCameraMatrix;
    final projMatrix = projectionMatrix(screenSize);

    final viewportMatrix = Matrix4.identity()
      ..translateByDouble(screenSize.width / 2, screenSize.height / 2, 0.0, 1.0)
      ..scaleByDouble(screenSize.width / 2, -screenSize.height / 2, 1.0, 1.0);

    final fullMatrix = viewportMatrix * projMatrix * viewMatrix;
    final worldVec = Vector4(worldPoint.dx, worldPoint.dy, 0.0, 1.0);
    final screenVec = fullMatrix.transform(worldVec);

    return Offset(screenVec.x / screenVec.w, screenVec.y / screenVec.w);
  }

  /// Converts a screen space point to world space point.
  Offset screenToWorldPoint(Offset screenPoint, Size screenSize) {
    final viewMatrix = worldToCameraMatrix;
    final projMatrix = projectionMatrix(screenSize);

    final viewportMatrix = Matrix4.identity()
      ..translateByDouble(screenSize.width / 2, screenSize.height / 2, 0.0, 1.0)
      ..scaleByDouble(screenSize.width / 2, -screenSize.height / 2, 1.0, 1.0);

    final fullMatrix = viewportMatrix * projMatrix * viewMatrix;
    final invMatrix = Matrix4.inverted(fullMatrix);

    final screenVec = Vector4(screenPoint.dx, screenPoint.dy, 0.0, 1.0);
    final worldVec = invMatrix.transform(screenVec);

    return Offset(worldVec.x / worldVec.w, worldVec.y / worldVec.w);
  }
}
