import 'package:flutter/gestures.dart';
import 'package:goo2d/goo2d.dart';

/// Adds physics-based mouse/touch dragging to any dynamic Rigidbody.
///
/// A TargetJoint is created when the pointer presses on the body's collider
/// and removed on release.
class DragBehavior extends Behavior with PointerReceiver {
  TargetJoint? _joint;

  /// The world matrix captured at pointer-down time.
  ///
  /// Flutter reuses the hit-test entry transform from pointer-down for all
  /// subsequent move/up events. That transform bakes in worldMatrix_initial⁻¹,
  /// so applying worldMatrix_initial to event.localPosition recovers the true
  /// cursor world position for every event in the gesture — even as the body moves.
  Matrix4? _capturedMatrix;

  @override
  void onPointerDown(PointerDownEvent event) {
    if (_joint != null) return;
    final transform = gameObject.tryGetComponent<ObjectTransform>();
    _capturedMatrix = transform?.worldMatrix.clone();
    final joint = TargetJoint()
      ..autoConfigureTarget = false
      ..anchor = Vector2.zero()
      ..target = _toWorld(event)
      ..maxForce = 10000.0
      ..frequency = 12.0
      ..dampingRatio = 0.8;
    addComponent(joint);
    _joint = joint;
  }

  @override
  void onPointerMove(PointerMoveEvent event) {
    _joint?.target = _toWorld(event);
  }

  @override
  void onPointerUp(PointerUpEvent event) => _release();

  @override
  void onPointerCancel(PointerCancelEvent event) => _release();

  void _release() {
    final joint = _joint;
    if (joint == null) return;
    _joint = null;
    _capturedMatrix = null;
    removeComponent(joint);
  }

  Vector2 _toWorld(PointerEvent event) {
    final m = _capturedMatrix;
    if (m != null) {
      final p = event.localPosition;
      final v = m.transform3(Vector3(p.dx, p.dy, 0.0));
      return Vector2(v.x, v.y);
    }
    final camera = game.cameras.main;
    return camera.screenToWorldPoint(
      Vector2(event.localPosition.dx, event.localPosition.dy),
      game.screen.screenSize,
    );
  }
}
