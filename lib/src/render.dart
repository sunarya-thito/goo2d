import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'package:goo2d/src/game.dart';
import 'package:goo2d/src/event.dart';
import 'package:goo2d/src/pointer.dart';
import 'package:goo2d/src/transform.dart';
import 'package:goo2d/src/physics/collider.dart';
import 'package:goo2d/src/camera.dart';
import 'package:goo2d/src/object.dart';

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

/// Data associated with a [GameObject] when it is positioned
/// inside a [GameRenderObject].
class GameParentData extends ContainerBoxParentData<RenderBox> {}

/// The [RenderObject] that handles the layout and painting of a [GameObject].
///
/// It uses a coordinate system defined by the [GameObject]'s [ObjectTransform]
/// component and manages a list of child render objects.
class GameRenderObject extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, GameParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, GameParentData>
    implements MouseTrackerAnnotation {
  /// The object this render object is serving.
  GameObject object;

  /// Creates a [GameRenderObject].
  GameRenderObject(this.object);

  @override
  PointerEnterEventListener? get onEnter =>
      (event) => object.broadcastEvent(GamePointerEnterEvent(event));

  @override
  PointerExitEventListener? get onExit =>
      (event) => object.broadcastEvent(GamePointerExitEvent(event));

  @override
  MouseCursor get cursor => MouseCursor.defer;

  @override
  bool get validForMouseTracker => true;

  @override
  void setupParentData(covariant RenderObject child) {
    if (child.parentData is! GameParentData) {
      child.parentData = GameParentData();
    }
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final transform = object.tryGetComponent<ObjectTransform>();
    if (transform != null) {
      return transform.getSize(constraints);
    }
    return constraints.constrain(Size.infinite);
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return object.tryGetComponent<ObjectTransform>()?.computeMaxIntrinsicHeight(
          width,
        ) ??
        0;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return object.tryGetComponent<ObjectTransform>()?.computeMaxIntrinsicWidth(
          height,
        ) ??
        0;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return object.tryGetComponent<ObjectTransform>()?.computeMinIntrinsicHeight(
          width,
        ) ??
        0;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return object.tryGetComponent<ObjectTransform>()?.computeMinIntrinsicWidth(
          height,
        ) ??
        0;
  }

  @override
  void performLayout() {
    final transform = object.tryGetComponent<ObjectTransform>();
    final objectSize =
        transform?.getSize(constraints) ?? constraints.constrain(Size.infinite);
    final childConstraints =
        transform?.getChildConstraints(constraints) ?? constraints.loosen();

    RenderObject? child = firstChild;
    while (child != null) {
      child.layout(childConstraints);
      child = (child.parentData as GameParentData).nextSibling;
    }
    size = objectSize.isInfinite ? Size.zero : objectSize;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final camera = object.game.currentRenderCamera;
    if (camera != null && (object.layer & camera.cullingMask) == 0) {
      return;
    }

    final optionalTransform = object.tryGetComponent<ObjectTransform>();

    if (optionalTransform != null) {
      final paintMatrix = optionalTransform.getPaintMatrix(
        object.game,
        object.game.ticker.screenSize,
      );

      if (object.game.isSecondaryPass || !needsCompositing) {
        context.canvas.save();
        context.canvas.translate(offset.dx, offset.dy);
        context.canvas.transform(paintMatrix.storage);

        RenderEvent(context.canvas).dispatchTo(object);
        defaultPaint(context, Offset.zero);
        context.canvas.restore();
      } else {
        layer = context.pushTransform(
          needsCompositing,
          offset,
          paintMatrix,
          (context, offset) {
            RenderEvent(context.canvas).dispatchTo(object);
            defaultPaint(context, offset);
          },
        );
      }
    } else {
      context.canvas.save();
      context.canvas.translate(offset.dx, offset.dy);
      RenderEvent(context.canvas).dispatchTo(object);
      context.canvas.restore();
      defaultPaint(context, offset);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final optionalTransform = object.tryGetComponent<ObjectTransform>();
    if (optionalTransform != null) {
      final paintMatrix = optionalTransform.getPaintMatrix(
        object.game,
        object.game.ticker.screenSize,
      );
      return result.addWithPaintTransform(
        transform: paintMatrix,
        position: position,
        hitTest: (BoxHitTestResult result, Offset? transformedPosition) {
          if (transformedPosition == null) return false;
          if (hitTestChildren(result, position: transformedPosition) ||
              hitTestSelf(transformedPosition)) {
            result.add(BoxHitTestEntry(this, transformedPosition));
            return true;
          }
          return false;
        },
      );
    }

    if (hitTestChildren(result, position: position) || hitTestSelf(position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }

  @override
  bool hitTestSelf(Offset position) {
    for (var component in object.getComponents<Collider>()) {
      if (component.containsPoint(position)) {
        return true;
      }
    }
    return false;
  }

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is PointerDownEvent) {
      object.broadcastEvent(GamePointerDownEvent(event));
    } else if (event is PointerUpEvent) {
      object.broadcastEvent(GamePointerUpEvent(event));
    } else if (event is PointerMoveEvent) {
      object.broadcastEvent(GamePointerMoveEvent(event));
    } else if (event is PointerCancelEvent) {
      object.broadcastEvent(GamePointerCancelEvent(event));
    } else if (event is PointerHoverEvent) {
      object.broadcastEvent(GamePointerHoverEvent(event));
    }
  }
}
