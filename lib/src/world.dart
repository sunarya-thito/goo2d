import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:goo2d/src/game.dart';

/// A Flutter widget that serves as the root container for the 2D world space.
/// 
/// The [World] widget is the essential bridge between the declarative Flutter 
/// [Widget] tree and the Goo2D engine's specialized rendering pipeline. It 
/// establishes a world-space coordinate system where children can be positioned 
/// relative to a global origin rather than the screen's top-left corner.
/// 
/// It automatically retrieves the current [Camera.main] matrix from the 
/// [CameraSystem] and applies it to all of its children. This effectively 
/// "projects" standard Flutter widgets into the game world, allowing them 
/// to move, rotate, and scale as the camera navigates through the scene.
/// 
/// Example usage:
/// ```dart
/// Goo2D(
///   game: myGame,
///   child: World(
///     child: GameObject(
///       name: 'Player',
///       child: Sprite(image: playerImage),
///     ),
///   ),
/// );
/// ```
class World extends SingleChildRenderObjectWidget {
  /// Creates a [World] widget that transforms its [child] into world-space.
  /// 
  /// Initializes the bridge between the Flutter tree and game coordinates.
  /// 
  /// * [key]: Standard Flutter widget key.
  /// * [child]: The scene content to render in world-space.
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

/// The [RenderObject] that performs the coordinate transformation for the game world.
/// 
/// [RenderWorld] acts as a high-performance proxy that intercepts Flutter's 
/// painting and hit-testing phases. Its primary responsibility is to calculate 
/// and apply the View-Projection matrix provided by the active camera.
/// 
/// ### Coordinate Mapping
/// It calculates the [Camera.getFullMatrix] to map world-space coordinates 
/// (where +Y is up) to the physical screen pixels (where +Y is down), 
/// accounting for resolution scaling, camera zoom, and sub-pixel alignment.
/// 
/// ### Interaction handling
/// It also handles recursive [hitTest] logic. When a user taps the screen, 
/// [RenderWorld] "unprojects" the screen-space pointer offset back into 
/// the world-space coordinate system. This ensures that game objects can 
/// receive standard Flutter gesture events even when heavily transformed 
/// by the camera.
/// 
/// Example of internal usage:
/// ```dart
/// final world = RenderWorld(game: myEngine);
/// // The world will now automatically handle matrix application 
/// // during the paint phase.
/// ```
class RenderWorld extends RenderProxyBox {
  /// The [GameEngine] instance that provides access to the camera and ticker systems.
  /// 
  /// The [game] engine is the central source of truth for the viewport size 
  /// and the active camera stack. [RenderWorld] depends on this to perform 
  /// its projection calculations.
  GameEngine game;

  /// Creates a [RenderWorld] instance bound to a specific [game] engine.
  /// 
  /// Initializes the render object with its engine dependency.
  /// 
  /// * [game]: The engine instance to read camera data from.
  RenderWorld({required this.game});

  /// Retrieves the current view-projection matrix from the main camera.
  /// 
  /// This method performs safe-checks for system initialization. It returns 
  /// `null` if the [CameraSystem] is not yet ready or if the engine's 
  /// internal [screenSize] report is invalid (e.g., during the very first 
  /// layout frame).
  /// 
  /// The returned matrix handles the translation from game coordinates to 
  /// screen pixels.
  Matrix4? _getTransform() {
    if (!game.cameras.isReady) return null;
    final camera = game.cameras.main;

    final screenSize = game.ticker.screenSize;
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

    if (game.isSecondaryPass) {
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
