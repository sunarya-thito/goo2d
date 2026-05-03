/// The primary entry point for the Goo2D game engine.
///
/// This barrel file centralizes all public APIs of the Goo2D engine, allowing
/// developers to import a single library to access the complete feature set.
/// It simplifies dependency management and ensures that internal implementation
/// details remain hidden while exposing stable interfaces.
///
/// Developers should import this file using `import 'package:goo2d/goo2d.dart';`.
/// The library exports essential modules including [Game], [GameObject],
/// [Component], and the physics systems. Selective hiding is used to prevent
/// name collisions with internal render objects or private providers.
///
/// ```dart
/// import 'package:goo2d/goo2d.dart';
///
/// void main() {
///   runApp(const Game(world: MyWorld()));
/// }
/// ```
library;

export 'src/game.dart' hide GameProvider;
export 'src/event.dart';
export 'src/component.dart';
export 'src/object.dart';
export 'src/element.dart' hide GameObjectElement;
export 'src/widget.dart';
export 'src/render.dart' hide GameRenderObject, GameParentData;
export 'src/pointer.dart';
export 'src/transform.dart';
export 'src/physics/utils/physics_material.dart';
export 'src/physics/core/physics_shape.dart' show CapsuleDirection;
export 'src/physics/utils/raycast_hit.dart';
export 'src/physics/utils/collision.dart';
export 'src/physics/utils/collision_state.dart';
export 'src/physics/utils/collision_event.dart';
export 'src/physics/utils/trigger_event.dart';
export 'src/physics/utils/physics_listeners.dart';
export 'src/physics/components/collider.dart';
export 'src/physics/utils/sprite_polygon_generator.dart';
export 'src/physics/components/rigidbody.dart';
export 'src/physics/components/effector.dart';
export 'src/physics/components/joint.dart';
export 'src/physics/components/physics_system.dart';
export 'src/rpc/buffer.dart';
export 'src/rpc/parser.dart';
export 'src/rpc/parsers.dart';
export 'src/rpc/registry.dart';
export 'src/rpc/rpc.dart';
export 'src/camera.dart';
export 'src/ticker.dart'
    hide GameLoop, GameRenderer, RenderGameLoop, RenderGameRenderer;
export 'src/camera_view.dart' hide RenderCameraView;
export 'src/lifecycle.dart';
export 'src/screen.dart';
export 'src/input.dart';
export 'src/asset.dart';
export 'src/coroutine.dart' hide CoroutineFuture, CoroutineInternal;
export 'src/sprite.dart';
export 'src/sprite_mesh.dart';
export 'src/sprite_pivot.dart';
export 'src/sprite_fit.dart';
export 'src/utility.dart';
export 'src/audio.dart';
export 'src/world.dart' hide RenderWorld;
