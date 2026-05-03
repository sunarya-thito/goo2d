import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';
import 'package:goo2d/src/game.dart';
import 'package:goo2d/src/component.dart';
import 'package:goo2d/src/lifecycle.dart';
import 'package:vector_math/vector_math_64.dart';

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
///   transform.localPosition = const Offset(100, 100);
///   transform.localAngle = ObjectTransform.degrees(45);
///   transform.localScale = const Offset(2, 2);
/// }
/// ```
///
/// See also:
/// * [ScreenTransform] for objects that exist in screen space (UI).
/// * [GameObject.getComponent] for retrieving this component from an object.
class ObjectTransform extends Component with LifecycleListener {
  Offset _localPosition = Offset.zero;
  double _localAngle = 0.0;
  Offset _localScale = const Offset(1, 1);

  /// The position of the object relative to its parent.
  ///
  /// This property defines the translation offset from the parent's origin. 
  /// Changing this value will automatically mark the world matrix as dirty, 
  /// ensuring that all children are updated in the next rendering pass.
  Offset get localPosition => _localPosition;

  /// Sets the position of the object relative to its parent.
  ///
  /// * [value]: The new local position offset.
  set localPosition(Offset value) {
    if (_localPosition == value) return;
    _localPosition = value;
    _markDirty();
  }

  /// The rotation of the object relative to its parent in radians.
  ///
  /// Positive values represent clockwise rotation in the standard Goo2D 
  /// coordinate system. Use [ObjectTransform.degrees] to convert from 
  /// human-readable degrees to the required radians.
  double get localAngle => _localAngle;

  /// Sets the rotation of the object relative to its parent in radians.
  ///
  /// * [value]: The new local rotation angle.
  set localAngle(double value) {
    if (_localAngle == value) return;
    _localAngle = value;
    _markDirty();
  }

  /// The scale of the object relative to its parent.
  ///
  /// A value of (1, 1) represents the original size. Values greater than 1 
  /// will enlarge the object, while values between 0 and 1 will shrink it. 
  /// Negative values can be used to flip the object along an axis.
  Offset get localScale => _localScale;

  /// Sets the scale of the object relative to its parent.
  ///
  /// * [value]: The new local scale factors.
  set localScale(Offset value) {
    if (_localScale == value) return;
    _localScale = value;
    _markDirty();
  }

  ObjectTransform? _parentTransform;
  final List<ObjectTransform> _childTransforms = [];

  bool _isScreenSpace = false;

  /// Whether this transform exists in screen space rather than world space.
  ///
  /// Screen space transforms are typically used for UI elements that 
  /// remain fixed on the display regardless of camera movement. This 
  /// property is inherited from the parent transform by default.
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
  /// This can be used by external systems to track whether a transform 
  /// has been modified since the last update. It is particularly useful 
  /// for caching render-side data that depends on the world matrix.
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

  /// The matrix representing the local transformation.
  ///
  /// This matrix combines the local position, rotation, and scale into 
  /// a single [Matrix4]. It is cached internally and only recalculated 
  /// when one of the local properties is modified.
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

  /// The matrix representing the transformation in world space.
  ///
  /// This matrix is the product of all parent transforms and the 
  /// current local matrix. It defines the final position and orientation 
  /// of the object in the global coordinate system.
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

  /// The absolute position of the object in world coordinates.
  ///
  /// Setting this value will automatically calculate the required 
  /// [localPosition] based on the parent's transformation. This is the 
  /// preferred way to place objects at specific world coordinates.
  Offset get position {
    final t = worldMatrix.getTranslation();
    return Offset(t.x, t.y);
  }

  /// Sets the absolute position of the object in world coordinates.
  ///
  /// * [value]: The new absolute position in world space.
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

  /// The absolute rotation of the object in world space radians.
  ///
  /// This getter returns the sum of the local rotation and all parent 
  /// rotations. Setting this value will adjust the [localAngle] to 
  /// achieve the desired global orientation.
  double get angle {
    if (_parentTransform != null) {
      return _parentTransform!.angle + _localAngle;
    }
    return _localAngle;
  }

  /// Sets the absolute rotation of the object in world space radians.
  ///
  /// * [value]: The new absolute rotation in world space.
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
  /// This value accounts for the cumulative scaling of all parent 
  /// transforms. Setting this property will adjust [localScale] 
  /// relative to the parent's current absolute scale.
  Offset get scale {
    final wm = worldMatrix;
    final sx = wm.getColumn(0).xyz.length;
    final sy = wm.getColumn(1).xyz.length;
    return Offset(sx, sy);
  }

  /// Sets the absolute scale of the object in world space.
  ///
  /// * [value]: The new absolute scale factors.
  set scale(Offset value) {
    if (_parentTransform != null) {
      final ps = _parentTransform!.scale;
      _localScale = Offset(value.dx / ps.dx, value.dy / ps.dy);
    } else {
      _localScale = value;
    }
    _markDirty();
  }

  /// Transforms a point from local space to world space.
  ///
  /// This is useful for determining where a specific point on an object 
  /// (such as a gun barrel or a hit-box corner) is located in the global 
  /// coordinate system.
  ///
  /// * [local]: The coordinate relative to this object's origin.
  Offset localToWorld(Offset local) {
    final world = worldMatrix.transform3(Vector3(local.dx, local.dy, 0));
    return Offset(world.x, world.y);
  }

  /// Transforms a point from world space to local space.
  ///
  /// This is the inverse of [localToWorld] and is typically used to 
  /// determine where a global event (like a mouse click) occurred 
  /// relative to an object's local origin.
  ///
  /// * [world]: The coordinate in the global world system.
  Offset worldToLocal(Offset world) {
    final local = worldInverse.transform3(Vector3(world.dx, world.dy, 0));
    return Offset(local.x, local.y);
  }

  /// Returns the matrix to be used during the painting pass.
  ///
  /// In standard world space, this is usually identical to [localMatrix]. 
  /// Subclasses like [ScreenTransform] override this to provide custom 
  /// rendering behavior, such as counter-acting the camera transform.
  ///
  /// * [game]: The current game engine instance.
  /// * [screenSize]: The dimensions of the game display.
  Matrix4 getPaintMatrix(GameEngine game, Size screenSize) => localMatrix;

  /// Calculates the layout size of this component based on constraints.
  ///
  /// This method is primarily used for UI components that need to respond 
  /// to Flutter-style layout protocols. In standard world space, it 
  /// typically returns the biggest possible size within the constraints.
  ///
  /// * [constraints]: The layout constraints provided by the parent.
  Size getSize(BoxConstraints constraints) {
    final biggest = constraints.biggest;
    if (biggest.isInfinite) return Size.zero;
    return biggest;
  }

  /// Offsets the object's [localPosition] by the given [delta].
  ///
  /// This is a convenience method that performs a relative translation. 
  /// It is functionally equivalent to `localPosition += delta`.
  ///
  /// * [delta]: The amount to move the object.
  void translate(Offset delta) {
    localPosition = _localPosition + delta;
  }

  /// Rotates the object's [localAngle] by the given [deltaRadians].
  ///
  /// This is a convenience method that performs a relative rotation. 
  /// It is functionally equivalent to `localAngle += deltaRadians`.
  ///
  /// * [deltaRadians]: The amount to rotate the object in radians.
  void rotate(double deltaRadians) {
    localAngle = _localAngle + deltaRadians;
  }

  /// Returns the constraints that should be applied to children.
  ///
  /// By default, this loosens the current constraints, allowing children 
  /// to be any size they wish. UI components may override this to enforce 
  /// specific padding or alignment rules.
  ///
  /// * [constraints]: The incoming constraints from the parent.
  BoxConstraints getChildConstraints(BoxConstraints constraints) =>
      constraints.loosen();

  /// Computes the minimum intrinsic width for this transform.
  ///
  /// * [height]: The given height constraint.
  double computeMinIntrinsicWidth(double height) => 0;

  /// Computes the maximum intrinsic width for this transform.
  ///
  /// * [height]: The given height constraint.
  double computeMaxIntrinsicWidth(double height) => 0;

  /// Computes the minimum intrinsic height for this transform.
  ///
  /// * [width]: The given width constraint.
  double computeMinIntrinsicHeight(double width) => 0;

  /// Computes the maximum intrinsic height for this transform.
  ///
  /// * [width]: The given width constraint.
  double computeMaxIntrinsicHeight(double width) => 0;

  /// Converts an angle from [deg] degrees to radians.
  ///
  /// This is a static helper method to facilitate working with degrees 
  /// in a system that natively uses radians for all calculations.
  ///
  /// * [deg]: The angle in degrees.
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
  /// If provided, these constraints are enforced during the layout pass 
  /// and passed down to children. This allows for creating UI elements 
  /// with fixed dimensions or aspect ratios.
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
