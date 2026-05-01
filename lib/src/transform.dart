import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';
import 'package:goo2d/src/game.dart';
import 'package:goo2d/src/component.dart';
import 'package:goo2d/src/object.dart';
import 'package:goo2d/src/lifecycle.dart';
import 'package:vector_math/vector_math_64.dart';

/// The foundational component for spatial positioning, rotation, and scaling in the engine.
///
/// [ObjectTransform] implements a hierarchical coordinate system similar to Unity or
/// Godot. Every [GameObject] has exactly one [ObjectTransform] (via the `transform`
/// getter) which defines its relationship to its parent and the world.
///
/// The component uses a "lazy update" pattern for performance. Matrices are only
/// recomputed when accessed, and only if a property has changed since the last
/// calculation. This is managed via the [_markDirty] system.
///
/// It also provides a [version] counter, which acts as a change tracking primitive
/// for dependent systems like Physics and Rendering.
///
/// ```dart
/// gameObject.transform.localPosition = Offset(100, 100);
/// gameObject.transform.rotate(ObjectTransform.degrees(45));
/// ```
class ObjectTransform extends Component with LifecycleListener {
  Offset _localPosition = Offset.zero;

  /// The rotation angle of the object in radians relative to its parent.
  ///
  /// Rotation is counter-clockwise. This private field stores the
  /// raw radian value used in the local matrix construction.
  double _localAngle = 0.0;

  Offset _localScale = const Offset(1, 1);

  /// The position of the object relative to its immediate parent.
  ///
  /// In the root of the scene graph, this is equivalent to world space.
  /// Changes to this property trigger a recursive cache invalidation
  /// for this transform and all of its descendants.
  Offset get localPosition => _localPosition;

  /// Sets the position of the object relative to its immediate parent.
  ///
  /// If the value changes, it marks the local and world matrices as
  /// dirty and increments the [version] counter.
  ///
  /// * [value]: The new local coordinates.
  set localPosition(Offset value) {
    if (_localPosition == value) return;
    _localPosition = value;
    _markDirty();
  }

  /// The rotation of the object (in radians) relative to its parent.
  ///
  /// Rotation is performed around the Z-axis (2D rotation). Positive values
  /// represent counter-clockwise rotation.
  double get localAngle => _localAngle;

  /// Sets the rotation of the object (in radians) relative to its parent.
  ///
  /// Triggers a cache invalidation if the rotation angle has changed.
  /// Ensure the value is in radians.
  ///
  /// * [value]: The new rotation angle in radians.
  set localAngle(double value) {
    if (_localAngle == value) return;
    _localAngle = value;
    _markDirty();
  }

  /// The scale of the object relative to its parent.
  ///
  /// A scale of (1.0, 1.0) represents the original size.
  Offset get localScale => _localScale;

  /// Sets the scale of the object relative to its parent.
  ///
  /// Invalidation occurs if the scale factors change. Scale is
  /// cumulative down the hierarchy.
  ///
  /// * [value]: The new scale factors.
  set localScale(Offset value) {
    if (_localScale == value) return;
    _localScale = value;
    _markDirty();
  }

  ObjectTransform? _parentTransform;
  final List<ObjectTransform> _childTransforms = [];

  bool _isScreenSpace = false;

  /// Indicates if this transform is part of a screen-space hierarchy.
  ///
  /// Screen-space objects are rendered at fixed pixel positions on the
  /// viewport, ignoring the main [Camera] translation.
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

  /// A change-tracking counter for high-performance dependency updates.
  ///
  /// Incremented on every transform change. Dependents like [Collider]
  /// use this to detect when their cached data is stale.
  int version = 0;

  /// Invalidates all cached matrices for this transform and its descendants.
  ///
  /// Propagates the dirty flag recursively down the tree and increments
  /// the [version] counter.
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

  /// Retrieves the matrix representing this transform relative to its parent.
  ///
  /// Combines translation, rotation, and scale into a single [Matrix4].
  /// Uses [translateByDouble] and [scaleByDouble] for efficiency.
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

  /// Retrieves the matrix representing this transform in absolute world space.
  ///
  /// Multiplies the parent's [worldMatrix] by the [localMatrix].
  Matrix4 get worldMatrix {
    if (_cachedWorld != null) return _cachedWorld!;
    if (_parentTransform != null) {
      _cachedWorld = _parentTransform!.worldMatrix * localMatrix;
    } else {
      _cachedWorld = localMatrix.clone();
    }
    return _cachedWorld!;
  }

  /// Returns the inverse of the [worldMatrix].
  ///
  /// This matrix is cached for performance and is used to transform
  /// coordinates from world space back into the local space of this object.
  @internal
  Matrix4 get worldInverse {
    if (_cachedWorldInverse != null) return _cachedWorldInverse!;
    _cachedWorldInverse = Matrix4.inverted(worldMatrix);
    return _cachedWorldInverse!;
  }

  /// The absolute position of the object in world space.
  ///
  /// Returns the translation component of the [worldMatrix].
  Offset get position {
    final t = worldMatrix.getTranslation();
    return Offset(t.x, t.y);
  }

  /// Sets the absolute position of the object in world space.
  ///
  /// Adjusts [localPosition] to match the requested world coordinates.
  ///
  /// * [value]: The new world coordinates.
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

  /// The absolute rotation of the object (in radians) in world space.
  ///
  /// Returns the sum of all ancestor rotations and the [localAngle].
  double get angle {
    if (_parentTransform != null) {
      return _parentTransform!.angle + _localAngle;
    }
    return _localAngle;
  }

  /// Sets the absolute rotation of the object (in radians) in world space.
  ///
  /// Adjusts the [localAngle] to achieve the target world orientation.
  ///
  /// * [value]: The new world rotation in radians.
  set angle(double value) {
    if (_parentTransform != null) {
      _localAngle = value - _parentTransform!.angle;
    } else {
      _localAngle = value;
    }
    _markDirty();
  }

  /// The absolute scale of the object in world space.
  ///
  /// Calculates the magnitude of the basis vectors in the [worldMatrix]
  /// to determine the visual scaling factor.
  Offset get scale {
    final wm = worldMatrix;
    final sx = wm.getColumn(0).xyz.length;
    final sy = wm.getColumn(1).xyz.length;
    return Offset(sx, sy);
  }

  /// Sets the absolute scale of the object in world space.
  ///
  /// Adjusts [localScale] to achieve the target world scaling factor.
  ///
  /// * [value]: The new world scale factors.
  set scale(Offset value) {
    if (_parentTransform != null) {
      final ps = _parentTransform!.scale;
      _localScale = Offset(value.dx / ps.dx, value.dy / ps.dy);
    } else {
      _localScale = value;
    }
    _markDirty();
  }

  /// Transforms a position from local space to world space.
  ///
  /// Applies the [worldMatrix] to the local coordinate vector.
  ///
  /// * [local]: The coordinates in local space.
  Offset localToWorld(Offset local) {
    final world = worldMatrix.transform3(Vector3(local.dx, local.dy, 0));
    return Offset(world.x, world.y);
  }

  /// Transforms a position from world space to local space.
  ///
  /// Applies the [worldInverse] to the world coordinate vector.
  ///
  /// * [world]: The coordinates in world space.
  Offset worldToLocal(Offset world) {
    final local = worldInverse.transform3(Vector3(world.dx, world.dy, 0));
    return Offset(local.x, local.y);
  }

  /// Returns the matrix to be used for rendering and hit testing.
  ///
  /// Base implementation returns [localMatrix]. Subclasses like
  /// [ScreenTransform] override this for specialized projection.
  ///
  /// * [game]: The active game engine.
  /// * [screenSize]: Viewport dimensions.
  Matrix4 getPaintMatrix(GameEngine game, Size screenSize) => localMatrix;

  /// Returns the size of this object based on the given constraints.
  ///
  /// Resolves the final dimensions using the parent [BoxConstraints].
  ///
  /// * [constraints]: Layout constraints.
  Size getSize(BoxConstraints constraints) {
    final biggest = constraints.biggest;
    if (biggest.isInfinite) return Size.zero;
    return biggest;
  }

  // ---------------------------------------------------------------------------
  // Convenience
  // ---------------------------------------------------------------------------

  /// Shifts the [localPosition] by [delta].
  ///
  /// Incrementally updates the local translation vector.
  ///
  /// * [delta]: Translation offset.
  void translate(Offset delta) {
    localPosition = _localPosition + delta;
  }

  /// Rotates the object by [deltaRadians].
  ///
  /// Incrementally updates the local rotation angle.
  ///
  /// * [deltaRadians]: Rotation offset in radians.
  void rotate(double deltaRadians) {
    localAngle = _localAngle + deltaRadians;
  }

  /// Returns the constraints that should be passed to children during layout.
  ///
  /// Loosens the parent constraints by default to allow flexible child sizing.
  ///
  /// * [constraints]: Parent constraints.
  BoxConstraints getChildConstraints(BoxConstraints constraints) =>
      constraints.loosen();

  /// Calculates the minimum intrinsic width of this transform.
  ///
  /// This is used by the Flutter layout system to determine the smallest
  /// width this component can take without failing to render its content.
  ///
  /// * [height]: The available height constraint.
  double computeMinIntrinsicWidth(double height) => 0;

  /// Calculates the maximum intrinsic width of this transform.
  ///
  /// This determines the ideal width for the component when given infinite
  /// horizontal space.
  ///
  /// * [height]: The available height constraint.
  double computeMaxIntrinsicWidth(double height) => 0;

  /// Calculates the minimum intrinsic height of this transform.
  ///
  /// This is used by the Flutter layout system to determine the smallest
  /// height this component can take without failing to render its content.
  ///
  /// * [width]: The available width constraint.
  double computeMinIntrinsicHeight(double width) => 0;

  /// Calculates the maximum intrinsic height of this transform.
  ///
  /// This determines the ideal height for the component when given infinite
  /// vertical space.
  ///
  /// * [width]: The available width constraint.
  double computeMaxIntrinsicHeight(double width) => 0;

  /// Helper utility to convert degree values to radians.
  ///
  /// Standard degree-to-radian conversion formula.
  ///
  /// * [deg]: Angle in degrees.
  static double degrees(double deg) => deg * math.pi / 180.0;
}

/// A transform component that exists in screen space instead of world space.
///
/// It automatically reverts any camera transform for itself and its children.
/// Useful for UI elements and HUDs. Links to [ObjectTransform].
///
/// ```dart
/// gameObject.addComponent(ScreenTransform());
/// ```
class ScreenTransform extends ObjectTransform {
  /// Optional constraints to enforce on the size of this object.
  ///
  /// [constraints] are applied during the layout phase to limit the
  /// effective dimensions of the component in screen space.
  BoxConstraints? constraints;

  bool _isNestedScreenTransform = false;

  @override
  void onMounted() {
    super.onMounted();
    _isNestedScreenTransform = _parentTransform?.isScreenSpace ?? false;
    _isScreenSpace = true;
  }

  @override
  Matrix4 getPaintMatrix(GameEngine game, Size screenSize) {
    // Revert camera transform in main pass, but stay world-space in secondary passes
    if (game.isSecondaryPass || !game.cameras.isReady) {
      return localMatrix;
    }

    if (_isNestedScreenTransform) {
      return localMatrix;
    }

    final invCamera = game.cameras.main.getFullMatrixInverse(screenSize);
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
