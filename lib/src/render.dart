import 'dart:ui';

import 'package:goo2d/goo2d.dart';

/// An interface for objects that can be rendered to a [Canvas].
///
/// Classes mixing in [Renderable] must implement the [render] method. This 
/// mixin also identifies the object as an [EventListener], allowing it to 
/// participate in the engine's automated rendering pass.
///
/// See also:
/// * [RenderEvent], the event that triggers the rendering process.
mixin Renderable implements EventListener {
  /// Renders the object's visual representation.
  ///
  /// This is called during the [RenderEvent] dispatch. The [canvas] is 
  /// pre-transformed by the object's [Transform] and [Camera] settings.
  ///
  /// * [canvas]: The target drawing surface.
  void render(Canvas canvas);
}

/// An event dispatched to trigger rendering on all [Renderable] components.
///
/// This event carries the target [Canvas] and is sent through the scene 
/// graph by the [GameEngine] during the paint phase of the Flutter pipeline.
///
/// ```dart
/// // Example of a manual render dispatch
/// world.dispatch(RenderEvent(myCanvas));
/// ```
///
/// See also:
/// * [Renderable], the interface that receives this event.
class RenderEvent extends Event<Renderable> {
  /// The canvas to draw upon.
  /// 
  /// This [Canvas] is provided by the Flutter painting framework and is 
  /// used for all drawing operations in the current frame.
  final Canvas canvas;

  /// Creates a render event with the given [canvas].
  /// 
  /// * [canvas]: The drawing surface for the current frame.
  const RenderEvent(this.canvas);

  @override
  void dispatch(Renderable listener) {
    listener.render(canvas);
  }
}

/// Bitmask constants for rendering layers.
///
/// Layers allow for selective rendering (via [Camera.cullingMask]) and 
/// collision filtering. Each object can belong to one or more layers.
/// 
/// ```dart
/// gameObject.layer = RenderLayer.world;
/// ```
/// 
/// See also:
/// * [GameObject.layer] for setting an object's layer.
/// * [Camera] for culling layers during rendering.
class RenderLayer {
  /// No layers selected (0x0).
  /// 
  /// This mask represents an empty set of layers, typically used to 
  /// disable rendering or collisions entirely.
  static const int none = 0;

  /// The default layer for new objects (bit 0).
  /// 
  /// Most game objects should belong to this layer unless they 
  /// require specialized culling or filtering.
  static const int defaultLayer = 1 << 0;

  /// Alias for the default layer, typically used for world objects.
  /// 
  /// Provides a descriptive name for objects that reside in the 
  /// main game world.
  static const int world = 1 << 0;

  /// Layer typically used for UI elements (bit 1).
  /// 
  /// Objects on this layer are often rendered by a separate camera 
  /// that ignores world-space transformations.
  static const int ui = 1 << 1;

  /// All layers selected (0xFFFFFFFF).
  /// 
  /// This mask includes every bit, effectively selecting all possible 
  /// rendering layers for culling or filtering.
  static const int all = 0xFFFFFFFF;

  RenderLayer._();
}
