import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:goo2d/src/game.dart';

class World extends SingleChildRenderObjectWidget {
  const World({super.key, super.child});

  @override
  RenderWorld createRenderObject(BuildContext context) {
    return RenderWorld(game: GameProvider.of(context));
  }

  @override
  void updateRenderObject(BuildContext context, RenderWorld renderObject) {
    renderObject.game = GameProvider.of(context);
  }
}

class RenderWorld extends RenderProxyBox {
  GameEngine game;
  RenderWorld({required this.game});
  Matrix4? _getTransform() {
    final cameras = game.getSystem<CameraSystem>();
    if (cameras == null || !cameras.isReady) return null;
    final camera = cameras.main;

    final screenSize = game.screen.screenSize;
    if (screenSize == Size.zero ||
        screenSize.width == 0 ||
        screenSize.height == 0) {
      return null;
    }

    return camera.getFullMatrix(screenSize);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) return;

    final transform = _getTransform();
    if (transform == null) {
      super.paint(context, offset);
      return;
    }

    final cameraSystem = game.getSystem<CameraSystem>();
    if (cameraSystem?.isSecondaryPass ?? false) {
      // Manual transformation for non-standard rendering passes
      // (e.g. shadow maps or post-processing buffers).
      context.canvas.save();
      context.canvas.translate(offset.dx, offset.dy);
      context.canvas.transform(transform.storage);
      context.paintChild(child!, Offset.zero);
      context.canvas.restore();
    } else {
      // Standard Flutter transform push, allowing for hardware
      // acceleration and layer optimization.
      if (cameraSystem != null) {
        cameraSystem.currentRenderCamera = cameraSystem.main;
      }
      try {
        context.pushTransform(needsCompositing, offset, transform, (
          context,
          offset,
        ) {
          context.paintChild(child!, offset);
        });
      } finally {
        if (cameraSystem != null) {
          cameraSystem.currentRenderCamera = null;
        }
      }
    }
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // We bypass our own bounds check so the world-root doesn't
    // clip its children. This allows objects to be interactive even
    // if they are partially outside the initial render box boundaries,
    // which is common in sprawling 2D environments.
    if (hitTestChildren(result, position: position) || hitTestSelf(position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (child == null) return false;

    final transform = _getTransform();
    if (transform == null) {
      return super.hitTestChildren(result, position: position);
    }

    // Unprojects the screen-space pointer position into the world-space
    // child coordinate system using the inverse camera matrix.
    return result.addWithPaintTransform(
      transform: transform,
      position: position,
      hitTest: (result, transformedPosition) {
        return child!.hitTest(result, position: transformedPosition);
      },
    );
  }
}
