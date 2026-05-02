import 'package:flutter/widgets.dart';
import 'package:goo2d/src/game.dart';
import 'package:goo2d/src/component.dart';
import 'package:goo2d/src/event.dart';
import 'package:goo2d/src/coroutine.dart';

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
  void removeComponentOfType<T extends Component>();
  void addComponents(Iterable<Component> components);
  void removeComponents(Iterable<Type> types);
  void removeComponentAt(int index);
  void removeAllComponents();
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
  bool hasComponent<T extends Component>();
  bool hasComponentOfType(Type type);
  Component getComponentAt(int index);
  int getComponentsCount();
  List<T> getComponentsOfType<T extends Component>();
  int getComponentIndex(Component component);
  GameObject? findChild(String name);
  static GameObject? find(BuildContext context, String name) {
    final engine = GameEngine.of(context);
    final isAbsolute = name.startsWith('/');
    final path = isAbsolute ? name.substring(1) : name;
    final parts = path.split('/');

    final roots = engine.getSystem<TickerState>()?.rootObjects ?? [];
    for (final root in roots) {
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

  static GameObject? findWithTag(BuildContext context, GameTag tag) {
    return tag.gameObject;
  }

  static Iterable<GameObject> findGameObjectsWithTag(
    BuildContext context,
    GameTag tag,
  ) {
    final engine = GameEngine.of(context);
    final roots = engine.getSystem<TickerState>()?.rootObjects ?? [];
    return roots.expand((e) => _findAllWithTag(e, tag));
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
}
