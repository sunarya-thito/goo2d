import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'package:goo2d/src/game.dart';
import 'package:goo2d/src/event.dart';
import 'package:goo2d/src/pointer.dart';
import 'package:goo2d/src/transform.dart';
import 'package:goo2d/src/physics/components/collider.dart';
import 'package:goo2d/src/object.dart';

mixin Renderable implements EventListener {
  void render(Canvas canvas);
}

class RenderEvent extends Event<Renderable> {
  final Canvas canvas;
  const RenderEvent(this.canvas);

  @override
  void dispatch(Renderable listener) {
    listener.render(canvas);
  }
}

class RenderLayer {
  static const int none = 0;
  static const int defaultLayer = 1 << 0;
  static const int world = 1 << 0;
  static const int ui = 1 << 1;
  static const int all = 0xFFFFFFFF;

  RenderLayer._();
}

class GameParentData extends ContainerBoxParentData<RenderBox> {}

class GameRenderObject extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, GameParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, GameParentData>
    implements MouseTrackerAnnotation {
  GameObject object;
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
    final cameraSystem = object.game.getSystem<CameraSystem>();
    final camera = cameraSystem?.currentRenderCamera;
    if (camera != null && (object.layer & camera.cullingMask) == 0) {
      return;
    }

    final optionalTransform = object.tryGetComponent<ObjectTransform>();

    if (optionalTransform != null) {
      final screenSize = object.game.screen.screenSize;
      final paintMatrix = optionalTransform.getPaintMatrix(
        object.game,
        screenSize,
      );

      if (cameraSystem?.isSecondaryPass ?? false || !needsCompositing) {
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
      final screenSize = object.game.screen.screenSize;
      final paintMatrix = optionalTransform.getPaintMatrix(
        object.game,
        screenSize,
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
