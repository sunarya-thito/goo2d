import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:goo2d/goo2d.dart';
import 'package:goo2d/src/component.dart';
import 'package:meta/meta.dart';
import 'game.dart';
import 'coroutine.dart';

class GameTag extends GlobalObjectKey {
  const GameTag(super.value);

  GameObject? get gameObject => currentContext as GameObject?;
}

abstract class GameObject implements BuildContext {
  GameEngine get game;
  GameTag? get tag;
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

  Future<void> startCoroutine(CoroutineFunction coroutine);
  Future<void> startCoroutineWithOption<T>(
    CoroutineFunctionWithOptions<T> coroutine, {
    required T option,
  });
  void stopCoroutine(Future<void> coroutine);
  void stopAllCoroutines([Function? coroutine]);

  @internal
  List<GameObject> get internalChildrenObjects;

  @internal
  set internalParentObject(GameObject? value);
}

abstract class GameObjectElement extends RenderObjectElement
    implements GameObject {
  final List<Component> _components = [];
  final List<GameObject> _childrenObjects = [];
  final List<CoroutineFuture> _runningCoroutines = [];
  GameObject? _parentObject;
  List<Element> _childElements = [];
  GameEngine? _game;

  GameObjectElement(super.widget);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _game = dependOnInheritedWidgetOfExactType<GameProvider>()?.game;
  }

  @override
  GameEngine get game {
    return _game!;
  }

  @override
  bool get active => mounted;

  @override
  GameTag? get tag => widget.key is GameTag ? widget.key as GameTag : null;

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
    final component = tryGetComponent<T>();
    if (component == null) {
      throw StateError(
        'GameObject "$this" does not have a component of type $T',
      );
    }
    return component;
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

  @override
  Future<void> startCoroutine(CoroutineFunction coroutine) {
    CoroutineFuture result = CoroutineFuture(coroutine);
    setupCoroutine(result, coroutine(), _runningCoroutines);
    return result;
  }

  @override
  Future<void> startCoroutineWithOption<T>(
    CoroutineFunctionWithOptions<T> coroutine, {
    required T option,
  }) {
    CoroutineFuture result = CoroutineFuture(coroutine);
    setupCoroutine(result, coroutine(option), _runningCoroutines);
    return result;
  }

  @override
  void stopCoroutine(Future<void> coroutine) {
    _runningCoroutines.remove(coroutine);
  }

  @override
  void stopAllCoroutines([Function? coroutine]) {
    if (coroutine != null) {
      _runningCoroutines.removeWhere((e) => e.coroutine == coroutine);
    } else {
      _runningCoroutines.clear();
    }
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    _attachToParent();
    _game = parent?.dependOnInheritedWidgetOfExactType<GameProvider>()?.game;
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    for (final child in _childElements) {
      visitor(child);
    }
  }

  @override
  void forgetChild(Element child) {
    _childElements.remove(child);
    super.forgetChild(child);
  }

  @protected
  void updateChildElements(List<Widget> newWidgets) {
    _childElements = updateChildren(_childElements, newWidgets);
  }

  @override
  void insertRenderObjectChild(RenderObject child, Object? slot) {
    final renderObject = this.renderObject as GameRenderObject;
    final Element? afterElement = (slot as IndexedSlot<Element?>?)?.value;
    renderObject.insert(
      child as RenderBox,
      after: afterElement?.renderObject as RenderBox?,
    );
  }

  @override
  void moveRenderObjectChild(
    RenderObject child,
    Object? oldSlot,
    Object? newSlot,
  ) {
    final renderObject = this.renderObject as GameRenderObject;
    final Element? afterElement = (newSlot as IndexedSlot<Element?>?)?.value;
    renderObject.move(
      child as RenderBox,
      after: afterElement?.renderObject as RenderBox?,
    );
  }

  @override
  void removeRenderObjectChild(RenderObject child, Object? slot) {
    final renderObject = this.renderObject as GameRenderObject;
    renderObject.remove(child as RenderBox);
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
    const UnmountedEvent().dispatchTo(this);
    stopAllCoroutines();
    super.unmount();
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

class GameWidget extends RenderObjectWidget {
  static List<Component> _emptyComponents() {
    return [];
  }

  final List<Widget> children;
  final Iterable<Component> Function() components;

  const GameWidget({
    super.key,
    this.children = const [],
    this.components = _emptyComponents,
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

class GameElement extends GameObjectElement {
  GameElement(GameWidget super.widget);

  @override
  GameWidget get widget => super.widget as GameWidget;

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    final components = widget.components();
    for (var component in components) {
      addComponent(component);
    }
    updateChildElements(widget.children);
  }

  @override
  void update(GameWidget newWidget) {
    super.update(newWidget);
    updateChildElements(newWidget.children);
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
      child.layout(BoxConstraints.loose(objectSize));
      child = (child.parentData as GameParentData).nextSibling;
    }
    size = objectSize.isInfinite ? Size.zero : objectSize;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final optionalTransform = object.tryGetComponent<ObjectTransform>();

    if (optionalTransform != null) {
      if (object.game.isSecondaryPass || !needsCompositing) {
        context.canvas.save();
        context.canvas.translate(offset.dx, offset.dy);
        context.canvas.transform(optionalTransform.localMatrix.storage);
        RenderEvent(context.canvas).dispatchTo(object);
        defaultPaint(context, Offset.zero);
        context.canvas.restore();
      } else {
        layer = context.pushTransform(
          needsCompositing,
          offset,
          optionalTransform.localMatrix,
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
    final optionalTransform = object.tryGetComponent<ObjectTransform>();
    if (optionalTransform != null) {
      return result.addWithPaintTransform(
        transform: optionalTransform.localMatrix,
        position: position,
        hitTest: (BoxHitTestResult result, Offset? transformedPosition) {
          if (transformedPosition == null) return false;
          return defaultHitTestChildren(result, position: transformedPosition);
        },
      );
    }
    return defaultHitTestChildren(result, position: position);
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
  bool hitTestSelf(Offset position) {
    for (var component in object.getComponents<CollisionTrigger>()) {
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
