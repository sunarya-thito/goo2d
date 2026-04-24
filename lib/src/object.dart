import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:goo2d/goo2d.dart';
import 'package:goo2d/src/component.dart';
import 'package:meta/meta.dart';

class GameTag extends GlobalObjectKey {
  const GameTag(super.value);

  GameObject? get gameObject => currentContext as GameObject?;
}

abstract class GameObject implements BuildContext {
  Object? get tag;
  bool get active;
  GameObject get rootObject;
  GameObject? get parentObject;
  Iterable<GameObject> get childrenObjects;
  Iterable<Component> get components;

  void addComponent(
    Component component, [
    Component? a,
    Component? b,
    Component? c,
    Component? d,
    Component? e,
    Component? f,
    Component? g,
    Component? h,
    Component? i,
    Component? j,
  ]);
  void removeComponent(
    Component component, [
    Component? a,
    Component? b,
    Component? c,
    Component? d,
    Component? e,
    Component? f,
    Component? g,
    Component? h,
    Component? i,
    Component? j,
  ]);

  Iterable<T> getComponentsInChildren<T extends Component>();
  T getComponentInParent<T extends Component>();
  T? tryGetComponentInParent<T extends Component>();
  void broadcastEvent(Event event);
  void sendEvent(Event event);
  T getComponent<T extends Component>();
  T? tryGetComponent<T extends Component>();
  Iterable<T> getComponents<T extends Component>();

  @internal
  List<GameObject> get internalChildrenObjects;

  @internal
  set internalParentObject(GameObject? value);
}

mixin GameObjectMixin implements GameObject {
  final List<Component> _components = [];
  final List<GameObject> _childrenObjects = [];
  GameObject? _parentObject;

  @override
  bool get active => true; // Default to true, subclasses can override

  @override
  Object? get tag => null; // Default to null, subclasses can override

  @override
  List<GameObject> get internalChildrenObjects => _childrenObjects;

  @override
  set internalParentObject(GameObject? value) => _parentObject = value;

  @override
  Iterable<GameObject> get childrenObjects =>
      List.unmodifiable(_childrenObjects);

  @override
  Iterable<Component> get components => List.unmodifiable(_components);

  @override
  GameObject? get parentObject => _parentObject;

  void _addComponentInternal(Component comp) {
    _components.add(comp);
    internalAttach(comp, this);
    if (active && comp is LifecycleListener) {
      comp.onMounted();
    }
  }

  @override
  void addComponent(
    Component component, [
    Component? a,
    Component? b,
    Component? c,
    Component? d,
    Component? e,
    Component? f,
    Component? g,
    Component? h,
    Component? i,
    Component? j,
  ]) {
    _addComponentInternal(component);
    if (a != null) _addComponentInternal(a);
    if (b != null) _addComponentInternal(b);
    if (c != null) _addComponentInternal(c);
    if (d != null) _addComponentInternal(d);
    if (e != null) _addComponentInternal(e);
    if (f != null) _addComponentInternal(f);
    if (g != null) _addComponentInternal(g);
    if (h != null) _addComponentInternal(h);
    if (i != null) _addComponentInternal(i);
    if (j != null) _addComponentInternal(j);
  }

  void _removeComponentInternal(Component comp) {
    if (_components.remove(comp)) {
      if (active && comp is LifecycleListener) {
        comp.onUnmounted();
      }
    }
  }

  @override
  void removeComponent(
    Component component, [
    Component? a,
    Component? b,
    Component? c,
    Component? d,
    Component? e,
    Component? f,
    Component? g,
    Component? h,
    Component? i,
    Component? j,
  ]) {
    _removeComponentInternal(component);
    if (a != null) _removeComponentInternal(a);
    if (b != null) _removeComponentInternal(b);
    if (c != null) _removeComponentInternal(c);
    if (d != null) _removeComponentInternal(d);
    if (e != null) _removeComponentInternal(e);
    if (f != null) _removeComponentInternal(f);
    if (g != null) _removeComponentInternal(g);
    if (h != null) _removeComponentInternal(h);
    if (i != null) _removeComponentInternal(i);
    if (j != null) _removeComponentInternal(j);
  }

  @override
  T getComponent<T extends Component>() {
    return _components.whereType<T>().first;
  }

  @override
  T? tryGetComponent<T extends Component>() {
    return _components.whereType<T>().firstOrNull;
  }

  @override
  Iterable<T> getComponents<T extends Component>() {
    return _components.whereType<T>();
  }

  @override
  Iterable<T> getComponentsInChildren<T extends Component>() sync* {
    yield* _components.whereType<T>();
    for (final child in childrenObjects) {
      yield* child.getComponentsInChildren<T>();
    }
  }

  @override
  T getComponentInParent<T extends Component>() {
    T? result = tryGetComponentInParent<T>();
    if (result != null) {
      return result;
    }
    throw Exception('Component $T not found in parent');
  }

  @override
  T? tryGetComponentInParent<T extends Component>() {
    GameObject? parent = parentObject;
    while (parent != null) {
      T? result = parent.tryGetComponent<T>();
      if (result != null) {
        return result;
      }
      parent = parent.parentObject;
    }
    return null;
  }

  @override
  void broadcastEvent(Event event) {
    event.dispatchTo(this);
    sendEvent(event);
  }

  @override
  void sendEvent(Event event) {
    for (var child in _childrenObjects) {
      child.broadcastEvent(event);
    }
  }

  @override
  GameObject get rootObject {
    GameObject root = this;
    GameObject? current = this;
    while (current != null) {
      root = current;
      current = current.parentObject;
    }
    return root;
  }
}

class GameWidget extends MultiChildRenderObjectWidget {
  static List<Component> _emptyComponents() {
    return [];
  }

  final List<Component> Function() components;

  const GameWidget({
    super.key,
    this.components = _emptyComponents,
    super.children = const [],
  });

  @override
  GameElement createElement() {
    return GameElement(this);
  }

  @override
  RenderObject createRenderObject(BuildContext context) {
    return GameRenderObject(context as GameElement);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderObject renderObject,
  ) {
    (renderObject as GameRenderObject).object = context as GameElement;
  }
}

class GameElement extends MultiChildRenderObjectElement
    with GameObjectMixin
    implements GameObject {
  GameElement(super.widget);

  @override
  Object? get tag =>
      widget.key is GameTag ? (widget.key as GameTag).value : null;

  @override
  bool get active => mounted;

  @override
  void mount(Element? parent, Object? newSlot) {
    final components = (widget as GameWidget).components();
    for (var component in components) {
      addComponent(component);
    }
    super.mount(parent, newSlot);
    _attachToParent();
    const MountedEvent().dispatchTo(this);
  }

  @override
  void activate() {
    super.activate();
    _attachToParent();
  }

  @override
  void deactivate() {
    _detachFromParent();
    super.deactivate();
  }

  @override
  void unmount() {
    for (var component in components) {
      if (component is LifecycleListener) {
        component.onUnmounted();
      }
    }
    super.unmount();
    const UnmountedEvent().dispatchTo(this);
  }

  void _attachToParent() {
    _detachFromParent();
    _parentObject = _findParentGameObject(this);
    _parentObject?.internalChildrenObjects.add(this);
  }

  void _detachFromParent() {
    _parentObject?.internalChildrenObjects.remove(this);
    _parentObject = null;
  }

  GameObject? _findParentGameObject(Element element) {
    GameObject? found;
    element.visitAncestorElements((ancestor) {
      if (ancestor is GameObject) {
        found = ancestor as GameObject;
        return false;
      }
      return true;
    });
    return found;
  }
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
    child.parentData = GameParentData();
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    return constraints.constrain(
      object.tryGetComponent<ObjectSize>()?.size ?? Size.infinite,
    );
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return object.tryGetComponent<ObjectSize>()?.size.height ?? 0;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return object.tryGetComponent<ObjectSize>()?.size.width ?? 0;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return object.tryGetComponent<ObjectSize>()?.size.height ?? 0;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return object.tryGetComponent<ObjectSize>()?.size.width ?? 0;
  }

  @override
  void performLayout() {
    final objectSize = constraints.constrain(
      object.tryGetComponent<ObjectSize>()?.size ?? Size.infinite,
    );
    RenderObject? child = firstChild;
    while (child != null) {
      child.layout(BoxConstraints.tight(objectSize));
      child = (child.parentData as GameParentData).nextSibling;
    }
    size = objectSize;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final optionalTransform = object.tryGetComponent<ObjectTransform>();
    if (optionalTransform != null) {
      layer = context.pushTransform(
        needsCompositing,
        offset,
        optionalTransform.localMatrix,
        (context, offset) {
          RenderEvent(context.canvas).dispatchTo(object);
          defaultPaint(context, offset);
        },
      );
    } else {
      context.canvas.save();
      context.canvas.translate(offset.dx, offset.dy);
      RenderEvent(context.canvas).dispatchTo(object);
      context.canvas.restore();
      defaultPaint(context, offset);
    }
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final optionalTransform = object.tryGetComponent<ObjectTransform>();
    if (optionalTransform != null) {
      return result.addWithPaintTransform(
        transform: optionalTransform.localMatrix,
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
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  bool hitTestSelf(Offset position) {
    for (var component in object.getComponents<Collider>()) {
      if (component.contains(position)) {
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

class GameScene extends StatelessWidget {
  final Widget child;
  const GameScene({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(child: GameTicker(child: child));
  }
}
