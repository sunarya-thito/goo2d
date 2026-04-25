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

abstract class GameState<T extends StatefulGameWidget> extends Component {
  late StatefulGameElement _element;

  @override
  GameObject get gameObject => _element;

  T get widget => _element.widget as T;

  BuildContext get context => _element;

  void setState(VoidCallback fn) {
    fn();
    _element.markNeedsBuild();
  }

  @mustCallSuper
  void initState() {}

  @mustCallSuper
  void didUpdateWidget(T oldWidget) {}

  @mustCallSuper
  void didChangeDependencies() {}

  @mustCallSuper
  void dispose() {}

  Iterable<Widget> build(BuildContext context);
}

class StatefulGameElement extends GameObjectElement {
  late final GameState state;

  StatefulGameElement(super.widget);

  @override
  void mount(Element? parent, Object? newSlot) {
    state = (widget as StatefulGameWidget).createState();
    state._element = this;
    super.mount(parent, newSlot);

    addComponent(state);
    state.initState();

    // Trigger initial build of state children
    _rebuild();
  }

  @override
  void update(MultiChildRenderObjectWidget newWidget) {
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

  List<Element> _children = [];

  @override
  void performRebuild() {
    // Satisfy must_call_super to ensure updateRenderObject is called
    super.performRebuild();
    _rebuild();
  }

  void _rebuild() {
    final widgets = state.build(this).toList();
    _children = updateChildren(_children, widgets);
  }
}
