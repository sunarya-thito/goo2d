import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'game.dart';
import 'camera.dart';
import 'object.dart';
import 'world.dart';

class CameraView extends SingleChildRenderObjectWidget {
  final GameTag cameraTag;

  const CameraView({super.key, required this.cameraTag, super.child});

  @override
  RenderCameraView createRenderObject(BuildContext context) {
    return RenderCameraView(
      game: GameProvider.of(context),
      cameraTag: cameraTag,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderCameraView renderObject) {
    renderObject
      ..game = GameProvider.of(context)
      ..cameraTag = cameraTag;
  }
}

class RenderCameraView extends RenderProxyBox {
  GameEngine game;
  GameTag cameraTag;

  RenderCameraView({required this.game, required this.cameraTag});

  @override
  bool get alwaysNeedsCompositing => false;

  @override
  void performLayout() {
    size = constraints.constrain(
      constraints.isTight ? constraints.biggest : const Size(150, 150),
    );
  }

  @override
  double computeMinIntrinsicWidth(double height) => 0;
  @override
  double computeMaxIntrinsicWidth(double height) => 10000;
  @override
  double computeMinIntrinsicHeight(double width) => 0;
  @override
  double computeMaxIntrinsicHeight(double width) => 10000;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (game.isSecondaryPass) {
      super.paint(context, offset);
      return;
    }

    final camera = cameraTag.gameObject?.tryGetComponent<Camera>();
    if (camera == null || !camera.gameObject.active || !camera.enabled) {
      super.paint(context, offset);
      return;
    }

    final screenSize = game.ticker.screenSize;
    // debugPrint('goo2d: Minimap paint - screenSize: $screenSize, size: $size');
    if (screenSize == Size.zero) {
      super.paint(context, offset);
      return;
    }

    if (camera.clearFlags == CameraClearFlags.solidColor) {
      final paint = Paint()..color = camera.backgroundColor;
      context.canvas.drawRect(offset & size, paint);
    }

    // 1. Calculate the full transformation for the secondary view
    final viewMatrix = camera.worldToCameraMatrix;

    // Use the local size directly for the projection and viewport mapping.
    // This ensures that the minimap covers the expected orthographic area (100x100 units if size=50)
    // regardless of the main window's aspect ratio.
    final projMatrix = camera.projectionMatrix(size);
    final viewportMatrix = Matrix4.identity()
      ..translateByDouble(size.width / 2, size.height / 2, 0.0, 1.0)
      ..scaleByDouble(size.width / 2, -size.height / 2, 1.0, 1.0);

    final fullCameraMatrix = viewportMatrix * projMatrix * viewMatrix;

    // 2. Find the RenderWorld ancestor
    RenderWorld? world;
    RenderObject? current = parent;
    while (current != null) {
      if (current is RenderWorld) {
        world = current;
        break;
      }
      current = current.parent;
    }
    if (world == null) {
      debugPrint('goo2d: Minimap could NOT find RenderWorld ancestor!');
    }

    if (world != null && world.child != null) {
      game.isSecondaryPass = true;
      game.currentRenderCamera = camera;
      try {
        context.canvas.save();
        context.canvas.clipRect(offset & size);
        context.canvas.translate(offset.dx, offset.dy);
        context.canvas.transform(fullCameraMatrix.storage);

        _paintFiltered(context, Offset.zero, world.child!);
        context.canvas.restore();
      } finally {
        game.isSecondaryPass = false;
        game.currentRenderCamera = null;
      }
    }

    super.paint(context, offset);
  }

  void _paintFiltered(
    PaintingContext context,
    Offset offset,
    RenderObject node,
  ) {
    if (node == this) return;

    if (_isAncestorOf(node, this)) {
      node.visitChildren((child) {
        Offset childOffset = offset;
        if (child.parentData is BoxParentData) {
          childOffset += (child.parentData as BoxParentData).offset;
        }
        _paintFiltered(context, childOffset, child);
      });
    } else {
      if (node is GameRenderObject) {
        final camera = cameraTag.gameObject?.tryGetComponent<Camera>();
        if (camera != null && (node.object.layer & camera.cullingMask) == 0) {
          return;
        }
      }
      context.paintChild(node, offset);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    // If we're already in a secondary pass, don't start another hit-test pass.
    if (game.isSecondaryPass) return false;

    final camera = cameraTag.gameObject?.tryGetComponent<Camera>();
    if (camera == null || !camera.gameObject.active || !camera.enabled) {
      return super.hitTestChildren(result, position: position);
    }

    final screenSize = game.ticker.screenSize;
    if (screenSize == Size.zero) return false;

    game.isSecondaryPass = true;
    try {
      final viewMatrix = camera.worldToCameraMatrix;
      final projMatrix = camera.projectionMatrix(screenSize);

      final viewportMatrix = Matrix4.identity()
        ..translateByDouble(
          screenSize.width / 2,
          screenSize.height / 2,
          0.0,
          1.0,
        )
        ..scaleByDouble(screenSize.width / 2, -screenSize.height / 2, 1.0, 1.0);

      // Local scaling to fit the RenderBox size
      final localScaleX = size.width / screenSize.width;
      final localScaleY = size.height / screenSize.height;
      final localScaleMatrix = Matrix4.identity()
        ..scaleByDouble(localScaleX, localScaleY, 1.0, 1.0);

      final fullCameraMatrix =
          localScaleMatrix * viewportMatrix * projMatrix * viewMatrix;

      // Find the RenderWorld ancestor and all roots to test against
      RenderWorld? world;
      RenderObject? current = parent;
      while (current != null) {
        if (current is RenderWorld) {
          world = current;
          break;
        }
        current = current.parent;
      }

      final List<RenderBox> worldRoots = [];
      if (world != null && world.child != null) {
        void findWorldRoots(RenderObject node) {
          if (node is GameRenderObject) {
            // Check if this node is part of our own HUD branch
            if (_isAncestorOf(node, this)) return;

            worldRoots.add(node);
          } else {
            node.visitChildren(findWorldRoots);
          }
        }

        findWorldRoots(world.child!);
      }

      if (worldRoots.isNotEmpty) {
        return result.addWithPaintTransform(
          transform: fullCameraMatrix,
          position: position,
          hitTest: (result, transformedPosition) {
            for (final root in worldRoots) {
              if (root.hitTest(result, position: transformedPosition)) {
                return true;
              }
            }
            return false;
          },
        );
      }

      return super.hitTestChildren(result, position: position);
    } finally {
      game.isSecondaryPass = false;
    }
  }

  bool _isAncestorOf(RenderObject ancestor, RenderObject node) {
    RenderObject? current = node;
    while (current != null) {
      if (current == ancestor) return true;
      current = current.parent;
    }
    return false;
  }
}
