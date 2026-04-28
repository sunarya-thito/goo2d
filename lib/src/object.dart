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
  String get name;
  GameEngine get game;
  GameTag? get tag;
  bool get active;
  GameObject get rootObject;
  GameObject? get parentObject;
  Iterable<GameObject> get childrenObjects;
  Iterable<Component> get components;

  /// The rendering layer of this object.
  int get layer;
  set layer(int value);

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
  T getComponentInChildren<T extends Component>();
  T? tryGetComponentInChildren<T extends Component>();
  Iterable<T> getComponentsInParent<T extends Component>();

  GameObject? findChild(String name);

  static GameObject? find(BuildContext context, String name) {
    final engine = GameEngine.of(context);
    final isAbsolute = name.startsWith('/');
    final path = isAbsolute ? name.substring(1) : name;
    final parts = path.split('/');

    for (final root in engine.rootObjects) {
      // Check if root matches first part
      if (root.name == parts[0]) {
        if (parts.length == 1) return root;
        final found = root.findChild(path.substring(parts[0].length + 1));
        if (found != null) return found;
      }

      // If not absolute, search for first part deep
      if (!isAbsolute) {
        final foundStart = root.findChild(parts[0]);
        if (foundStart != null) {
          if (parts.length == 1) return foundStart;
          final foundFull = foundStart.findChild(
            path.substring(parts[0].length + 1),
          );
          if (foundFull != null) return foundFull;
        }
      }
    }
    return null;
  }

  static GameObject? findWithTag(BuildContext context, GameTag tag) {
    return tag.gameObject;
  }

  static Iterable<GameObject> findGameObjectsWithTag(
    BuildContext context,
    GameTag tag,
  ) {
    final engine = GameEngine.of(context);
    return engine.rootObjects.expand((e) => _findAllWithTag(e, tag));
  }

  static Iterable<GameObject> _findAllWithTag(GameObject root, GameTag tag) {
    final result = <GameObject>[];
    if (root.tag == tag) result.add(root);
    for (final child in root.childrenObjects) {
      result.addAll(_findAllWithTag(child, tag));
    }
    return result;
  }

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

  int _layer = RenderLayer.defaultLayer;
  GameObjectElement(super.widget);

  @override
  void reassemble() {
    super.reassemble();
  }

  @override
  String get name {
    final w = widget;
    if (w is GameWidget) {
      return w.name ?? w.runtimeType.toString();
    }
    return w.runtimeType.toString();
  }

  @override
  int get layer => _layer;

  @override
  set layer(int value) {
    if (_layer == value) return;
    _layer = value;
    if (mounted) {
      renderObject.markNeedsPaint();
    }
  }

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
  T getComponentInChildren<T extends Component>() {
    final result = tryGetComponentInChildren<T>();
    if (result != null) return result;
    throw Exception('Component $T not found in children of $this');
  }

  @override
  T? tryGetComponentInChildren<T extends Component>() {
    final self = tryGetComponent<T>();
    if (self != null) return self;
    for (final child in childrenObjects) {
      final found = child.tryGetComponentInChildren<T>();
      if (found != null) return found;
    }
    return null;
  }

  @override
  T getComponentInParent<T extends Component>() {
    T? result = tryGetComponentInParent<T>();
    if (result != null) {
      return result;
    }
    throw Exception('Component $T not found in parent of $this');
  }

  @override
  T? tryGetComponentInParent<T extends Component>() {
    GameObject? current = this;
    while (current != null) {
      T? result = current.tryGetComponent<T>();
      if (result != null) {
        return result;
      }
      current = current.parentObject;
    }
    return null;
  }

  @override
  Iterable<T> getComponentsInParent<T extends Component>() sync* {
    GameObject? current = this;
    while (current != null) {
      yield* current.getComponents<T>();
      current = current.parentObject;
    }
  }

  @override
  GameObject? findChild(String name) {
    if (name.contains('/')) {
      final parts = name.split('/');
      GameObject? current = this;
      for (final part in parts) {
        GameObject? next;
        for (final child in current!.internalChildrenObjects) {
          if (child.name == part) {
            next = child;
            break;
          }
        }
        if (next == null) return null;
        current = next;
      }
      return current;
    }

    for (final child in _childrenObjects) {
      if (child.name == name) return child;
    }
    for (final child in _childrenObjects) {
      final found = child.findChild(name);
      if (found != null) return found;
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
    _game = parent?.dependOnInheritedWidgetOfExactType<GameProvider>()?.game;
    _attachToParent();
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
    if (_parentObject != null) {
      _parentObject?.internalChildrenObjects.add(this);
    } else {
      _game?.registerRootObject(this);
    }
  }

  void _detachFromParent() {
    if (_parentObject != null) {
      _parentObject?.internalChildrenObjects.remove(this);
    } else {
      _game?.unregisterRootObject(this);
    }
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
  final int layer;
  final String? name;

  const GameWidget({
    super.key,
    this.children = const [],
    this.components = _emptyComponents,
    this.layer = RenderLayer.defaultLayer,
    this.name,
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
    layer = widget.layer;
    final components = widget.components();
    for (var component in components) {
      addComponent(component);
    }
    updateChildElements(widget.children);
  }

  @override
  void update(GameWidget newWidget) {
    layer = newWidget.layer;
    super.update(newWidget);
    _refreshComponents();
    updateChildElements(newWidget.children);
  }

  @override
  void reassemble() {
    super.reassemble();
    for (final component in _components) {
      component.onHotReload();
    }
  }

  void _refreshComponents() {
    final newComponents = widget.components().toList();
    for (final newComp in newComponents) {
      final existing = _components
          .where((c) => c.runtimeType == newComp.runtimeType)
          .firstOrNull;
      if (existing == null) {
        addComponent(newComp);
      } else {
        _patchComponent(existing, newComp);
      }
    }
  }

  void _patchComponent(Component existing, Component newComp) {
    if (existing is Camera && newComp is Camera) {
      existing.backgroundColor = newComp.backgroundColor;
      existing.orthographicSize = newComp.orthographicSize;
      existing.depth = newComp.depth;
      existing.cullingMask = newComp.cullingMask;
      existing.clearFlags = newComp.clearFlags;
      existing.nearClipPlane = newComp.nearClipPlane;
      existing.farClipPlane = newComp.farClipPlane;
    } else if (existing is SpriteRenderer && newComp is SpriteRenderer) {
      existing.sprite = newComp.sprite;
      existing.color = newComp.color;
      existing.flipX = newComp.flipX;
      existing.flipY = newComp.flipY;
      existing.filterQuality = newComp.filterQuality;
      existing.blendMode = newComp.blendMode;
    }
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
    final transform = object.tryGetComponent<ObjectTransform>();
    if (transform != null) {
      return transform.getSize(constraints);
    }
    return constraints.constrain(Size.infinite);
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return object.tryGetComponent<ObjectTransform>()?.computeMaxIntrinsicHeight(width) ?? 0;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return object.tryGetComponent<ObjectTransform>()?.computeMaxIntrinsicWidth(height) ?? 0;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return object.tryGetComponent<ObjectTransform>()?.computeMinIntrinsicHeight(width) ?? 0;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return object.tryGetComponent<ObjectTransform>()?.computeMinIntrinsicWidth(height) ?? 0;
  }

  @override
  void performLayout() {
    final transform = object.tryGetComponent<ObjectTransform>();
    final objectSize = transform?.getSize(constraints) ?? constraints.constrain(Size.infinite);
    final childConstraints = transform?.getChildConstraints(constraints) ?? constraints.loosen();
    
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
      // No transform. Render at the current offset.
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

    // No transform. Hit-test at the current position.
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
