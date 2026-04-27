import 'package:flutter/widgets.dart';
import 'package:goo2d/goo2d.dart';
import 'package:goo2d/src/object.dart';

abstract class StatefulGameWidget extends RenderObjectWidget {
  final int layer;

  const StatefulGameWidget({super.key, this.layer = RenderLayer.defaultLayer});

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

abstract class GameState<T extends StatefulGameWidget> extends Component {
  StatefulGameElement? _element;

  final List<InputAction> _trackedInputActions = [];

  @override
  GameObject get gameObject => _element!;

  T get widget => _element!.widget as T;

  BuildContext get context => _element!;

  bool get mounted => _element != null;

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

  void setState(VoidCallback fn) {
    assert(_element != null, 'Cannot call setState on an unmounted widget');
    fn();
    _element!.markNeedsBuild();
  }

  @mustCallSuper
  void initState() {}

  @mustCallSuper
  void didUpdateWidget(T oldWidget) {}

  @mustCallSuper
  void didChangeDependencies() {}

  @mustCallSuper
  void dispose() {
    for (var action in _trackedInputActions) {
      action.dispose();
    }
    _trackedInputActions.clear();
  }

  Iterable<Widget> build(BuildContext context) => const [];
}

class StatefulGameElement extends GameObjectElement {
  late final GameState state;

  StatefulGameElement(super.widget);

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    layer = (widget as StatefulGameWidget).layer;
    state = (widget as StatefulGameWidget).createState();
    state._element = this;

    addComponent(state);
    state.initState();
    state.didChangeDependencies();

    _rebuild();
  }

  @override
  void update(StatefulGameWidget newWidget) {
    layer = newWidget.layer;
    final oldWidget = widget as StatefulGameWidget;
    super.update(newWidget);
    state.didUpdateWidget(oldWidget);
    _rebuild();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    state.didChangeDependencies();
  }

  @override
  void unmount() {
    state.dispose();
    super.unmount();
  }

  @override
  void performRebuild() {
    // Satisfy must_call_super to ensure updateRenderObject is called
    super.performRebuild();
    _rebuild();
  }

  void _rebuild() {
    final widgets = state.build(this).toList();
    updateChildElements(widgets);
  }
}
