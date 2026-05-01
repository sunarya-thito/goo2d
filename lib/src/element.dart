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
/// [GameObjectElement] acts as the bridge between the declarative Flutter
/// UI and the imperative game engine logic. It manages a collection of
/// [Component]s and handles the lifecycle of the object within the scene graph.
///
/// Why: Flutter's element tree is the source of truth for widget hierarchy,
/// and [GameObjectElement] leverages this to provide automatic parenting
/// and resource management for game objects.
///
/// How: By extending [RenderObjectElement], it participates in the layout
/// and paint phases while exposing a high-level API for component management
/// and coroutine execution.
///
/// ```dart
/// final element = GameObjectElement(myWidget);
/// element.addComponent(SpriteRenderer(sprite));
/// ```
class GameObjectElement extends RenderObjectElement implements GameObject {
  /// Creates a [GameObjectElement] for the given [widget].
  ///
  /// This constructor initializes the element within the Flutter framework
  /// and prepares it for mounting into the game's scene graph.
  ///
  /// Why: Every game object needs a reference to its configuration widget
  /// to correctly handle updates and lifecycle events.
  ///
  /// How: The widget is passed to the super constructor, and the engine
  /// later populates the game and parent references during the mount phase.
  ///
  /// * [widget]: The configuration widget for this game object.
  GameObjectElement(GameWidget super.widget);

  final List<Component> _components = [];
  final List<CoroutineFuture> _runningCoroutines = [];
  GameObject? _parentObject;
  GameEngine? _game;

  final List<Component> _deferredLifecycleComponents = [];
  bool _isMounting = false;

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
  Iterable<Component> get components => _components;

  /// The [GameState] currently associated with this element.
  GameState? get state => _state;

  void _addComponentInternal(Component component) {
    assert(
      !component.isAttached,
      'Component is already attached to ${component.isAttached ? component.gameObject : "another object"}.',
    );
    assert(
      component is! GameState || _state == component,
      'GameState components are managed by the engine and cannot be added manually.',
    );

    // Add component
    component.internalAttach(this);
    _components.add(component);
    if (!_isMounting) {
      _checkSingleInstanceConflict(component);
    }

    if (active && component is LifecycleListener) {
      if (_isMounting) {
        _deferredLifecycleComponents.add(component);
      } else {
        component.onMounted();
      }
    }
  }

  void _checkSingleInstanceConflict(Component component) {
    if (component is! MultiComponent) {
      final type = component.runtimeType;
      for (var c in _components) {
        if (c != component && c.runtimeType == type) {
          throw AssertionError(
            'Only one component of type $type is allowed on GameObject "$name". '
            'To allow multiple instances, the component must implement MultiComponent.',
          );
        }
      }
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

  void _removeComponentInternal(Component component) {
    assert(
      component is! GameState,
      'GameState components are managed by the engine and cannot be removed manually.',
    );
    if (component.tryGameObject != this) return;
    if (_components.remove(component)) {
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
    final toRemove = _components.where((c) => c.runtimeType == type).toList();
    for (final c in toRemove) {
      _components.remove(c);
      _onComponentRemoved(c);
    }
  }

  @override
  void removeComponentOfType<T extends Component>() {
    final removed = <Component>[];
    _components.removeWhere((component) {
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
    _components.removeWhere((component) {
      if (typeSet.contains(component.runtimeType)) {
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
  void addComponents(Iterable<Component> components) {
    for (var component in components) {
      _addComponentInternal(component);
    }
  }

  @override
  void removeComponentAt(int index) {
    final component = _components[index];
    _removeComponentInternal(component);
  }

  @override
  void removeAllComponents() {
    final toRemove = List<Component>.from(_components);
    for (final component in toRemove) {
      if (component is! GameState) {
        _onComponentRemoved(component);
        _components.remove(component);
      }
    }
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
    for (var component in _components) {
      if (component is T) return component;
    }
    return null;
  }

  @override
  Iterable<T> getComponents<T extends Component>() {
    return _components.whereType<T>();
  }

  @override
  bool hasComponent<T extends Component>() => tryGetComponent<T>() != null;

  @override
  bool hasComponentOfType(Type type) {
    for (var c in _components) {
      if (c.runtimeType == type) return true;
    }
    return false;
  }

  @override
  Component getComponentAt(int index) => _components[index];

  @override
  int getComponentsCount() => _components.length;

  @override
  List<T> getComponentsOfType<T extends Component>() =>
      _components.whereType<T>().toList();

  @override
  int getComponentIndex(Component component) => _components.indexOf(component);

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
    yield* _components.whereType<T>();
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
    _isMounting = true;
    super.mount(parent, newSlot);
    _game = parent?.dependOnInheritedWidgetOfExactType<GameProvider>()?.game;
    _attachToParent();
    _layer = (widget as GameWidget).layer;

    _state = (widget as GameWidget).createState();
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
    _finalizeMount();
  }

  void _finalizeMount() {
    _isMounting = false;

    // Check for single instance conflicts that might have persisted after the build.
    final Set<Type> seenTypes = {};
    for (final component in _components) {
      if (component is! MultiComponent) {
        if (seenTypes.contains(component.runtimeType)) {
          throw AssertionError(
            'Only one component of type ${component.runtimeType} is allowed on GameObject "$name". '
            'To allow multiple instances, the component must implement MultiComponent.',
          );
        }
        seenTypes.add(component.runtimeType);
      }
    }

    for (final component in _deferredLifecycleComponents) {
      if (component is LifecycleListener) {
        component.onMounted();
      }
    }
    _deferredLifecycleComponents.clear();
  }

  @override
  void update(GameWidget newWidget) {
    final oldWidget = widget as GameWidget;
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
    _isMounting = true;
    final widgets = _state?.build(this).toList() ?? const <Widget>[];
    _children = updateChildren(
      _children,
      widgets,
      forgottenChildren: _forgottenChildren,
    );
    _forgottenChildren.clear();
    _finalizeMount();
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
    for (final component in _components) {
      _onComponentRemoved(component);
    }
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
abstract class GameState<T extends GameWidget> extends Component {
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
