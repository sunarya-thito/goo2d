import 'dart:ui';
import 'package:flutter/material.dart' show Colors;
import 'package:meta/meta.dart';
import 'package:goo2d/goo2d.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

/// Defines how the camera clears the background before rendering a new frame.
/// 
/// The clearing phase ensures that previous frame data is removed from 
/// the render buffer. Depending on the game type, you might want to 
/// show a solid background, a skybox, or perform no clearing for 
/// trailing effects.
enum CameraClearFlags { 
  /// Renders a skybox background (not yet implemented in basic renderer).
  skybox, 
  
  /// Clears the buffer with the specified [Camera.backgroundColor].
  solidColor, 
  
  /// Only clears the depth buffer, preserving the previous frame's color.
  depth, 
  
  /// Performs no clearing, leading to "hall of mirrors" effects if 
  /// the entire screen is not covered by opaque sprites.
  nothing 
}

/// A component that defines the view and projection for rendering.
/// 
/// The [Camera] determines which part of the world is visible on 
/// screen. It uses an orthographic projection, which is standard for 
/// 2D games, where objects maintain their size regardless of their 
/// distance from the camera.
/// 
/// Every camera requires an [ObjectTransform] component on the same 
/// [GameObject] to define its position and rotation in world space. 
/// The view matrix is derived from the inverse of this transform.
/// 
/// ```dart
/// final mainCam = GameObject(name: 'MainCamera')
///   ..addComponent(Camera())
///   ..transform.position = Offset(0, 0);
/// ```
class Camera extends Behavior with LifecycleListener {
  /// Half of the vertical viewing volume height.
  /// 
  /// In an orthographic camera, this value defines how many world 
  /// units are visible from the center to the top edge of the screen. 
  /// For example, a size of 10.0 means the vertical range is 20 units.
  double orthographicSize = 10.0;

  /// The [Color] used to fill the background when [clearFlags] is set to [CameraClearFlags.solidColor].
  /// 
  /// Defaults to [Colors.transparent].
  Color backgroundColor = Colors.transparent;

  /// Determines the background clearing behavior for this camera.
  /// 
  /// See [CameraClearFlags] for detailed options.
  CameraClearFlags clearFlags = CameraClearFlags.solidColor;

  /// A bitmask used to selectively render layers of the scene.
  /// 
  /// Only [GameObject]s whose layers match this mask will be rendered 
  /// by this camera. A value of -1 renders all layers.
  int cullingMask = -1;

  /// The distance to the near clipping plane.
  /// 
  /// Objects closer to the camera than this distance will be culled. 
  /// In 2D, this is typically a negative value to allow objects at 
  /// Z=0 to be visible even if the camera is at Z=0.
  double nearClipPlane = -100.0;

  /// The distance to the far clipping plane.
  /// 
  /// Objects further from the camera than this distance will be culled.
  double farClipPlane = 100.0;

  double _depth = 0.0;
  
  Matrix4? _cachedProjectionMatrix;
  Size? _cachedProjectionSize;
  double? _cachedOrthographicSize;

  Matrix4? _cachedFullMatrix;
  Matrix4? _cachedFullMatrixInverse;
  Size? _cachedFullMatrixSize;
  int? _cachedFullMatrixTransformVersion;

  /// The rendering priority of this camera.
  /// 
  /// Cameras are rendered in ascending order of depth. The camera 
  /// with the highest depth value is considered the "Main Camera" by 
  /// the [CameraSystem].
  double get depth => _depth;
  
  /// Sets the rendering priority of this camera.
  /// 
  /// Updating this value triggers a re-sort of the camera list in the 
  /// [CameraSystem] to ensure correct draw order and main camera selection.
  /// 
  /// * [value]: The new depth value to assign.
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

  /// The matrix that transforms coordinates from World Space to Camera Space.
  /// 
  /// This is effectively the inverse of the camera's [ObjectTransform.worldMatrix]. 
  /// If no transform is found, returns an identity matrix.
  Matrix4 get worldToCameraMatrix {
    final transform = gameObject.tryGetComponent<ObjectTransform>();
    if (transform == null) return Matrix4.identity();
    return transform.worldInverse;
  }

  /// The matrix that transforms coordinates from Camera Space to World Space.
  /// 
  /// This is the camera's [ObjectTransform.worldMatrix]. It can be used 
  /// to determine where the camera is looking in the world.
  Matrix4 get cameraToWorldMatrix {
    final transform = gameObject.tryGetComponent<ObjectTransform>();
    if (transform == null) return Matrix4.identity();
    return transform.worldMatrix;
  }

  /// Calculates the orthographic projection matrix for a given screen size.
  /// 
  /// This matrix maps the 2D world units within the [orthographicSize] 
  /// volume to the clip-space range (-1 to 1). The result is cached 
  /// until [orthographicSize] or [screenSize] changes.
  /// 
  /// * [screenSize]: The dimensions of the viewport.
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

  /// Returns the combined View-Projection-Viewport matrix.
  /// 
  /// This matrix performs the full transformation from World Space 
  /// to Screen Space (pixels). It accounts for the camera's transform, 
  /// the orthographic projection, and the final viewport scaling.
  /// 
  /// * [screenSize]: The target viewport size.
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

  /// Returns the inverse of the full World-to-Screen matrix.
  /// 
  /// This is used for "unprojecting" screen coordinates (like mouse 
  /// positions) back into the game world.
  /// 
  /// * [screenSize]: The viewport dimensions.
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

  /// Maps a world-space [Offset] to its corresponding pixel position on screen.
  /// 
  /// This calculation applies the full camera transformation and handles 
  /// homogenous coordinate division.
  /// 
  /// * [worldPoint]: The point in game world coordinates.
  /// * [screenSize]: The current size of the game viewport.
  Offset worldToScreenPoint(Offset worldPoint, Size screenSize) {
    final fullMatrix = getFullMatrix(screenSize);
    final worldVec = Vector4(worldPoint.dx, worldPoint.dy, 0.0, 1.0);
    final screenVec = fullMatrix.transform(worldVec);

    return Offset(screenVec.x / screenVec.w, screenVec.y / screenVec.w);
  }

  /// Maps a screen pixel [Offset] back into the game world coordinates.
  /// 
  /// Use this to determine where a user's touch or mouse click is 
  /// located within the scene hierarchy.
  /// 
  /// * [screenPoint]: The pixel position (typically from [PointerEvent]).
  /// * [screenSize]: The current size of the game viewport.
  Offset screenToWorldPoint(Offset screenPoint, Size screenSize) {
    final invMatrix = getFullMatrixInverse(screenSize);
    final screenVec = Vector4(screenPoint.dx, screenPoint.dy, 0.0, 1.0);
    final worldVec = invMatrix.transform(screenVec);

    return Offset(worldVec.x / worldVec.w, worldVec.y / worldVec.w);
  }
}
