import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:goo2d/goo2d.dart';
import 'package:goo2d/src/component.dart';
import 'package:meta/meta.dart';
import 'game.dart';
import 'coroutine.dart';

/// A globally unique identifier for a [GameObject], used for searching.
/// 
/// [GameTag] is a specialized [GlobalObjectKey] that allows retrieving 
/// the associated [GameObject] directly from its context. This is 
/// primarily used for finding unique objects like 'MainCamera' or 'Player' 
/// across the scene hierarchy.
/// 
/// ```dart
/// const playerTag = GameTag('Player');
/// final player = playerTag.gameObject;
/// ```
class GameTag extends GlobalObjectKey {
  /// Creates a [GameTag] with the given [value].
  /// 
  /// Wraps the value in a global key that can be used to identify 
  /// objects across the entire application.
  /// 
  /// * [value]: The unique string or object identifier.
  const GameTag(super.value);

  /// Returns the [GameObject] associated with this tag, if it exists.
  /// 
  /// Performs a lookup in the global element registry to find the 
  /// mounted element corresponding to this key.
  GameObject? get gameObject => currentContext as GameObject?;
}

/// The core interface for all objects in the Goo2D scene hierarchy.
///
/// [GameObject] extends Flutter's [BuildContext], allowing it to participate 
/// in the widget tree while providing game-specific functionality like 
/// component management, hierarchical searches, and event broadcasting.
///
/// Every object in Goo2D is a [GameObject]. They act as containers for 
/// [Component]s, which define the object's actual behavior and appearance.
/// Objects are organized in a parent-child tree, where child objects 
/// inherit the transformations and lifecycle of their parents.
///
/// ```dart
/// // Finding an object by name
/// final player = GameObject.find(context, 'Player');
/// 
/// // Adding a component
/// player?.addComponent(SpriteRenderer(sprite: mySprite));
/// ```
abstract class GameObject implements BuildContext {
  /// The user-defined name of this object.
  /// 
  /// Used for identifying the object in the editor or during 
  /// runtime searches via [GameObject.find].
  String get name;

  /// The [GameEngine] instance this object belongs to.
  /// 
  /// Provides access to core systems like input, physics, and rendering.
  GameEngine get game;

  /// The unique [GameTag] assigned to this object, if any.
  /// 
  /// Allows global lookup of this object via the tag's [GameTag.gameObject] 
  /// property.
  GameTag? get tag;

  /// Whether this object is currently mounted and active in the scene.
  /// 
  /// Inactive objects do not receive lifecycle updates or rendering calls.
  bool get active;

  /// The top-most [GameObject] in this object's hierarchy.
  /// 
  /// Usually the object that was directly added to the [GameEngine].
  GameObject get rootObject;

  /// The immediate parent of this object, or null if it is a root object.
  /// 
  /// Defines the local coordinate space and lifecycle of this object.
  GameObject? get parentObject;

  /// An unmodifiable collection of all immediate child [GameObject]s.
  /// 
  /// Iterating over children allows hierarchical processing of the scene.
  Iterable<GameObject> get childrenObjects;

  /// An unmodifiable collection of all [Component]s attached to this object.
  /// 
  /// Components define the data and behavior for this object.
  Iterable<Component> get components;

  /// The rendering layer this object belongs to.
  /// 
  /// Layers are used for culling and draw order management. Objects on 
  /// higher layers are typically rendered on top.
  int get layer;
  /// Updates the rendering layer this object belongs to.
  /// 
  /// * [value]: The new layer index.
  set layer(int value);

  /// Adds one or more components to this object.
  /// 
  /// Newly added components will be initialized during the next engine 
  /// update cycle.
  /// 
  /// * [component]: The primary component to add.
  /// * [a]: Optional additional component.
  /// * [b]: Optional additional component.
  /// * [c]: Optional additional component.
  /// * [d]: Optional additional component.
  /// * [e]: Optional additional component.
  /// * [f]: Optional additional component.
  /// * [g]: Optional additional component.
  /// * [h]: Optional additional component.
  /// * [i]: Optional additional component.
  /// * [j]: Optional additional component.
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

  /// Removes one or more components from this object.
  /// 
  /// Components will be detached and disposed during the next engine 
  /// update cycle.
  /// 
  /// * [component]: The primary component to remove.
  /// * [a]: Optional additional component.
  /// * [b]: Optional additional component.
  /// * [c]: Optional additional component.
  /// * [d]: Optional additional component.
  /// * [e]: Optional additional component.
  /// * [f]: Optional additional component.
  /// * [g]: Optional additional component.
  /// * [h]: Optional additional component.
  /// * [i]: Optional additional component.
  /// * [j]: Optional additional component.
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

  /// Recursively searches for all components of type [T] in children.
  /// 
  /// Traverses the entire child hierarchy and returns an iterable of all 
  /// matching components. This is an expensive operation.
  /// 
  /// * [T]: The type of component to search for.
  Iterable<T> getComponentsInChildren<T extends Component>();

  /// Finds the first component of type [T] in the parent hierarchy.
  /// 
  /// Walks up the tree towards the [rootObject] and returns the first 
  /// match. Throws a [StateError] if no component is found.
  /// 
  /// * [T]: The type of component to search for.
  T getComponentInParent<T extends Component>();

  /// Attempts to find a component of type [T] in the parent hierarchy.
  /// 
  /// Similar to [getComponentInParent] but returns null instead of 
  /// throwing if no match is found.
  /// 
  /// * [T]: The type of component to search for.
  T? tryGetComponentInParent<T extends Component>();

  /// Broadcasts an [event] to this object's components and all children.
  /// 
  /// Recursively notifies the entire subtree. This is useful for 
  /// system-wide notifications like 'LevelStarted' or 'GameOver'.
  /// 
  /// * [event]: The event to broadcast.
  void broadcastEvent(Event event);

  /// Dispatches an [event] to all immediate children.
  /// 
  /// Only notifies the direct descendants of this object. Useful for 
  /// localized messaging within a parent-child relationship.
  /// 
  /// * [event]: The event to send.
  void sendEvent(Event event);

  /// Finds the first component of type [T] attached to this object.
  /// 
  /// Searches the local [components] list. Throws a [StateError] if 
  /// the component is not found.
  /// 
  /// * [T]: The type of component to search for.
  T getComponent<T extends Component>();

  /// Attempts to find a component of type [T] attached to this object.
  /// 
  /// Similar to [getComponent] but returns null if no matching component 
  /// is attached.
  /// 
  /// * [T]: The type of component to search for.
  T? tryGetComponent<T extends Component>();

  /// Finds all components of type [T] attached to this object.
  /// 
  /// Returns a filtered iterable of the local [components] list.
  /// 
  /// * [T]: The type of component to search for.
  Iterable<T> getComponents<T extends Component>();

  /// Finds the first component of type [T] in the children hierarchy.
  /// 
  /// Performs a depth-first search through all descendants. Throws 
  /// a [StateError] if no match is found.
  /// 
  /// * [T]: The type of component to search for.
  T getComponentInChildren<T extends Component>();

  /// Attempts to find the first component of type [T] in children.
  /// 
  /// Similar to [getComponentInChildren] but returns null instead of 
  /// throwing if the search fails.
  /// 
  /// * [T]: The type of component to search for.
  T? tryGetComponentInChildren<T extends Component>();

  /// Finds all components of type [T] in the parent hierarchy.
  /// 
  /// Walks up to the [rootObject] and collects all matching components 
  /// along the path.
  /// 
  /// * [T]: The type of component to search for.
  Iterable<T> getComponentsInParent<T extends Component>();

  /// Finds a child object by its relative or absolute [name].
  /// 
  /// Searches through the immediate and nested children using a path-based 
  /// string lookup. Supports relative paths.
  /// 
  /// * [name]: The name or relative path of the child object.
  GameObject? findChild(String name);

  /// Global search for a [GameObject] by its [name] or path.
  /// 
  /// Traverses the entire scene hierarchy starting from the root objects. 
  /// Supports both absolute paths (starting with '/') and deep searches.
  /// 
  /// * [context]: The context to start the search from (retrieves the engine).
  /// * [name]: The name or '/'-separated path to search for.
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

  /// Finds a single [GameObject] associated with the given [tag].
  /// 
  /// Directly retrieves the object from the global tag registry. This is 
  /// an O(1) operation and is the preferred way to find unique objects.
  /// 
  /// * [context]: The current build context.
  /// * [tag]: The unique tag to look up.
  static GameObject? findWithTag(BuildContext context, GameTag tag) {
    return tag.gameObject;
  }

  /// Finds all [GameObject]s across the engine that share the given [tag].
  /// 
  /// Returns a collection of all objects currently mounted with this tag. 
  /// Note that while tags are typically unique, multiple objects can share 
  /// the same tag for group identification.
  /// 
  /// * [context]: The current build context.
  /// * [tag]: The group tag to look up.
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

  /// Starts an asynchronous coroutine tied to this object's lifecycle.
  /// 
  /// The coroutine will automatically be stopped if this object is disposed. 
  /// Returns a future that completes when the coroutine finishes or is stopped.
  /// 
  /// * [coroutine]: The generator function to execute.
  Future<void> startCoroutine(CoroutineFunction coroutine);

  /// Starts a coroutine with a specific [option] payload.
  /// 
  /// Similar to [startCoroutine] but allows passing a generic parameter 
  /// [T] to the generator.
  /// 
  /// * [coroutine]: The generator function with options.
  /// * [option]: The initial data to pass to the coroutine.
  /// * [T]: The type of the option payload.
  Future<void> startCoroutineWithOption<T>(
    CoroutineFunctionWithOptions<T> coroutine, {
    required T option,
  });

  /// Stops a specific running [coroutine] handle.
  /// 
  /// Cancels the execution of the coroutine and cleans up its 
  /// internal state.
  /// 
  /// * [coroutine]: The future handle returned by [startCoroutine].
  void stopCoroutine(Future<void> coroutine);

  /// Stops all coroutines currently running on this object.
  /// 
  /// Can optionally be filtered to only stop coroutines created from 
  /// a specific [coroutine] function.
  /// 
  /// * [coroutine]: Optional filter to only stop specific generator functions.
  void stopAllCoroutines([Function? coroutine]);

  /// Internal access to the children list.
  /// 
  /// Provides direct mutable access for hierarchical manipulation.
  @internal
  List<GameObject> get internalChildrenObjects;

  /// Internal setter for the parent object relationship.
  /// 
  /// * [value]: The new parent object.
  @internal
  set internalParentObject(GameObject? value);
}

/// The base implementation of [GameObject] as a Flutter [Element].
/// 
/// [GameObjectElement] manages the lifecycle of components and the 
/// coordination of the scene hierarchy. It handles the bridge 
/// between the widget tree and the engine's update/render loops.
/// 
/// ```dart
/// class MyObjectElement extends GameObjectElement {
///   MyObjectElement(super.widget);
/// }
/// ```
abstract class GameObjectElement extends RenderObjectElement
    implements GameObject {
  final List<Component> _components = [];
  final List<GameObject> _childrenObjects = [];
  final List<CoroutineFuture> _runningCoroutines = [];
  GameObject? _parentObject;
  List<Element> _childElements = [];
  GameEngine? _game;

  int _layer = RenderLayer.defaultLayer;

  /// Creates a [GameObjectElement] for the given [widget].
  /// 
  /// Initializes the element state and prepares the internal component 
  /// and child registries.
  /// 
  /// * [widget]: The source widget for this element.
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

  /// Updates the child element list from a list of widgets.
  /// 
  /// Reconciles the existing children with a new set of widgets.
  /// 
  /// * [newWidgets]: The new collection of child widgets.
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

/// A base class for widgets that represent objects in the game world.
/// 
/// [GameWidget] handles the creation of [GameElement]s and the 
/// configuration of initial components. It is the declarative way 
/// to define the scene hierarchy.
/// 
/// ```dart
/// GameWidget(
///   name: 'Player',
///   components: () => [SpriteRenderer()],
///   children: [
///     GameWidget(name: 'Sword'),
///   ],
/// )
/// ```
class GameWidget extends RenderObjectWidget {
  static List<Component> _emptyComponents() {
    return [];
  }

  /// The child widgets (sub-objects) of this widget.
  /// 
  /// Defines the visual and logical subtree of this game object.
  final List<Widget> children;

  /// A factory that provides the initial components for this object.
  /// 
  /// Invoked during element mounting to attach behaviors to the object.
  final Iterable<Component> Function() components;

  /// The rendering layer of this object.
  /// 
  /// Determines the drawing order and culling behavior.
  final int layer;

  /// The name of the object.
  /// 
  /// Used for runtime identification and debugging.
  final String? name;

  /// Creates a [GameWidget].
  /// 
  /// Configures the declarative properties of a game object.
  /// 
  /// * [key]: The widget key, typically a [GameTag].
  /// * [children]: The child sub-objects.
  /// * [components]: Factory for initial components.
  /// * [layer]: The rendering layer index.
  /// * [name]: The descriptive name.
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

/// The concrete [Element] implementation for [GameWidget].
/// 
/// Manages the actual runtime state of a [GameWidget] in the element tree.
/// 
/// ```dart
/// final element = GameElement(myWidget);
/// ```
class GameElement extends GameObjectElement {
  /// Creates a [GameElement] for the given [widget].
  /// 
  /// * [widget]: The source game widget.
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

/// Specialized [ParentData] for [GameObject] rendering.
/// 
/// Stores layout and hierarchy information used by [GameRenderObject].
/// 
/// ```dart
/// final data = GameParentData();
/// ```
class GameParentData extends ContainerBoxParentData<RenderBox> {}

/// The [RenderObject] responsible for painting a [GameObject] and its children.
/// 
/// [GameRenderObject] manages the transformation, culling, and 
/// event handling for a specific object in the scene. It uses 
/// the [ObjectTransform] component to determine its size and 
/// coordinate space.
/// 
/// ```dart
/// final renderObject = GameRenderObject(myObject);
/// ```
class GameRenderObject extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, GameParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, GameParentData>
    implements MouseTrackerAnnotation {
  /// The object this render object is serving.
  /// 
  /// Provides access to components and engine state during rendering.
  GameObject object;

  /// Creates a [GameRenderObject] for the given [object].
  /// 
  /// Initializes the render object with its associated game object.
  /// 
  /// * [object]: The source game object.
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
