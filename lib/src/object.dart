import 'package:flutter/widgets.dart';
import 'package:goo2d/src/game.dart';
import 'package:goo2d/src/component.dart';
import 'package:goo2d/src/event.dart';
import 'package:goo2d/src/coroutine.dart';

/// A globally unique identifier for a [GameObject], used for searching.
class GameTag extends GlobalObjectKey {
  /// Creates a [GameTag] with the given [value].
  const GameTag(super.value);

  /// Returns the [GameObject] associated with this tag, if it exists.
  GameObject? get gameObject => currentContext as GameObject?;
}

/// The core interface for all objects in the Goo2D scene hierarchy.
abstract class GameObject implements BuildContext {
  /// The user-defined name of this object.
  String get name;

  /// The [GameEngine] instance this object belongs to.
  GameEngine get game;

  /// The unique [GameTag] assigned to this object, if any.
  GameTag? get tag;

  /// Whether this object is currently mounted and active in the scene.
  bool get active;

  /// The top-most [GameObject] in this object's hierarchy.
  GameObject get rootObject;

  /// The immediate parent of this object, or null if it is a root object.
  GameObject? get parentObject;

  /// An unmodifiable collection of all immediate child [GameObject]s.
  Iterable<GameObject> get childrenObjects;

  /// An unmodifiable collection of all [Component]s attached to this object.
  Iterable<Component> get components;

  /// The rendering layer this object belongs to.
  int get layer;

  /// Updates the rendering layer this object belongs to.
  set layer(int value);

  /// Adds one or more components to this object.
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

  /// Removes one or more component instances from this object.
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

  /// Removes one or more components of the exact specified runtime types.
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
  ]);

  /// Removes all components of type [T] (including subclasses).
  void removeComponentOfType<T extends Component>();

  /// Adds multiple components to this object.
  void addComponents(Iterable<Component> components);

  /// Removes all components of the specified exact runtime types.
  void removeComponents(Iterable<Type> types);

  /// Removes the component at the specified index.
  void removeComponentAt(int index);

  /// Removes all components from this object.
  void removeAllComponents();

  /// Recursively searches for all components of type [T] in children.
  Iterable<T> getComponentsInChildren<T extends Component>();

  /// Finds the first component of type [T] in the parent hierarchy.
  T getComponentInParent<T extends Component>();

  /// Attempts to find a component of type [T] in the parent hierarchy.
  T? tryGetComponentInParent<T extends Component>();

  /// Broadcasts an [event] to this object's components and all children.
  void broadcastEvent(Event event);

  /// Dispatches an [event] to all immediate children.
  void sendEvent(Event event);

  /// Finds the first component of type [T] attached to this object.
  T getComponent<T extends Component>();

  /// Attempts to find a component of type [T] attached to this object.
  T? tryGetComponent<T extends Component>();

  /// Finds all components of type [T] attached to this object.
  Iterable<T> getComponents<T extends Component>();

  /// Finds the first component of type [T] in the children hierarchy.
  T getComponentInChildren<T extends Component>();

  /// Attempts to find the first component of type [T] in children.
  T? tryGetComponentInChildren<T extends Component>();

  /// Finds all components of type [T] in the parent hierarchy.
  Iterable<T> getComponentsInParent<T extends Component>();

  /// Checks if a component of type [T] is attached to this object.
  bool hasComponent<T extends Component>();

  /// Checks if a component of exact [type] is attached to this object.
  bool hasComponentOfType(Type type);

  /// Returns the component at the specified [index] in the components list.
  Component getComponentAt(int index);

  /// Returns the total number of components attached to this object.
  int getComponentsCount();

  /// Finds all components of type [T] and returns them as a list.
  List<T> getComponentsOfType<T extends Component>();

  /// Returns the index of a specific [component] instance, or -1 if not found.
  int getComponentIndex(Component component);

  /// Finds a child object by its relative or absolute [name].
  GameObject? findChild(String name);

  /// Global search for a [GameObject] by its [name] or path.
  static GameObject? find(BuildContext context, String name) {
    final engine = GameEngine.of(context);
    final isAbsolute = name.startsWith('/');
    final path = isAbsolute ? name.substring(1) : name;
    final parts = path.split('/');

    for (final root in engine.rootObjects) {
      if (root.name == parts[0]) {
        if (parts.length == 1) return root;
        final found = root.findChild(path.substring(parts[0].length + 1));
        if (found != null) return found;
      }

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
  static GameObject? findWithTag(BuildContext context, GameTag tag) {
    return tag.gameObject;
  }

  /// Finds all [GameObject]s across the engine that share the given [tag].
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
  Future<void> startCoroutine(CoroutineFunction coroutine);

  /// Starts a coroutine with a specific [option] payload.
  Future<void> startCoroutineWithOption<T>(
    CoroutineFunctionWithOptions<T> coroutine, {
    required T option,
  });

  /// Stops a specific running [coroutine] handle.
  void stopCoroutine(Future<void> coroutine);

  /// Stops all coroutines currently running on this object.
  void stopAllCoroutines([Function? coroutine]);
}
