import 'package:flutter/widgets.dart';
import 'package:goo2d/goo2d.dart';
import 'package:goo2d/src/object.dart';

/// A base class for [GameObject]s that maintain mutable state.
///
/// [StatefulGameWidget] is the engine's equivalent to Flutter's 
/// `StatefulWidget`. It is used for complex game objects (like players or 
/// enemies) that need to track variables over time and respond to 
/// lifecycle events.
/// 
/// ```dart
/// class MyPlayer extends StatefulGameWidget {
///   @override
///   GameState createState() => MyPlayerState();
/// }
/// ```
///
/// See also:
/// * [GameState], where the actual logic and state reside.
/// * [StatefulGameElement], the underlying element that manages the object.
abstract class StatefulGameWidget extends RenderObjectWidget {
  /// The rendering layer this object belongs to.
  ///
  /// * [layer] Defaults to [RenderLayer.defaultLayer].
  final int layer;

  /// Creates a stateful game widget.
  /// 
  /// * [key]: Standard Flutter widget key.
  /// * [layer]: The rendering layer this object belongs to.
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

  /// Creates the [GameState] instance for this widget.
  ///
  /// This is called when the widget is first inserted into the scene tree. 
  /// Subclasses must override this to return their specific state implementation.
  GameState createState();
}

/// The logic and internal state for a [StatefulGameWidget].
///
/// [GameState] objects have a lifecycle similar to Flutter's `State` class, 
/// including [initState], [didUpdateWidget], and [dispose]. They are also 
/// [Component]s, meaning they are automatically attached to the 
/// [StatefulGameWidget]'s [GameObject] and can receive update ticks.
///
/// ```dart
/// class MyPlayerState extends GameState< MyPlayerWidget > {
///   int health = 100;
///
///   @override
///   void update(double dt) {
///     // Game logic goes here
///   }
///
///   @override
///   Iterable< Widget > build(BuildContext context) => [
///     // UI overlay components
///   ];
/// }
/// ```
abstract class GameState<T extends StatefulGameWidget> extends Component {
  StatefulGameElement? _element;

  final List<InputAction> _trackedInputActions = [];

  @override
  GameObject get gameObject => _element!;

  /// The widget configuration currently associated with this state.
  /// 
  /// Returns the current configuration from the [StatefulGameElement]. This 
  /// is updated whenever the widget tree rebuilds with a new config.
  T get widget => _element!.widget as T;

  /// The location in the scene graph where this state is mounted.
  /// 
  /// [context] provides access to the engine's element hierarchy and 
  /// the underlying [GameObject].
  BuildContext get context => _element!;

  /// Whether the state is currently mounted in the scene graph.
  /// 
  /// Returns true if the [_element] is not null, indicating that the 
  /// state is currently active within the engine.
  bool get mounted => _element != null;

  /// Helper method to create and track an [InputAction] tied to this state's lifecycle.
  ///
  /// Actions created through this method are automatically disposed when the
  /// state is disposed, preventing memory leaks. They are registered with 
  /// the game's [InputSystem].
  ///
  /// * [name]: The unique identifier for the action.
  /// * [type]: The data type expected from the action.
  /// * [bindings]: The physical keys or buttons that trigger this action.
  /// * [enable]: Whether to enable the action immediately upon creation.
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
  ///
  /// Calling this will trigger a rebuild of any overlay widgets returned 
  /// by the [build] method. Use this to sync the UI with game state.
  ///
  /// * [fn]: A callback that performs the state modification.
  void setState(VoidCallback fn) {
    assert(_element != null, 'Cannot call setState on an unmounted widget');
    fn();
    _element!.markNeedsBuild();
  }

  /// Called when this object is inserted into the scene graph.
  /// 
  /// This is the first lifecycle hook called after the state is created. 
  /// Use it to perform one-time initialization, such as creating [InputAction]s.
  @mustCallSuper
  void initState() {}

  /// Called whenever the widget configuration changes.
  ///
  /// This occurs when the parent widget rebuilds and provides a new 
  /// configuration for this element.
  /// 
  /// * [oldWidget]: The previous widget configuration.
  @mustCallSuper
  void didUpdateWidget(T oldWidget) {}

  /// Called when a dependency of this state changes.
  /// 
  /// Use this to respond to changes in [InheritedWidget]s like [GameProvider].
  @mustCallSuper
  void didChangeDependencies() {}

  /// Called during hot reload to re-initialize state.
  /// 
  /// This allows the state to recover or reset properties when the 
  /// code is updated at runtime.
  @mustCallSuper
  void reassemble() {}

  /// Called when this object is removed from the scene graph.
  /// 
  /// Perform final cleanup here, such as canceling streams or disposing 
  /// custom resources not tracked by [createInputAction].
  @mustCallSuper
  void dispose() {
    for (var action in _trackedInputActions) {
      action.dispose();
    }
    _trackedInputActions.clear();
  }

  /// Returns a collection of overlay widgets to be rendered on top of the game.
  ///
  /// These widgets are rendered in screen space and can be used for HUDs, 
  /// menus, or status bars.
  /// 
  /// * [context]: The build context for the overlays.
  Iterable<Widget> build(BuildContext context) => const [];
}

/// An [Element] that manages a [StatefulGameWidget] in the scene graph.
///
/// It handles the bridge between Flutter's widget tree and the engine's 
/// [GameObject] hierarchy, managing the lifecycle of the associated [GameState].
/// 
/// ```dart
/// final element = StatefulGameElement(myWidget);
/// ```
class StatefulGameElement extends GameObjectElement {
  /// The state instance associated with this element.
  /// 
  /// [state] handles the business logic and UI building for this element.
  late final GameState state;

  /// Creates an element for the given [widget].
  /// 
  /// * [widget]: The source widget for this element.
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
  void reassemble() {
    super.reassemble();
    state.reassemble();
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
