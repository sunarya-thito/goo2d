import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'game.dart';
import 'camera.dart';
import 'object.dart';
import 'world.dart';

/// A widget that renders a specific camera's view into a sub-region of the screen.
/// 
/// [CameraView] is primarily used for secondary views like minimaps, rearview 
/// mirrors, or picture-in-picture effects. It looks up a [Camera] component 
/// associated with the given [cameraTag] and renders the scene from that 
/// camera's perspective within its own bounds.
/// 
/// The view is rendered using the same world-space coordinate system as 
/// the main game [World], but applies the transformation and culling 
/// settings of the specific secondary camera.
/// 
/// Example:
/// ```dart
/// CameraView(
///   cameraTag: GameTag('MinimapCamera'),
/// )
/// ```
class CameraView extends SingleChildRenderObjectWidget {
  /// The tag of the [GameObject] that contains the [Camera] component to render.
  /// 
  /// This tag is used to resolve the target camera at runtime. If multiple 
  /// objects share the same tag, the first active one is used.
  final GameTag cameraTag;

  /// Creates a [CameraView] that renders the view from the camera tagged [cameraTag].
  /// 
  /// * [key]: Standard Flutter widget key.
  /// * [cameraTag]: The tag identifying the target camera.
  /// * [child]: Optional child widget to wrap.
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

/// The [RenderObject] that performs the drawing for a [CameraView].
/// 
/// [RenderCameraView] handles the coordination between the Flutter painting 
/// pipeline and the Goo2D secondary rendering pass. It ensures that 
/// the target [Camera] is correctly positioned and that its projection 
/// matrix is adjusted to fit the [RenderBox] size.
/// 
/// ```dart
/// // Internal use via CameraView widget
/// ```
/// 
/// See also:
/// * [CameraView], the widget that uses this render object.
class RenderCameraView extends RenderProxyBox {
  /// The engine instance providing access to systems.
  /// 
  /// Used to coordinate secondary passes and access the [TickerState].
  GameEngine game;
  
  /// The tag used to identify the target camera.
  /// 
  /// The system looks up the [GameObject] with this tag to find 
  /// the active [Camera] component.
  GameTag cameraTag;

  /// Creates a [RenderCameraView] instance.
  /// 
  /// Initializes the render object with its engine and camera dependencies.
  /// 
  /// * [game]: The engine instance to use.
  /// * [cameraTag]: The tag for the target camera.
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
    // This ensures that the minimap covers the expected orthographic area
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

  /// Recursively paints children while applying camera culling masks.
  /// 
  /// This method traverses the scene graph and only paints [RenderObject]s 
  /// whose layer matches the target camera's [Camera.cullingMask].
  /// 
  /// * [context]: The painting context to draw into.
  /// * [offset]: The drawing offset.
  /// * [node]: The current render node being processed.
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

  /// Utility to check if [ancestor] is in the parent chain of [node].
  /// 
  /// Perfroms a recursive climb up the [RenderObject] tree to determine 
  /// structural relationship.
  /// 
  /// * [ancestor]: The potential parent node.
  /// * [node]: The potential descendant node.
  bool _isAncestorOf(RenderObject ancestor, RenderObject node) {
    RenderObject? current = node;
    while (current != null) {
      if (current == ancestor) return true;
      current = current.parent;
    }
    return false;
  }
}
