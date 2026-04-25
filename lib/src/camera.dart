import 'dart:ui';
import 'package:flutter/material.dart' show Colors;
import 'package:goo2d/goo2d.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

enum CameraClearFlags { skybox, solidColor, depth, nothing }

class Camera extends Component with LifecycleListener {
  static Camera? _main;

  /// The first enabled camera tagged "MainCamera" (read only).
  static Camera get main {
    assert(_main != null, 'Camera is not ready');
    return _main!;
  }

  static bool get isReady => _main != null;

  static final List<Camera> _allCameras = [];

  /// Returns all enabled cameras in the scene.
  static List<Camera> get allCameras => List.unmodifiable(_allCameras);

  /// The camera that is currently rendering (read only).
  static Camera? current;

  /// Camera's half-size (half of the vertical viewing volume).
  double orthographicSize = 10.0;

  /// The color with which the screen will be cleared.
  Color backgroundColor = Colors.black;

  /// How the camera clears the background.
  CameraClearFlags clearFlags = CameraClearFlags.solidColor;

  /// This is used to render parts of the scene selectively.
  int cullingMask = -1;

  /// Camera's depth in the camera rendering order.
  double depth = 0;

  /// Where on the screen is the camera rendered (0-1).
  Rect rect = const Rect.fromLTWH(0, 0, 1, 1);

  /// Near clipping plane distance.
  double nearClipPlane = -100.0;

  /// Far clipping plane distance.
  double farClipPlane = 100.0;

  @override
  void onMounted() {
    _allCameras.add(this);
    _allCameras.sort((a, b) => a.depth.compareTo(b.depth));
    _updateMainCamera();
  }

  @override
  void onUnmounted() {
    _allCameras.remove(this);
    if (_main == this) {
      _main = null;
      _updateMainCamera();
    }
  }

  void _updateMainCamera() {
    if (_main != null && _main!.gameObject.active) return;
    for (final cam in _allCameras) {
      if (cam.gameObject.tag == 'MainCamera') {
        _main = cam;
        break;
      }
    }
  }

  /// Matrix that transforms from world to camera space.
  Matrix4 get worldToCameraMatrix {
    final transform = gameObject.getComponent<ObjectTransform>();
    return Matrix4.inverted(transform.worldMatrix);
  }

  /// Matrix that transforms from camera to world space.
  Matrix4 get cameraToWorldMatrix {
    final transform = gameObject.getComponent<ObjectTransform>();
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

  /// Transforms [position] from world space into screen space.
  Offset worldToScreenPoint(Offset worldPoint, Size screenSize) {
    final viewMatrix = worldToCameraMatrix;
    final projMatrix = projectionMatrix(screenSize);
    final vpMatrix = projMatrix * viewMatrix;

    final worldVec = Vector3(worldPoint.dx, worldPoint.dy, 0);
    final screenVec = vpMatrix.transform3(worldVec);

    // Normalize from [-1, 1] to [0, 1] then to [0, screenSize]
    // Note: Y is usually inverted in screen space vs world space in some engines,
    // but in Flutter (0,0) is top-left.
    // In Unity 2D, (0,0) is center, and Y is up.
    // Let's assume Unity-like: Y is up, (0,0) is world origin.
    // Screen (0,0) is top-left.

    final x = (screenVec.x + 1) / 2 * screenSize.width;
    final y = (1 - screenVec.y) / 2 * screenSize.height;

    return Offset(x, y);
  }

  /// Transforms [position] from screen space into world space.
  Offset screenToWorldPoint(Offset screenPoint, Size screenSize) {
    final viewMatrix = worldToCameraMatrix;
    final projMatrix = projectionMatrix(screenSize);
    final vpMatrix = projMatrix * viewMatrix;
    final invVpMatrix = Matrix4.inverted(vpMatrix);

    // Normalize from [0, screenSize] to [-1, 1]
    final nx = (screenPoint.dx / screenSize.width) * 2 - 1;
    final ny = 1 - (screenPoint.dy / screenSize.height) * 2;

    final clipVec = Vector3(nx, ny, 0);
    final worldVec = invVpMatrix.transform3(clipVec);

    return Offset(worldVec.x, worldVec.y);
  }

  /// Transforms [position] from viewport space into world space.
  Offset viewportToWorldPoint(Offset viewportPoint, Size screenSize) {
    final screenPoint = Offset(
      viewportPoint.dx * screenSize.width,
      viewportPoint.dy * screenSize.height,
    );
    return screenToWorldPoint(screenPoint, screenSize);
  }

  /// Transforms [position] from world space into viewport space.
  Offset worldToViewportPoint(Offset worldPoint, Size screenSize) {
    final screenPoint = worldToScreenPoint(worldPoint, screenSize);
    return Offset(
      screenPoint.dx / screenSize.width,
      screenPoint.dy / screenSize.height,
    );
  }
}
