import 'dart:collection';
import 'package:flutter/widgets.dart';
import 'package:goo2d/src/game.dart';
import 'package:goo2d/src/coroutine.dart';
import 'package:goo2d/src/event.dart';
import 'package:goo2d/src/lifecycle.dart';
import 'package:goo2d/src/object.dart';
import 'package:goo2d/src/component.dart';
import 'package:goo2d/src/input.dart';
import 'package:goo2d/src/widget.dart';
import 'package:goo2d/src/render.dart';

/// A concrete implementation of [GameObject] that integrates with
/// the Flutter element tree.
///
/// It implements both state management (like [StatefulElement]) and
/// multi-child reconciliation (like [MultiChildRenderObjectElement]).
class GameObjectElement extends RenderObjectElement implements GameObject {
  /// Creates a [GameObjectElement] for the given [widget].
  GameObjectElement(GameObjectWidget super.widget);

  final Map<Type, Component> _components = {};
  final List<CoroutineFuture> _runningCoroutines = [];
  GameObject? _parentObject;
  GameEngine? _game;

  GameState? _state;
  List<Element> _children = const <Element>[];
  final HashSet<Element> _forgottenChildren = HashSet<Element>();

  int _layer = RenderLayer.defaultLayer;

  @override
  GameEngine get game {
    if (_game == null) {
      throw StateError('GameObjectElement is not mounted to a GameEngine.');
    }
    return _game!;
  }

  @override
  bool get active => mounted;

  @override
  GameTag? get tag => widget.key is GameTag ? widget.key as GameTag : null;

  @override
  GameObject? get parentObject => _parentObject;

  @override
  Iterable<GameObject> get childrenObjects {
    final collected = <GameObject>[];
    for (var element in _children) {
      _collectFirstDepthGameObject(element, collected);
    }
    return collected;
  }

  void _collectFirstDepthGameObject(Element e, List<GameObject> collector) {
    if (e is GameObject) {
      collector.add(e as GameObject);
    } else {
      e.visitChildren((e) => _collectFirstDepthGameObject(e, collector));
    }
  }

  @override
  Iterable<Component> get components => _components.values;

  /// The [GameState] currently associated with this element.
  GameState? get state => _state;

  void _addComponentInternal(Component component) {
    assert(!component.isAttached, 'Component is already attached to ${component.isAttached ? component.gameObject : "another object"}.');
    assert(component is! GameState || _state == component, 'GameState components are managed by the engine and cannot be added manually.');
    component.internalAttach(this);
    _components[component.runtimeType] = component;
    if (active && component is LifecycleListener) {
      component.onMounted();
    }
  }

  @override
  void addComponent(
    GameComponent component, [
    GameComponent? a,
    GameComponent? b,
    GameComponent? c,
    GameComponent? d,
    GameComponent? e,
    GameComponent? f,
    GameComponent? g,
    GameComponent? h,
    GameComponent? i,
    GameComponent? j,
  ]) {
    _addComponentInternal(internalCreateComponent(component));
    if (a != null) _addComponentInternal(internalCreateComponent(a));
    if (b != null) _addComponentInternal(internalCreateComponent(b));
    if (c != null) _addComponentInternal(internalCreateComponent(c));
    if (d != null) _addComponentInternal(internalCreateComponent(d));
    if (e != null) _addComponentInternal(internalCreateComponent(e));
    if (f != null) _addComponentInternal(internalCreateComponent(f));
    if (g != null) _addComponentInternal(internalCreateComponent(g));
    if (h != null) _addComponentInternal(internalCreateComponent(h));
    if (i != null) _addComponentInternal(internalCreateComponent(i));
    if (j != null) _addComponentInternal(internalCreateComponent(j));
  }

  void _removeComponentInternal(Component component) {
    assert(component is! GameState, 'GameState components are managed by the engine and cannot be removed manually.');
    assert(component.gameObject == this, 'Cannot remove component that is not attached to this GameObject');
    if (_components.remove(component.runtimeType) != null) {
      _onComponentRemoved(component);
    }
  }

  void _onComponentRemoved(Component component) {
    if (active && component is LifecycleListener) {
      component.onUnmounted();
    }
    component.internalDetach();
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
  void removeComponentOfExactType(
    Type type, [
    Type? a,
    Type? b,
    Type? c,
    Type? d,
    Type? e,
    Type? f,
    Type? g,
    Type? h,
    Type? i,
    Type? j,
  ]) {
    _removeExactTypeInternal(type);
    if (a != null) _removeExactTypeInternal(a);
    if (b != null) _removeExactTypeInternal(b);
    if (c != null) _removeExactTypeInternal(c);
    if (d != null) _removeExactTypeInternal(d);
    if (e != null) _removeExactTypeInternal(e);
    if (f != null) _removeExactTypeInternal(f);
    if (g != null) _removeExactTypeInternal(g);
    if (h != null) _removeExactTypeInternal(h);
    if (i != null) _removeExactTypeInternal(i);
    if (j != null) _removeExactTypeInternal(j);
  }

  void _removeExactTypeInternal(Type type) {
    final component = _components.remove(type);
    if (component != null) {
      _onComponentRemoved(component);
    }
  }

  @override
  void removeComponentOfType<T extends Component>() {
    final removed = <Component>[];
    _components.removeWhere((type, component) {
      if (component is T) {
        removed.add(component);
        return true;
      }
      return false;
    });
    for (final component in removed) {
      _onComponentRemoved(component);
    }
  }

  @override
  void removeComponents(Iterable<Type> types) {
    final typeSet = types.toSet();
    final removed = <Component>[];
    _components.removeWhere((type, component) {
      if (typeSet.contains(type)) {
        removed.add(component);
        return true;
      }
      return false;
    });
    for (final component in removed) {
      _onComponentRemoved(component);
    }
  }

  @override
  void addComponents(Iterable<GameComponent> components) {
    for (var component in components) {
      _addComponentInternal(internalCreateComponent(component));
    }
  }

  @override
  void removeComponentAt(int index) {
    final component = _components.values.elementAt(index);
    _removeComponentInternal(component);
  }

  @override
  void removeAllComponents() {
    _components.forEach((type, component) => _onComponentRemoved(component));
    _components.clear();
  }

  @override
  void sendEvent(Event event) {
    for (final element in _children) {
      _sendEventDown(event, element);
    }
  }

  void _sendEventDown(Event event, Element element) {
    if (element is GameObject) {
      event.dispatchTo(element as GameObject);
    } else {
      element.visitChildren((e) => _sendEventDown(event, e));
    }
  }

  @override
  void broadcastEvent(Event event) {
    event.dispatchTo(this);
    sendEvent(event);
  }

  @override
  T getComponent<T extends Component>() {
    final component = tryGetComponent<T>();
    if (component == null) {
      throw StateError('Component of type $T not found on object $name');
    }
    return component;
  }

  @override
  T? tryGetComponent<T extends Component>() {
    final exact = _components[T];
    if (exact != null) return exact as T;
    for (var component in _components.values) {
      if (component is T) return component;
    }
    return null;
  }

  @override
  Iterable<T> getComponents<T extends Component>() {
    return _components.values.whereType<T>();
  }

  @override
  T getComponentInChildren<T extends Component>() {
    final component = tryGetComponentInChildren<T>();
    if (component == null) {
      throw StateError('Component of type $T not found in children of $name');
    }
    return component;
  }

  @override
  T? tryGetComponentInChildren<T extends Component>() {
    final self = tryGetComponent<T>();
    if (self != null) return self;
    for (var child in _children) {
      final found = _tryToGetComponentInChildren<T>(child);
      if (found != null) return found;
    }
    return null;
  }

  T? _tryToGetComponentInChildren<T extends Component>(Element e) {
    if (e is GameObject) {
      return (e as GameObject).tryGetComponentInChildren<T>();
    } else {
      T? result;
      e.visitChildren((e) {
        result ??= _tryToGetComponentInChildren<T>(e);
      });
      return result;
    }
  }

  @override
  Iterable<T> getComponentsInChildren<T extends Component>() sync* {
    yield* _components.values.whereType<T>();
    List<T> collected = [];
    for (var child in _children) {
      _collectComponentsInChildren(child, collected);
    }
    yield* collected;
  }

  void _collectComponentsInChildren<T extends Component>(
    Element e,
    List<T> components,
  ) {
    if (e is GameObject) {
      components.addAll((e as GameObject).getComponents<T>());
    } else {
      e.visitChildren((e) => _collectComponentsInChildren<T>(e, components));
    }
  }

  @override
  T getComponentInParent<T extends Component>() {
    final component = tryGetComponentInParent<T>();
    if (component == null) {
      throw StateError('Component of type $T not found in parent of $name');
    }
    return component;
  }

  @override
  T? tryGetComponentInParent<T extends Component>() {
    GameObject? current = this;
    while (current != null) {
      final result = current.tryGetComponent<T>();
      if (result != null) return result;
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
        for (final child in current!.childrenObjects) {
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

    for (var child in _children) {
      final found = _findFirstDepthByName(child, name);
      if (found != null) {
        return found;
      }
    }
    for (var child in _children) {
      final found = _findFirstDepthByFinding(child, name);
      if (found != null) return found;
    }
    return null;
  }

  GameObject? _findFirstDepthByName(Element e, String name) {
    if (e is GameObject) {
      if ((e as GameObject).name == name) {
        return e as GameObject;
      }
      return null;
    } else {
      GameObject? result;
      e.visitChildren((e) {
        result ??= _findFirstDepthByName(e, name);
      });
      return result;
    }
  }

  GameObject? _findFirstDepthByFinding(Element e, String name) {
    if (e is GameObject) {
      return (e as GameObject).findChild(name);
    } else {
      GameObject? result;
      e.visitChildren((e) {
        result ??= _findFirstDepthByName(e, name);
      });
      return result;
    }
  }

  @override
  String get name {
    final w = widget;
    if (w is GameObjectWidget) {
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
  void visitChildren(ElementVisitor visitor) {
    for (final Element child in _children) {
      if (!_forgottenChildren.contains(child)) {
        visitor(child);
      }
    }
  }

  @override
  void forgetChild(Element child) {
    assert(_children.contains(child));
    assert(!_forgottenChildren.contains(child));
    _forgottenChildren.add(child);
    super.forgetChild(child);
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    _game = parent?.dependOnInheritedWidgetOfExactType<GameProvider>()?.game;
    _attachToParent();
    _layer = (widget as GameObjectWidget).layer;

    _state = (widget as GameObjectWidget).createState();
    if (_state != null) {
      _state!._element = this;
      _addComponentInternal(_state!);
      _state!.initState();
      _state!.didChangeDependencies();
    }

    final widgets = _state?.build(this).toList() ?? const <Widget>[];
    final List<Element> children = <Element>[];
    Element? previousChild;
    for (var i = 0; i < widgets.length; i += 1) {
      final Element newChild = inflateWidget(
        widgets[i],
        IndexedSlot<Element?>(i, previousChild),
      );
      children.add(newChild);
      previousChild = newChild;
    }
    _children = children;
  }

  @override
  void update(GameObjectWidget newWidget) {
    final oldWidget = widget as GameObjectWidget;
    super.update(newWidget);
    _layer = newWidget.layer;
    if (_state != null) {
      _state!.didUpdateWidget(oldWidget);
    }
    markNeedsBuild();
    rebuild();
  }

  @override
  void performRebuild() {
    _rebuild();
    super.performRebuild();
  }

  @override
  void reassemble() {
    _state?.reassemble();
    super.reassemble();
    broadcastEvent(HotReloadEvent());
  }

  void _rebuild() {
    final widgets = _state?.build(this).toList() ?? const <Widget>[];
    _children = updateChildren(
      _children,
      widgets,
      forgottenChildren: _forgottenChildren,
    );
    _forgottenChildren.clear();
  }

  void _attachToParent() {
    _detachFromParent();
    _parentObject = _findParentGameObject(this);
    if (_parentObject == null) {
      _game?.registerRootObject(this);
    }
  }

  void _detachFromParent() {
    if (_parentObject == null) {
      _game?.unregisterRootObject(this);
    }
  }

  GameObject? _findParentGameObject(Element element) {
    GameObject? found;
    element.visitAncestorElements((parent) {
      if (parent is GameObject) {
        found = parent as GameObject;
        return false;
      }
      return true;
    });
    return found;
  }

  @override
  void unmount() {
    _components.forEach((type, component) => _onComponentRemoved(component));
    _components.clear();
    _state?.dispose();
    _state?._element = null;
    _state = null;
    stopAllCoroutines();
    _detachFromParent();
    super.unmount();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _state?.didChangeDependencies();
  }

  @override
  void insertRenderObjectChild(RenderObject child, IndexedSlot<Element?> slot) {
    final renderObject = this.renderObject as GameRenderObject;
    renderObject.insert(
      child as RenderBox,
      after: slot.value?.renderObject as RenderBox?,
    );
  }

  @override
  void moveRenderObjectChild(
    RenderObject child,
    IndexedSlot<Element?> oldSlot,
    IndexedSlot<Element?> newSlot,
  ) {
    final renderObject = this.renderObject as GameRenderObject;
    renderObject.move(
      child as RenderBox,
      after: newSlot.value?.renderObject as RenderBox?,
    );
  }

  @override
  void removeRenderObjectChild(RenderObject child, Object? slot) {
    final renderObject = this.renderObject as GameRenderObject;
    renderObject.remove(child as RenderBox);
  }

  @override
  Future<void> startCoroutine(CoroutineFunction coroutine) {
    final future = CoroutineFuture(coroutine);
    setupCoroutine(future, coroutine(), _runningCoroutines);
    return future;
  }

  @override
  Future<void> startCoroutineWithOption<T>(
    CoroutineFunctionWithOptions<T> coroutine, {
    required T option,
  }) {
    final future = CoroutineFuture(coroutine);
    setupCoroutine(future, coroutine(option), _runningCoroutines);
    return future;
  }

  @override
  void stopCoroutine(Future<void> coroutine) {
    if (coroutine is CoroutineFuture) {
      _runningCoroutines.remove(coroutine);
    }
  }

  @override
  void stopAllCoroutines([Function? coroutine]) {
    if (coroutine != null) {
      _runningCoroutines.removeWhere((e) => e.coroutine == coroutine);
    } else {
      _runningCoroutines.clear();
    }
  }
}

/// The logic and internal state for a [StatefulGameWidget].
abstract class GameState<T extends GameObjectWidget> extends Component {
  GameObjectElement? _element;
  final List<InputAction> _trackedInputActions = [];

  @override
  GameObject get gameObject => _element!;

  /// The widget configuration currently associated with this state.
  T get widget => _element!.widget as T;

  /// The location in the scene graph where this state is mounted.
  BuildContext get context => _element!;

  /// Whether the state is currently mounted in the scene graph.
  bool get mounted => _element != null;

  /// Helper method to create and track an [InputAction] tied to this state's lifecycle.
  InputAction createInputAction({
    required String name,
    InputActionType type = InputActionType.value,
    List<InputBinding> bindings = const [],
    bool enable = true,
  }) {
    final action = InputAction(
      game: game,
      name: name,
      type: type,
      bindings: bindings,
    );
    _trackedInputActions.add(action);
    if (enable) action.enable();
    return action;
  }

  /// Notifies the engine that the internal state has changed.
  void setState(VoidCallback fn) {
    assert(_element != null, 'Cannot call setState on an unmounted widget');
    fn();
    _element!.markNeedsBuild();
  }

  /// Called when this object is inserted into the scene graph.
  @mustCallSuper
  void initState() {}

  /// Called whenever the widget configuration changes.
  @mustCallSuper
  void didUpdateWidget(T oldWidget) {}

  /// Called when a dependency of this state changes.
  @mustCallSuper
  void didChangeDependencies() {}

  /// Called during hot reload to re-initialize state.
  @mustCallSuper
  void reassemble() {}

  /// Called when this object is removed from the scene graph.
  @mustCallSuper
  void dispose() {
    for (var action in _trackedInputActions) {
      action.dispose();
    }
    _trackedInputActions.clear();
  }

  /// Returns a collection of child widgets to be rendered as part of this object.
  Iterable<Widget> build(BuildContext context) => const [];
}

/// Typedef for [GameObjectElement] for backward compatibility.
typedef GameElement = GameObjectElement;
