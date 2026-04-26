import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'game.dart';

class CanvasWidget extends SingleChildRenderObjectWidget {
  const CanvasWidget({super.key, super.child});

  @override
  RenderCanvasWidget createRenderObject(BuildContext context) {
    return RenderCanvasWidget(
      game: GameProvider.of(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderCanvasWidget renderObject) {
    renderObject.game = GameProvider.of(context);
  }
}

class RenderCanvasWidget extends RenderProxyBox {
  GameEngine game;

  RenderCanvasWidget({required this.game});

  Matrix4? _getInverseCameraMatrix() {
    if (!game.cameras.isReady) return null;
    final camera = game.cameras.main;
    
    final screenSize = game.ticker.screenSize;
    if (screenSize == Size.zero || screenSize.width == 0 || screenSize.height == 0) {
      return null;
    }
    
    final viewMatrix = camera.worldToCameraMatrix;
    final projMatrix = camera.projectionMatrix(screenSize);

    final viewportMatrix = Matrix4.identity()
      ..translateByDouble(screenSize.width / 2, screenSize.height / 2, 0.0, 1.0)
      ..scaleByDouble(screenSize.width / 2, -screenSize.height / 2, 1.0, 1.0);

    final fullCameraMatrix = viewportMatrix * projMatrix * viewMatrix;
    
    try {
      return Matrix4.inverted(fullCameraMatrix);
    } catch (e) {
      return null;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final invMatrix = _getInverseCameraMatrix();
    
    if (invMatrix == null) {
      super.paint(context, offset);
      return;
    }

    if (game.isSecondaryPass) {
      super.paint(context, offset);
    } else {
      // CRITICAL: We push the inverse transform at Offset.zero.
      // This way, the 'offset' (HUD's local position) is applied AFTER the inverse matrix,
      // ensuring the HUD stays in Screen Space relative to its intended screen-coordinate.
      context.pushTransform(false, Offset.zero, invMatrix, (context, _) {
        super.paint(context, offset);
      });
    }
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (hitTestChildren(result, position: position) || hitTestSelf(position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final parentData = this.parentData;
    final Offset localOffset;
    if (parentData is BoxParentData) {
      localOffset = parentData.offset;
    } else {
      localOffset = Offset.zero;
    }

    final invMatrix = _getInverseCameraMatrix();
    if (invMatrix == null) {
      return super.hitTestChildren(result, position: position);
    }

    return result.addWithPaintTransform(
      transform: invMatrix,
      position: position,
      hitTest: (result, transformedPosition) {
        // transformedPosition is now in screen space.
        return child?.hitTest(result, position: transformedPosition - localOffset) ?? false;
      },
    );
  }
}
