import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';
import 'package:goo2d/src/game.dart';
import 'package:goo2d/src/component.dart';
import 'package:goo2d/src/lifecycle.dart';
import 'package:vector_math/vector_math_64.dart';

/// Defines the reference frame for a transformation operation.
enum Space {
  /// Apply the operation relative to this object's own local axes.
  self,

  /// Apply the operation relative to the world coordinate axes.
  world,
}

/// A component that defines the position, rotation, and scale of a game object.
///
/// [ObjectTransform] is the foundation of the Goo2D coordinate system. Every
/// game object that exists in the world space requires a transform to
/// determine its spatial relationship with its parent and the camera. It
/// automatically handles hierarchical transformations, allowing children to
/// move relative to their parents.
///
/// ```dart
/// void example(GameObject object) {
///   final transform = object.getComponent<ObjectTransform>();
///   transform.localPosition = Vector2(100, 100);
///   transform.localAngle = ObjectTransform.degrees(45);
///   transform.localScale = Vector2(2, 2);
/// }
/// ```
///
/// See also:
/// * [ScreenTransform] for objects that exist in screen space (UI).
/// * [GameObject.getComponent] for retrieving this component from an object.
class ObjectTransform extends Component with LifecycleListener {
  Vector2 _localPosition = Vector2.zero();
  double _localAngle = 0.0;
  Vector2 _localScale = Vector2(1.0, 1.0);

  /// The position of the object relative to its parent.
  ///
  /// Changing this value automatically marks the world matrix as dirty,
  /// ensuring that all children are updated in the next rendering pass.
  Vector2 get localPosition => _localPosition;

  set localPosition(Vector2 value) {
    if (_localPosition.x == value.x && _localPosition.y == value.y) return;
    _localPosition = value;
    _markDirty();
  }

  /// The rotation of the object relative to its parent in radians.
  ///
  /// Positive values represent clockwise rotation. Use [ObjectTransform.degrees]
  /// to convert from degrees to radians.
  double get localAngle => _localAngle;

  set localAngle(double value) {
    if (_localAngle == value) return;
    _localAngle = value;
    _markDirty();
  }

  /// The scale of the object relative to its parent.
  ///
  /// A value of (1, 1) represents the original size. Negative values flip the
  /// object along that axis.
  Vector2 get localScale => _localScale;

  set localScale(Vector2 value) {
    if (_localScale.x == value.x && _localScale.y == value.y) return;
    _localScale = value;
    _markDirty();
  }

  ObjectTransform? _parentTransform;
  final List<ObjectTransform> _childTransforms = [];

  bool _isScreenSpace = false;

  /// Whether this transform exists in screen space rather than world space.
  ///
  /// Screen space transforms are typically used for UI elements that remain
  /// fixed on the display regardless of camera movement. This property is
  /// inherited from the parent transform by default.
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

  /// The current version of the transform, incremented whenever it changes.
  ///
  /// External systems can compare this value to detect modifications since
  /// their last update, avoiding redundant recomputation.
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

  // -------------------------------------------------------------------------
  // Matrices
  // -------------------------------------------------------------------------

  /// The matrix representing the local transformation (position, rotation, scale).
  ///
  /// Cached internally and only recomputed when a local property changes.
  Matrix4 get localMatrix {
    if (_cachedLocal != null) return _cachedLocal!;
    final m = Matrix4.identity();
    m.translateByDouble(_localPosition.x, _localPosition.y, 0.0, 1.0);
    if (_localAngle != 0.0) {
      m.rotateZ(_localAngle);
    }
    if (_localScale.x != 1.0 || _localScale.y != 1.0) {
      m.scaleByDouble(_localScale.x, _localScale.y, 1.0, 1.0);
    }
    _cachedLocal = m;
    return m;
  }

  /// The matrix representing the transformation in world space.
  ///
  /// This is the product of all parent transforms and the local matrix.
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

  /// Matrix that transforms points from local space to world space.
  ///
  /// Alias for [worldMatrix], matching Unity's naming convention.
  Matrix4 get localToWorldMatrix => worldMatrix;

  /// Matrix that transforms points from world space to local space.
  ///
  /// Alias for the internal world inverse, matching Unity's naming convention.
  Matrix4 get worldToLocalMatrix => worldInverse;

  // -------------------------------------------------------------------------
  // Position
  // -------------------------------------------------------------------------

  /// The absolute position of the object in world coordinates.
  ///
  /// Setting this value automatically calculates the required [localPosition]
  /// based on the parent's transformation.
  Vector2 get position {
    final t = worldMatrix.getTranslation();
    return Vector2(t.x, t.y);
  }

  set position(Vector2 value) {
    if (_parentTransform != null) {
      final inv = _parentTransform!.worldInverse;
      final local = inv.transform3(Vector3(value.x, value.y, 0));
      _localPosition = Vector2(local.x, local.y);
    } else {
      _localPosition = value;
    }
    _markDirty();
  }

  // -------------------------------------------------------------------------
  // Rotation
  // -------------------------------------------------------------------------

  /// The absolute rotation of the object in world space radians.
  ///
  /// Setting this value adjusts [localAngle] to achieve the desired global
  /// orientation.
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

  // -------------------------------------------------------------------------
  // Scale
  // -------------------------------------------------------------------------

  /// The absolute scale of the object in world space.
  ///
  /// Setting this property adjusts [localScale] relative to the parent's
  /// current absolute scale.
  Vector2 get scale {
    final wm = worldMatrix;
    final sx = wm.getColumn(0).xyz.length;
    final sy = wm.getColumn(1).xyz.length;
    return Vector2(sx, sy);
  }

  set scale(Vector2 value) {
    if (_parentTransform != null) {
      final ps = _parentTransform!.scale;
      _localScale = Vector2(value.x / ps.x, value.y / ps.y);
    } else {
      _localScale = value;
    }
    _markDirty();
  }

  /// Read-only world scale. Equivalent to [scale], matches Unity's `lossyScale`.
  Vector2 get lossyScale => scale;

  // -------------------------------------------------------------------------
  // Direction vectors
  // -------------------------------------------------------------------------

  /// The object's local X axis expressed in world space (normalized).
  Vector2 get right {
    final col = worldMatrix.getColumn(0);
    return Vector2(col.x, col.y)..normalize();
  }

  /// The object's local Y axis expressed in world space (normalized).
  Vector2 get up {
    final col = worldMatrix.getColumn(1);
    return Vector2(col.x, col.y)..normalize();
  }

  // -------------------------------------------------------------------------
  // Hierarchy
  // -------------------------------------------------------------------------

  /// The direct parent transform, or null if this is a root transform.
  ObjectTransform? get parent => _parentTransform;

  /// The topmost transform in the hierarchy (returns self when already root).
  ObjectTransform get root => _parentTransform?.root ?? this;

  /// Number of direct child transforms.
  int get childCount => _childTransforms.length;

  /// Returns the direct child transform at [index].
  ObjectTransform getChild(int index) => _childTransforms[index];

  /// Returns true if this transform is a descendant (at any depth) of [other].
  bool isChildOf(ObjectTransform other) {
    var current = _parentTransform;
    while (current != null) {
      if (current == other) return true;
      current = current._parentTransform;
    }
    return false;
  }

  // -------------------------------------------------------------------------
  // Coordinate-space conversions
  // -------------------------------------------------------------------------

  /// Transforms [point] from local space to world space.
  ///
  /// Useful for mapping object-local positions (e.g. a weapon barrel tip) to
  /// global world coordinates.
  Vector2 localToWorld(Vector2 point) {
    final world = worldMatrix.transform3(Vector3(point.x, point.y, 0));
    return Vector2(world.x, world.y);
  }

  /// Transforms [point] from world space to local space.
  ///
  /// The inverse of [localToWorld], typically used to map global input events
  /// (e.g. a click position) into an object's local frame.
  Vector2 worldToLocal(Vector2 point) {
    final local = worldInverse.transform3(Vector3(point.x, point.y, 0));
    return Vector2(local.x, local.y);
  }

  /// Transforms [point] from local to world space.
  ///
  /// Unity-compatible alias for [localToWorld].
  Vector2 transformPoint(Vector2 point) => localToWorld(point);

  /// Transforms [point] from world to local space.
  ///
  /// Unity-compatible alias for [worldToLocal].
  Vector2 inverseTransformPoint(Vector2 point) => worldToLocal(point);

  /// Transforms [direction] from local to world space (rotation only).
  ///
  /// Translation and scale are not applied. The magnitude of the input
  /// vector is preserved.
  Vector2 transformDirection(Vector2 direction) {
    final a = angle;
    final cosA = math.cos(a);
    final sinA = math.sin(a);
    return Vector2(
      direction.x * cosA - direction.y * sinA,
      direction.x * sinA + direction.y * cosA,
    );
  }

  /// Transforms [direction] from world to local space (rotation only).
  ///
  /// The inverse of [transformDirection].
  Vector2 inverseTransformDirection(Vector2 direction) {
    final a = angle;
    final cosA = math.cos(a);
    final sinA = math.sin(a);
    return Vector2(
      direction.x * cosA + direction.y * sinA,
      -direction.x * sinA + direction.y * cosA,
    );
  }

  /// Transforms [vector] from local to world space (rotation and scale, no translation).
  Vector2 transformVector(Vector2 vector) {
    final m = worldMatrix;
    final col0 = m.getColumn(0);
    final col1 = m.getColumn(1);
    return Vector2(
      col0.x * vector.x + col1.x * vector.y,
      col0.y * vector.x + col1.y * vector.y,
    );
  }

  /// Transforms [vector] from world to local space (rotation and scale, no translation).
  ///
  /// The inverse of [transformVector].
  Vector2 inverseTransformVector(Vector2 vector) {
    final m = worldInverse;
    final col0 = m.getColumn(0);
    final col1 = m.getColumn(1);
    return Vector2(
      col0.x * vector.x + col1.x * vector.y,
      col0.y * vector.x + col1.y * vector.y,
    );
  }

  // -------------------------------------------------------------------------
  // Mutation helpers
  // -------------------------------------------------------------------------

  /// Offsets the object's position by [delta].
  ///
  /// When [relativeTo] is [Space.self] (default), [delta] is interpreted along
  /// this object's own rotated axes — equivalent to Unity's
  /// `Transform.Translate(v, Space.Self)`.
  ///
  /// When [relativeTo] is [Space.world], [delta] is applied directly in world
  /// space — equivalent to Unity's `Transform.Translate(v, Space.World)`.
  void translate(Vector2 delta, {Space relativeTo = Space.self}) {
    switch (relativeTo) {
      case Space.self:
        final a = angle;
        final cosA = math.cos(a);
        final sinA = math.sin(a);
        position = position +
            Vector2(
              delta.x * cosA - delta.y * sinA,
              delta.x * sinA + delta.y * cosA,
            );
      case Space.world:
        position = position + delta;
    }
  }

  /// Adds [deltaRadians] to [localAngle].
  void rotate(double deltaRadians) {
    localAngle = _localAngle + deltaRadians;
  }

  /// Rotates this transform around [point] (world space) by [deltaAngle] radians.
  ///
  /// Both [position] and [angle] are updated so the object orbits [point] while
  /// also spinning in place, matching Unity's `Transform.RotateAround`.
  void rotateAround(Vector2 point, double deltaAngle) {
    final worldPos = position;
    final offset = worldPos - point;
    final cosA = math.cos(deltaAngle);
    final sinA = math.sin(deltaAngle);
    position = Vector2(
      point.x + offset.x * cosA - offset.y * sinA,
      point.y + offset.x * sinA + offset.y * cosA,
    );
    rotate(deltaAngle);
  }

  /// Orients this transform so its local X axis points toward [target] (world space).
  ///
  /// Sets [angle] to `atan2(dy, dx)` of the direction from [position] to [target].
  void lookAt(Vector2 target) {
    final worldPos = position;
    final dir = target - worldPos;
    angle = math.atan2(dir.y, dir.x);
  }

  /// Sets [localPosition] and [localAngle] atomically, firing [_markDirty] only once.
  void setLocalPositionAndRotation(Vector2 position, double angle) {
    if (_localPosition.x == position.x &&
        _localPosition.y == position.y &&
        _localAngle == angle) {
      return;
    }
    _localPosition = position;
    _localAngle = angle;
    _markDirty();
  }

  // -------------------------------------------------------------------------
  // Flutter layout integration (types intentionally stay as Flutter dart:ui)
  // -------------------------------------------------------------------------

  /// Returns the matrix to be used during the painting pass.
  ///
  /// In standard world space this equals [localMatrix]. [ScreenTransform]
  /// overrides this to counter-act the camera transform.
  Matrix4 getPaintMatrix(GameEngine game, Size screenSize) => localMatrix;

  /// Calculates the layout size of this component based on Flutter constraints.
  Size getSize(BoxConstraints constraints) {
    final biggest = constraints.biggest;
    if (biggest.isInfinite) return Size.zero;
    return biggest;
  }

  /// Returns the constraints that should be applied to children.
  BoxConstraints getChildConstraints(BoxConstraints constraints) =>
      constraints.loosen();

  double computeMinIntrinsicWidth(double height) => 0;
  double computeMaxIntrinsicWidth(double height) => 0;
  double computeMinIntrinsicHeight(double width) => 0;
  double computeMaxIntrinsicHeight(double width) => 0;

  // -------------------------------------------------------------------------
  // Static helpers
  // -------------------------------------------------------------------------

  /// Converts [deg] degrees to radians.
  static double degrees(double deg) => deg * math.pi / 180.0;
}

/// A specialized transform for objects that exist in screen space (UI).
///
/// [ScreenTransform] allows game objects to be anchored to the screen
/// rather than the world. It automatically compensates for camera
/// movement and rotation, ensuring that UI elements like buttons and
/// health bars remain fixed relative to the display edges.
///
/// ```dart
/// void example(GameObject uiObject) {
///   uiObject.addComponent(ScreenTransform()
///     ..constraints = BoxConstraints.tight(const Size(200, 50))
///   );
/// }
/// ```
///
/// See also:
/// * [ObjectTransform] for standard world-space objects.
class ScreenTransform extends ObjectTransform {
  /// Optional constraints that restrict the size of this transform.
  ///
  /// When provided, these constraints are enforced during layout and passed
  /// to children, allowing fixed-dimension UI elements.
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
