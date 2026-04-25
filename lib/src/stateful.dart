import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:goo2d/goo2d.dart';

abstract class StatefulGameWidget extends MultiChildRenderObjectWidget {
  const StatefulGameWidget({super.key}) : super(children: const []);

  @override
  StatefulGameElement createElement() => StatefulGameElement(this);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return GameRenderObject(context as GameObject);
  }

  @override
  void updateRenderObject(BuildContext context, GameRenderObject renderObject) {
    renderObject.object = context as GameObject;
  }

  GameState createState();
}

abstract class GameState<T extends StatefulGameWidget>
    with GameObjectMixin
    implements GameObject, BuildContext {
  late StatefulGameElement _element;

  GameObject get gameObject => _element;
  V stateObject<V extends GameState>() => this as V;

  @override
  T get widget => _element.widget as T;

  BuildContext get context => _element;

  void setState(VoidCallback fn) {
    fn();
    _element.markNeedsBuild();
  }

  void initState() {}
  void dispose() {}

  Iterable<Widget> build(BuildContext context);

  // GameObject / BuildContext Delegation
  @override
  bool get active => _element.mounted;

  @override
  Object? get tag => _element.tag;

  @override
  bool get mounted => _element.mounted;

  @override
  BuildOwner? get owner => _element.owner;

  @override
  bool get debugDoingBuild => _element.debugDoingBuild;

  @override
  Size? get size => _element.size;

  @override
  InheritedWidget dependOnInheritedElement(
    InheritedElement ancestor, {
    Object? aspect,
  }) => _element.dependOnInheritedElement(ancestor, aspect: aspect);

  @override
  V? dependOnInheritedWidgetOfExactType<V extends InheritedWidget>({
    Object? aspect,
  }) => _element.dependOnInheritedWidgetOfExactType<V>(aspect: aspect);

  @override
  InheritedElement?
  getElementForInheritedWidgetOfExactType<V extends InheritedWidget>() =>
      _element.getElementForInheritedWidgetOfExactType<V>();

  @override
  V? findAncestorWidgetOfExactType<V extends Widget>() =>
      _element.findAncestorWidgetOfExactType<V>();

  @override
  V? findAncestorStateOfType<V extends State<StatefulWidget>>() =>
      _element.findAncestorStateOfType<V>();

  @override
  V? findRootAncestorStateOfType<V extends State<StatefulWidget>>() =>
      _element.findRootAncestorStateOfType<V>();

  @override
  V? findAncestorRenderObjectOfType<V extends RenderObject>() =>
      _element.findAncestorRenderObjectOfType<V>();

  @override
  void visitAncestorElements(bool Function(Element element) visitor) =>
      _element.visitAncestorElements(visitor);

  @override
  void visitChildElements(ElementVisitor visitor) =>
      _element.visitChildElements(visitor);

  @override
  void dispatchNotification(Notification notification) =>
      _element.dispatchNotification(notification);

  @override
  DiagnosticsNode describeElement(
    String name, {
    DiagnosticsTreeStyle style = DiagnosticsTreeStyle.errorProperty,
  }) => _element.describeElement(name, style: style);

  @override
  DiagnosticsNode describeWidget(
    String name, {
    DiagnosticsTreeStyle style = DiagnosticsTreeStyle.errorProperty,
  }) => _element.describeWidget(name, style: style);

  @override
  List<DiagnosticsNode> describeMissingAncestor({
    required Type expectedAncestorType,
  }) => _element.describeMissingAncestor(
    expectedAncestorType: expectedAncestorType,
  );

  @override
  DiagnosticsNode describeOwnershipChain(String name) =>
      _element.describeOwnershipChain(name);

  @override
  V? getInheritedWidgetOfExactType<V extends InheritedWidget>() =>
      _element.getInheritedWidgetOfExactType<V>();

  @override
  RenderObject? findRenderObject() => _element.findRenderObject();
}

class StatefulGameElement extends MultiChildRenderObjectElement
    implements GameObject {
  late final GameState state;

  StatefulGameElement(super.widget);

  @override
  Object? get tag =>
      widget.key is GameTag ? (widget.key as GameTag).value : null;

  @override
  bool get active => mounted;

  @override
  void mount(Element? parent, Object? newSlot) {
    state = (widget as StatefulGameWidget).createState();
    state._element = this;
    super.mount(parent, newSlot);
    _attachToParent();
    state.initState();
    // Trigger initial build of state children
    _rebuild();
    if (state is LifecycleListener) {
      (state as LifecycleListener).onMounted();
    }
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
    state.dispose();
    super.unmount();
    const UnmountedEvent().dispatchTo(this);
  }

  GameObject? _parentObject;

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
      if (ancestor is StatefulGameElement) {
        found = ancestor.state;
        return false;
      }
      if (ancestor is GameObject) {
        found = ancestor as GameObject;
        return false;
      }
      return true;
    });
    return found;
  }

  List<Element> _children = [];

  @override
  void performRebuild() {
    // Satisfy must_call_super to ensure updateRenderObject is called
    super.performRebuild();
    _rebuild();
  }

  @override
  void update(MultiChildRenderObjectWidget newWidget) {
    super.update(newWidget);
    _rebuild();
  }

  void _rebuild() {
    final widgets = state.build(this).toList();
    _children = updateChildren(_children, widgets);
  }

  // GameObject delegation to State
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
  ]) => state.addComponent(component, a, b, c, d, e, f, g, h, i, j);

  @override
  void broadcastEvent(Event<EventListener> event) =>
      state.broadcastEvent(event);

  @override
  Iterable<GameObject> get childrenObjects => state.childrenObjects;

  @override
  Iterable<Component> get components => state.components;

  @override
  V getComponent<V extends Component>() => state.getComponent<V>();

  @override
  V getComponentInParent<V extends Component>() =>
      state.getComponentInParent<V>();

  @override
  Iterable<V> getComponents<V extends Component>() => state.getComponents<V>();

  @override
  Iterable<V> getComponentsInChildren<V extends Component>() =>
      state.getComponentsInChildren<V>();

  @override
  GameObject? get parentObject => state.parentObject;

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
  ]) => state.removeComponent(component, a, b, c, d, e, f, g, h, i, j);

  @override
  GameObject get rootObject => state.rootObject;

  @override
  void sendEvent(Event<EventListener> event) => state.sendEvent(event);

  @override
  V? tryGetComponent<V extends Component>() => state.tryGetComponent<V>();

  @override
  V? tryGetComponentInParent<V extends Component>() =>
      state.tryGetComponentInParent<V>();

  @override
  List<GameObject> get internalChildrenObjects => state.internalChildrenObjects;

  @override
  Future<void> startCoroutine(CoroutineFunction coroutine) =>
      state.startCoroutine(coroutine);

  @override
  Future<void> startCoroutineWithOption<T>(
    CoroutineFunctionWithOptions<T> coroutine, {
    required T option,
  }) => state.startCoroutineWithOption<T>(coroutine, option: option);

  @override
  void stopCoroutine(Future<void> coroutine) => state.stopCoroutine(coroutine);

  @override
  void stopAllCoroutines([Function? coroutine]) =>
      state.stopAllCoroutines(coroutine);

  @override
  set internalParentObject(GameObject? value) =>
      state.internalParentObject = value;
}
