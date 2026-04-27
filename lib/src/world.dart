import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'game.dart';

/// A widget that defines the 2D world space.
/// It applies the camera transform to all its children.
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
  
  @override
  bool get isRepaintBoundary => true;

  Matrix4? _getTransform() {
    if (!game.cameras.isReady) return null;
    final camera = game.cameras.main;

    final screenSize = game.ticker.screenSize;
    if (screenSize == Size.zero ||
        screenSize.width == 0 ||
        screenSize.height == 0) {
      return null;
    }

    final viewMatrix = camera.worldToCameraMatrix;
    final projMatrix = camera.projectionMatrix(screenSize);

    final viewportMatrix = Matrix4.identity()
      ..translateByDouble(screenSize.width / 2, screenSize.height / 2, 0.0, 1.0)
      ..scaleByDouble(screenSize.width / 2, -screenSize.height / 2, 1.0, 1.0);

    return viewportMatrix * projMatrix * viewMatrix;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) return;

    final transform = _getTransform();
    if (transform == null) {
      super.paint(context, offset);
      return;
    }

    if (game.isSecondaryPass) {
      context.canvas.save();
      context.canvas.translate(offset.dx, offset.dy);
      context.canvas.transform(transform.storage);
      context.paintChild(child!, Offset.zero);
      context.canvas.restore();
    } else {
      game.currentRenderCamera = game.cameras.main;
      try {
        context.pushTransform(needsCompositing, offset, transform, (
          context,
          offset,
        ) {
          context.paintChild(child!, offset);
        });
      } finally {
        game.currentRenderCamera = null;
      }
    }
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // We still bypass our own bounds check so the world-root doesn't clip its children.
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

    return result.addWithPaintTransform(
      transform: transform,
      position: position,
      hitTest: (result, transformedPosition) {
        return child!.hitTest(result, position: transformedPosition);
      },
    );
  }
}
