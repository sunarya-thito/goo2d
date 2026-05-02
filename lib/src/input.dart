import 'package:flutter/services.dart';
import 'package:goo2d/src/game.dart';
import 'package:goo2d/src/component.dart';
import 'package:goo2d/src/lifecycle.dart';

part 'keyboard.dart';

/// Represents the current state of an [InputAction] during the game loop.
///
/// The lifecycle of an action generally flows from [waiting] -> [started] ->
/// [performed] -> [canceled]. This state machine ensures that input remains
/// predictable across different hardware refresh rates and frame timings.
///
/// ```dart
/// if (action.phase == InputActionPhase.performed) {
///   // Trigger gameplay logic
/// }
/// ```
enum InputActionPhase {
  /// The action is disabled.
  ///
  /// The action will not process any input bindings or trigger callbacks.
  disabled,

  /// The action is waiting for input.
  ///
  /// The action is enabled but no input thresholds have been met.
  waiting,

  /// The action has started.
  ///
  /// Input has begun but the performance threshold is not yet reached.
  started,

  /// The action has been performed.
  ///
  /// The input has reached the necessary threshold to trigger logic.
  performed,

  /// The action has been canceled.
  ///
  /// The input has ended or was interrupted before completion.
  canceled,
}

/// Defines the behavioral logic for how an [InputAction] processes input.
///
/// Different interaction types require different trigger logic. For example,
/// a "Jump" command should only fire once per press, while "Move" should
/// provide continuous updates.
///
/// ```dart
/// final move = InputAction(type: InputActionType.value);
/// ```
enum InputActionType {
  /// Continuous value-based input.
  ///
  /// Maintains the performed state as long as input is non-zero.
  value,

  /// Discrete button-based input.
  ///
  /// Triggers the performed state exactly once per press.
  button,

  /// Raw pass-through input.
  ///
  /// Passes through the raw input from the most recent control.
  passThrough,
}

/// Contextual data provided to [InputAction] event listeners.
///
/// When an action triggers an event (started, performed, canceled), it
/// passes a [CallbackContext] containing the current state and value.
/// This object is short-lived and should not be cached across frames.
///
/// ```dart
/// myAction.performed += (context) {
///   final val = context.readValue<double>(); // Use generic <T> to cast
///   print('Magnitude: ${context.magnitude}');
/// };
/// ```
class CallbackContext {
  /// The action that triggered this callback.
  ///
  /// Provides access to the originating [InputAction] configuration.
  final InputAction action;

  /// The current phase of the action.
  ///
  /// Describes the state machine transition that triggered the event.
  final InputActionPhase phase;

  /// Reads the current value of the action as type [T].
  ///
  /// For buttons, this is typically a `bool`. For composites, this
  /// might be a `double` or [Offset].
  ///
  /// * [T]: The expected return type.
  T readValue<T>() => action.readValue<T>();

  /// The normalized magnitude of the input (0.0 to 1.0).
  ///
  /// Calculated from the displacement of the underlying controls.
  double get magnitude => action._getMagnitude();

  /// The physical [InputControl] driving this action.
  ///
  /// Identifies the specific hardware source for the current interaction.
  InputControl? get control => action.activeControl;

  /// Creates a [CallbackContext] for a specific [action] and [phase].
  ///
  /// * [action]: The originating logical action.
  /// * [phase]: The phase that triggered this specific callback.
  CallbackContext(this.action, this.phase);
}

/// A specialized event system for handling [InputAction] callbacks.
///
/// It supports subscription and unsubscription using operator
/// overloading for a cleaner syntax. This system mimics modern
/// input frameworks to provide a familiar and ergonomic API.
///
/// ```dart
/// myAction.performed += (context) => print('Action performed!');
/// ```
class InputEvent {
  /// Internal list of event listeners.
  ///
  /// Stores callbacks to be executed when the event is invoked.
  final List<void Function(CallbackContext)> _listeners = [];

  /// Adds a listener to the event using the `+=` operator.
  ///
  /// Appends the provided callback to the internal listener list.
  /// The listener will be invoked on the next [invoke] call.
  ///
  /// * [listener]: The callback to be invoked when the event fires.
  InputEvent operator +(void Function(CallbackContext) listener) {
    _listeners.add(listener);
    return this;
  }

  /// Removes a listener from the event using the `-=` operator.
  ///
  /// Searches for the provided callback in the internal list and
  /// removes it. If the listener is not found, no action is taken.
  ///
  /// * [listener]: The callback to remove.
  InputEvent operator -(void Function(CallbackContext) listener) {
    _listeners.remove(listener);
    return this;
  }

  /// Invokes all listeners with the provided [context].
  ///
  /// Listeners are copied before iteration to allow modification
  /// of the list during the callback. This ensures stability if a
  /// listener unbinds itself during execution.
  ///
  /// * [context]: The data to pass to all listeners.
  void invoke(CallbackContext context) {
    for (var listener in List<void Function(CallbackContext)>.from(
      _listeners,
    )) {
      listener(context);
    }
  }

  /// Disposes of the event and clears all listeners.
  ///
  /// Should be called when the owning [InputAction] is no
  /// longer needed to prevent memory leaks.
  void dispose() => _listeners.clear();
}

/// The system responsible for processing physical input and driving actions.
///
/// [InputSystem] maintains the state of the [keyboard], manages
/// all registered [InputAction]s, and provides a registry for
/// default values. It acts as the central hub bridging Flutter events.
///
/// ```dart
/// final input = InputSystem();
/// engine.addSystem(input);
/// ```
class InputSystem implements GameSystem {
  /// The internal keyboard state manager.
  ///
  /// Tracks physical key presses and releases via Flutter Services.
  KeyboardState? _keyboard;

  /// The current state of the physical keyboard.
  ///
  /// Throws an [AssertionError] if accessed before the system is attached
  /// to a [GameEngine].
  KeyboardState get keyboard {
    assert(
      _keyboard != null,
      'KeyboardState is not ready. Did you call initialize() on GameEngine?',
    );
    return _keyboard!;
  }

  /// List of registered logical actions.
  ///
  /// Managed by [_registerAction] and [_unregisterAction] methods.
  final List<InputAction> _actions = [];

  /// Monotonic counter for dynamic updates.
  ///
  /// Used to resolve sub-frame input timing and prevent double-triggering.
  int dynamicUpdateCount = 0;

  /// The engine instance this system is attached to.
  ///
  /// Provides access to the ticker and other core systems.
  GameEngine? _game;
  @override
  GameEngine get game {
    assert(_game != null, 'InputSystem is not attached to a GameEngine');
    return _game!;
  }

  @override
  bool get gameAttached => _game != null;

  static final Map<Type, Object Function()> _defaultValues = {
    bool: () => false,
    double: () => 0.0,
    Offset: () => Offset.zero,
  };

  /// Creates a new [InputSystem] instance.
  ///
  /// Initializes the system state and prepares the internal registries.
  InputSystem();

  @override
  void attach(GameEngine game) {
    _game = game;
    _keyboard = KeyboardState(game);
  }

  /// Registers a default value provider for a custom input type [T].
  ///
  /// This ensures that [InputAction.readValue] always returns a valid
  /// object even when no input is active. Providers are stored in a
  /// static map for global access.
  ///
  /// * [provider]: A factory function that returns the default state of [T].
  static void registerDefaultValue<T extends Object>(T Function() provider) =>
      _defaultValues[T] = provider;

  /// Retrieves the default value for type [T].
  ///
  /// Looks up the provider in the [_defaultValues] registry and invokes it.
  /// Throws an error if no provider is registered for the requested type.
  ///
  /// * [T]: The type to retrieve a default for.
  static T getDefaultValue<T>() {
    final provider = _defaultValues[T];
    if (provider == null) throw UnimplementedError('No default value for $T');
    return provider() as T;
  }

  /// Registers an action with the system.
  ///
  /// Appends the [action] to the list of monitored logical inputs.
  ///
  /// * [action]: The action to register.
  void _registerAction(InputAction action) => _actions.add(action);

  /// Unregisters an action.
  ///
  /// Removes the [action] from the system and stops its updates.
  ///
  /// * [action]: The action to remove.
  void _unregisterAction(InputAction action) => _actions.remove(action);

  /// Updates all enabled actions based on current physical control states.
  ///
  /// This should be called once per game tick. It increments
  /// the [dynamicUpdateCount] and processes the phase state
  /// machine for every registered action.
  void update() {
    dynamicUpdateCount++;
    for (var action in _actions) {
      if (action.enabled) action._updatePhase();
    }
  }

  @override
  void dispose() {
    _keyboard?.dispose();
    for (var action in List<InputAction>.from(_actions)) {
      action.dispose();
    }
    _actions.clear();
  }
}

/// Base class for any physical or virtual input source.
///
/// [InputControl] tracks the raw state of a specific input and records
/// its magnitude. Subclasses implement hardware-specific logic.
///
/// ```dart
/// class MyKeyControl extends InputControl { }
/// ```
abstract class InputControl<T> {
  /// The [GameEngine] this control is associated with.
  ///
  /// Provides access to the ticker and other core engine systems.
  GameEngine get game;

  /// The current raw value of the control.
  ///
  /// Represents the hardware state as a typed value [T].
  T get value;

  /// The normalized magnitude of the input.
  ///
  /// Returns a value between 0.0 and 1.0 representing input intensity.
  double get magnitude;

  /// Frame number of the last press event.
  ///
  /// Used to calculate durations and handle frame-accurate logic.
  int lastFramePressed = -1;

  /// Frame number of the last release event.
  ///
  /// Used to determine if a release happened in the current frame.
  int lastFrameReleased = -1;

  /// Dynamic update count of the last press.
  ///
  /// Synchronized with [InputSystem.dynamicUpdateCount] for sub-frame timing.
  int lastUpdatePressed = -1;

  /// Dynamic update count of the last release.
  ///
  /// Synchronized with [InputSystem.dynamicUpdateCount] for sub-frame timing.
  int lastUpdateReleased = -1;

  /// Whether the control is currently pressed.
  ///
  /// Returns true if the control is active (e.g., button held).
  bool get isPressed;

  /// Whether the control was pressed this frame.
  ///
  /// Checks [lastFramePressed] against the current engine frame.
  bool get wasPressedThisFrame =>
      lastFramePressed == game.getSystem<TickerState>()?.frameCount;

  /// Whether the control was released this frame.
  ///
  /// Checks [lastFrameReleased] against the current engine frame.
  bool get wasReleasedThisFrame =>
      lastFrameReleased == game.getSystem<TickerState>()?.frameCount;
}

/// A specialized [InputControl] for binary (on/off) inputs.
///
/// [ButtonControl] is used for keys, mouse buttons, and gamepad
/// face buttons. It maintains simple boolean state and
/// frame-accurate timing for presses and releases.
///
/// ```dart
/// final button = ButtonControl(game);
/// ```
class ButtonControl extends InputControl<bool> {
  @override
  final GameEngine game;
  bool _isPressed = false;

  /// Creates a [ButtonControl] instance for a specific [game].
  ///
  /// The control will use the engine's ticker to record press timings.
  ///
  /// * [game]: The engine instance to read frame timing from.
  ButtonControl(this.game);

  @override
  bool get value => _isPressed;
  @override
  bool get isPressed => _isPressed;
  @override
  double get magnitude => _isPressed ? 1.0 : 0.0;

  /// Internal method to record a press event.
  ///
  /// Updates the [lastFramePressed] if the button was not previously
  /// in a pressed state. This ensures frame-accurate input timing.
  void press() {
    if (!_isPressed) {
      lastFramePressed = game.getSystem<TickerState>()?.frameCount ?? -1;
      lastUpdatePressed =
          game.getSystem<InputSystem>()?.dynamicUpdateCount ?? -1;
    }
    _isPressed = true;
  }

  /// Internal method to record a release event.
  ///
  /// Updates [lastFrameReleased] and [lastUpdateReleased] to
  /// synchronize with the current engine state. This is used for
  /// sub-frame event resolution.
  void release() {
    if (_isPressed) {
      lastFrameReleased = game.getSystem<TickerState>()?.frameCount ?? -1;
      lastUpdateReleased =
          game.getSystem<InputSystem>()?.dynamicUpdateCount ?? -1;
    }
    _isPressed = false;
  }
}

/// Manages the state of all keys on a physical keyboard.
///
/// [KeyboardState] listens to system hardware events and updates
/// internal [ButtonControl] instances for each key. It provides
/// a convenient indexed accessor for any [LogicalKeyboardKey].
///
/// Example:
/// ```dart
/// final spaceKey = input.keyboard[LogicalKeyboardKey.space];
/// if (spaceKey.isPressed) jump();
/// ```
class KeyboardState {
  /// The [GameEngine] instance providing frame data.
  ///
  /// Used to synchronize input events with the engine's current frame
  /// number and ticker state.
  final GameEngine game;
  final Map<LogicalKeyboardKey, ButtonControl> _keys = {};

  /// Creates a [KeyboardState] and attaches hardware listeners.
  ///
  /// Registers the [_handleKeyEvent] method with the [HardwareKeyboard]
  /// singleton to receive low-level OS events.
  ///
  /// * [game]: The engine instance to bind to.
  KeyboardState(this.game) {
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  /// Retrieves the [ButtonControl] for a specific [key].
  ///
  /// If the key has not been accessed before, a new control is created
  /// and cached in the internal [_keys] map.
  ///
  /// * [key]: The logical key to look up.
  ButtonControl operator [](LogicalKeyboardKey key) =>
      _keys.putIfAbsent(key, () => ButtonControl(game));

  /// Internal event handler for Flutter's [KeyEvent]s.
  ///
  /// Updates the corresponding [ButtonControl] state based on whether
  /// the key was pressed or released.
  ///
  /// * [event]: The low-level Flutter key event.
  bool _handleKeyEvent(KeyEvent event) {
    final key = event.logicalKey;
    final control = this[key];
    if (event is KeyDownEvent) {
      control.press();
    } else if (event is KeyUpEvent) {
      control.release();
    }
    return false;
  }

  /// Unregisters the hardware listener and clears key states.
  ///
  /// Removes the [_handleKeyEvent] from the global handler list to
  /// prevent memory leaks when the system is destroyed.
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
  }
}

/// Base class for mapping physical controls to logical [InputAction] values.
///
/// Bindings provide a layer of abstraction that allows one action
/// to be triggered by multiple different hardware sources. They can be
/// simple 1-to-1 mappings or complex composites.
///
/// ```dart
/// final binding = InputBinding(keyboard.space);
/// ```
abstract class InputBinding {
  const InputBinding._();

  /// Creates the runtime state for this binding.
  ///
  /// This is called automatically by [InputAction] when it is mounted.
  BindingState createState(GameEngine game);

  /// Whether the binding is currently active in the given [game].
  bool isPressed(GameEngine game);

  /// Whether the binding was pressed in the current frame of the given [game].
  bool wasPressedThisFrame(GameEngine game);

  /// Whether the binding was released in the current frame of the given [game].
  bool wasReleasedThisFrame(GameEngine game);

  /// The normalized magnitude of the binding in the given [game].
  double magnitude(GameEngine game);

  /// Reads the raw value of the binding in the given [game].
  T readValue<T>(GameEngine game);

  /// Creates a binding for a specific [InputControl].
  const factory InputBinding(InputControl control) = SimpleInputBinding;

  /// Creates a late-bound keyboard binding for a [LogicalKeyboardKey].
  const factory InputBinding.key(LogicalKeyboardKey key) = KeyInputBinding;

  /// Creates a composite binding that combines 4 buttons into a 2D vector.
  const factory InputBinding.composite({
    required InputBinding up,
    required InputBinding down,
    required InputBinding left,
    required InputBinding right,
  }) = CompositeBinding;
}

/// Holds the runtime state and logic for an [InputBinding].
abstract class BindingState {
  final GameEngine game;
  BindingState(this.game);

  /// Reads the raw value from the bound controls.
  Object? read();

  /// The normalized magnitude of the input (usually 0.0 to 1.0).
  double get magnitude;

  /// Whether the input is currently active.
  bool get isPressed;

  /// The specific [InputControl] currently driving this binding.
  InputControl? get activeControl;

  /// Whether the input was released in the current frame.
  bool get wasReleasedThisFrame;

  /// Whether the input was released in the current dynamic update.
  bool get wasReleasedThisDynamicUpdate;

  /// Whether the input was pressed in the current frame.
  bool get wasPressedThisFrame;

  /// Whether the input was pressed in the current dynamic update.
  bool get wasPressedThisDynamicUpdate;

  /// Helper to cast the value to a specific type.
  T? asValue<T>() {
    final val = read();
    try {
      return val as T;
    } catch (_) {
      return null;
    }
  }
}

/// A binding that maps a single physical control to an action.
///
/// [SimpleInputBinding] is the most basic binding type. It provides
/// a direct link between a hardware control and a logical action.
///
/// ```dart
/// final binding = SimpleInputBinding(keyboard.space);
/// ```
class SimpleInputBinding extends InputBinding {
  final InputControl control;
  const SimpleInputBinding(this.control) : super._();

  @override
  BindingState createState(GameEngine game) =>
      SimpleBindingState(game, control);

  @override
  bool isPressed(GameEngine game) => control.isPressed;
  @override
  bool wasPressedThisFrame(GameEngine game) => control.wasPressedThisFrame;
  @override
  bool wasReleasedThisFrame(GameEngine game) => control.wasReleasedThisFrame;
  @override
  double magnitude(GameEngine game) => control.magnitude;
  @override
  T readValue<T>(GameEngine game) => 
      control.value is T ? control.value as T : InputSystem.getDefaultValue<T>();
}

class SimpleBindingState extends BindingState {
  final InputControl control;
  SimpleBindingState(super.game, this.control);

  @override
  Object? read() => control.value;
  @override
  double get magnitude => control.magnitude;
  @override
  bool get isPressed => control.isPressed;
  @override
  InputControl? get activeControl => isPressed ? control : null;
  @override
  bool get wasReleasedThisFrame => control.wasReleasedThisFrame;
  @override
  bool get wasReleasedThisDynamicUpdate =>
      control.lastUpdateReleased ==
      game.getSystem<InputSystem>()?.dynamicUpdateCount;
  @override
  bool get wasPressedThisFrame => control.wasPressedThisFrame;
  @override
  bool get wasPressedThisDynamicUpdate =>
      control.lastUpdatePressed ==
      game.getSystem<InputSystem>()?.dynamicUpdateCount;
}

/// A binding that resolves to a specific keyboard key.
class KeyInputBinding extends InputBinding {
  final LogicalKeyboardKey key;
  const KeyInputBinding(this.key) : super._();

  @override
  BindingState createState(GameEngine game) => KeyBindingState(game, key);

  @override
  bool isPressed(GameEngine game) =>
      game.getSystem<InputSystem>()?.keyboard[key].isPressed ?? false;
  @override
  bool wasPressedThisFrame(GameEngine game) =>
      game.getSystem<InputSystem>()?.keyboard[key].wasPressedThisFrame ?? false;
  @override
  bool wasReleasedThisFrame(GameEngine game) =>
      game.getSystem<InputSystem>()?.keyboard[key].wasReleasedThisFrame ?? false;
  @override
  double magnitude(GameEngine game) =>
      game.getSystem<InputSystem>()?.keyboard[key].magnitude ?? 0.0;
  @override
  T readValue<T>(GameEngine game) {
    final control = game.getSystem<InputSystem>()?.keyboard[key];
    return control?.value is T
        ? control!.value as T
        : InputSystem.getDefaultValue<T>();
  }
}

class KeyBindingState extends BindingState {
  final LogicalKeyboardKey key;
  ButtonControl? _control;

  KeyBindingState(super.game, this.key) {
    _control = game.getSystem<InputSystem>()?.keyboard[key];
  }

  @override
  Object? read() => _control?.value ?? false;
  @override
  double get magnitude => (_control?.value ?? false) ? 1.0 : 0.0;
  @override
  bool get isPressed => _control?.isPressed ?? false;
  @override
  InputControl? get activeControl =>
      (_control?.isPressed ?? false) ? _control : null;
  @override
  bool get wasReleasedThisFrame => _control?.wasReleasedThisFrame ?? false;
  @override
  bool get wasReleasedThisDynamicUpdate =>
      _control?.lastUpdateReleased ==
      game.getSystem<InputSystem>()?.dynamicUpdateCount;
  @override
  bool get wasPressedThisFrame => _control?.wasPressedThisFrame ?? false;
  @override
  bool get wasPressedThisDynamicUpdate =>
      _control?.lastUpdatePressed ==
      game.getSystem<InputSystem>()?.dynamicUpdateCount;
}

/// A binding that maps four binary buttons to a single 2-dimensional [Offset].
///
/// This is commonly used for WASD or Arrow key movement. The result
/// is a vector representing the combined state of the buttons.
///
/// ```dart
/// final move = CompositeBinding(up: w, down: s, left: a, right: d);
/// ```
class CompositeBinding extends InputBinding {
  final InputBinding up, down, left, right;

  const CompositeBinding({
    required this.up,
    required this.down,
    required this.left,
    required this.right,
  }) : super._();

  @override
  BindingState createState(GameEngine game) => CompositeBindingState(
    game,
    up.createState(game),
    down.createState(game),
    left.createState(game),
    right.createState(game),
  );

  @override
  bool isPressed(GameEngine game) =>
      up.isPressed(game) ||
      down.isPressed(game) ||
      left.isPressed(game) ||
      right.isPressed(game);
  @override
  bool wasPressedThisFrame(GameEngine game) =>
      up.wasPressedThisFrame(game) ||
      down.wasPressedThisFrame(game) ||
      left.wasPressedThisFrame(game) ||
      right.wasPressedThisFrame(game);
  @override
  bool wasReleasedThisFrame(GameEngine game) =>
      up.wasReleasedThisFrame(game) ||
      down.wasReleasedThisFrame(game) ||
      left.wasReleasedThisFrame(game) ||
      right.wasReleasedThisFrame(game);
  @override
  double magnitude(GameEngine game) {
    final u = up.magnitude(game);
    final d = down.magnitude(game);
    final l = left.magnitude(game);
    final r = right.magnitude(game);
    return Offset(r - l, d - u).distance.clamp(0.0, 1.0);
  }

  @override
  T readValue<T>(GameEngine game) {
    if (T == Offset) {
      final u = up.magnitude(game);
      final d = down.magnitude(game);
      final l = left.magnitude(game);
      final r = right.magnitude(game);
      return Offset(r - l, d - u) as T;
    }
    return InputSystem.getDefaultValue<T>();
  }
}

class CompositeBindingState extends BindingState {
  final BindingState up, down, left, right;

  CompositeBindingState(super.game, this.up, this.down, this.left, this.right);

  @override
  Object? read() {
    double x = 0, y = 0;
    if (up.isPressed) y += 1;
    if (down.isPressed) y -= 1;
    if (left.isPressed) x -= 1;
    if (right.isPressed) x += 1;
    return Offset(x, y);
  }

  @override
  double get magnitude => (read() as Offset).distance;
  @override
  bool get isPressed => magnitude > 0;
  @override
  InputControl? get activeControl {
    return up.activeControl ??
        down.activeControl ??
        left.activeControl ??
        right.activeControl;
  }

  @override
  bool get wasReleasedThisFrame =>
      up.wasReleasedThisFrame ||
      down.wasReleasedThisFrame ||
      left.wasReleasedThisFrame ||
      right.wasReleasedThisFrame;
  @override
  bool get wasReleasedThisDynamicUpdate =>
      up.wasReleasedThisDynamicUpdate ||
      down.wasReleasedThisDynamicUpdate ||
      left.wasReleasedThisDynamicUpdate ||
      right.wasReleasedThisDynamicUpdate;
  @override
  bool get wasPressedThisFrame =>
      up.wasPressedThisFrame ||
      down.wasPressedThisFrame ||
      left.wasPressedThisFrame ||
      right.wasPressedThisFrame;
  @override
  bool get wasPressedThisDynamicUpdate =>
      up.wasPressedThisDynamicUpdate ||
      down.wasPressedThisDynamicUpdate ||
      left.wasPressedThisDynamicUpdate ||
      right.wasPressedThisDynamicUpdate;
}

/// A high-level logical input that abstracts hardware into game actions.
///
/// [InputAction] is the primary way to handle user interaction. It can be
/// bound to multiple physical sources via [bindings] and notifies
/// listeners when its state changes.
///
/// ```dart
/// final moveAction = InputAction(
///   game: game,
///   name: 'Move',
///   type: InputActionType.value,
///   bindings: [
///     InputBinding.composite(
///       up: keyboard.up,
///       down: keyboard.down,
///       left: keyboard.left,
///       right: keyboard.right,
///     ),
///   ],
/// );
/// ```
class InputAction extends Behavior with LifecycleListener, MultiComponent {
  /// The human-readable name of the action.
  ///
  /// Used for debugging and identifying the action in registries.
  @override
  String name = '';

  /// The logic type determining how input triggers the action.
  InputActionType type = InputActionType.button;

  List<InputBinding> _bindings = [];

  /// The set of controls that can trigger this action.
  ///
  /// Allows multiple hardware sources to trigger the same game action.
  List<InputBinding> get bindings => _bindings;

  /// Sets the bindings for this action and refreshes runtime states if mounted.
  set bindings(List<InputBinding> value) {
    _bindings = value;
    if (isAttached) {
      _recreateRuntimeStates();
    }
  }

  final List<BindingState> _runtimeStates = [];

  bool _enabled = true;
  InputActionPhase _phase = InputActionPhase.waiting;
  InputControl? _activeControl;

  int _lastUpdateStarted = -1;
  int _lastUpdatePerformed = -1;
  int _lastUpdateCanceled = -1;
  int _lastFrameStarted = -1;
  int _lastFramePerformed = -1;
  int _lastFrameCanceled = -1;

  final InputEvent _started = InputEvent();
  final InputEvent _performed = InputEvent();
  final InputEvent _canceled = InputEvent();

  /// Event triggered when the action enters the [InputActionPhase.started] phase.
  ///
  /// Usually fired when a key is first pressed or a threshold is crossed.
  InputEvent get started => _started;

  /// Event triggered when the action enters the [InputActionPhase.performed] phase.
  ///
  /// Fired when the action logic is fully satisfied (e.g., full press).
  InputEvent get performed => _performed;

  /// Event triggered when the action enters the [InputActionPhase.canceled] phase.
  ///
  /// Fired when input is released or the action is interrupted.
  InputEvent get canceled => _canceled;

  /// Internal setter for the started event.
  ///
  /// * [value]: The new event instance.
  set started(InputEvent value) {}

  /// Internal setter for the performed event.
  ///
  /// * [value]: The new event instance.
  set performed(InputEvent value) {}

  /// Internal setter for the canceled event.
  ///
  /// * [value]: The new event instance.
  set canceled(InputEvent value) {}

  /// Initializes the action with the specified metadata and bindings.
  ///
  /// * [name]: Descriptive name for the action.
  /// * [type]: Behavior type.
  /// * [bindings]: Initial set of input bindings.
  InputAction();

  @override
  bool get enabled => _enabled;

  @override
  set enabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    if (!value) {
      _phase = InputActionPhase.waiting;
    }
    if (isAttached) {
      if (value) {
        game.getSystem<InputSystem>()?._registerAction(this);
      } else {
        game.getSystem<InputSystem>()?._unregisterAction(this);
      }
    }
  }

  @override
  void onMounted() {
    _recreateRuntimeStates();
    if (enabled) {
      game.getSystem<InputSystem>()?._registerAction(this);
    }
  }

  void _recreateRuntimeStates() {
    _runtimeStates.clear();
    for (var b in _bindings) {
      _runtimeStates.add(b.createState(game));
    }
  }

  @override
  void onUnmounted() {
    if (enabled) {
      game.getSystem<InputSystem>()?._unregisterAction(this);
    }
  }

  /// The current phase of the action in the game loop.
  ///
  /// Tracks the transition through [InputActionPhase] states.
  InputActionPhase get phase => _phase;

  /// Whether the action was triggered exactly in this frame.
  ///
  /// Returns true if [wasPerformedThisFrame] is true.
  bool get triggered => wasPerformedThisFrame;

  /// Whether the action is in the middle of being performed.
  ///
  /// True if phase is [InputActionPhase.started] or [InputActionPhase.performed].
  bool get inProgress =>
      _phase == InputActionPhase.started ||
      _phase == InputActionPhase.performed;

  /// The specific [InputControl] currently driving the action value.
  ///
  /// Returns the control from the first active binding that satisfies
  /// the action type.
  InputControl? get activeControl => _activeControl;

  /// Whether the action entered the started phase this frame.
  ///
  /// Checks the frame timestamp against the engine's current frame.
  bool get wasPressedThisFrame =>
      _lastFrameStarted == game.getSystem<TickerState>()?.frameCount;

  /// Whether the action was performed this frame.
  ///
  /// Checks the frame timestamp against the engine's current frame.
  bool get wasPerformedThisFrame =>
      _lastFramePerformed == game.getSystem<TickerState>()?.frameCount;

  /// Whether the action was canceled this frame.
  ///
  /// Checks the frame timestamp against the engine's current frame.
  bool get wasCanceledThisFrame =>
      _lastFrameCanceled == game.getSystem<TickerState>()?.frameCount;

  /// Alias for [wasCanceledThisFrame].
  ///
  /// Provided for semantic clarity in different action contexts.
  bool get wasCompletedThisFrame => wasCanceledThisFrame;

  /// Whether any binding was released in this frame.
  ///
  /// Returns true if at least one bound control was released in the current tick.
  bool get wasReleasedThisFrame {
    for (var b in _runtimeStates) {
      if (b.wasReleasedThisFrame) return true;
    }
    return false;
  }

  /// Whether the action entered the started phase in this update tick.
  ///
  /// Checks the dynamic update count against the engine's input system.
  bool get wasPressedThisDynamicUpdate =>
      _lastUpdateStarted == game.getSystem<InputSystem>()?.dynamicUpdateCount;

  /// Whether the action was performed in this update tick.
  ///
  /// Checks the dynamic update count against the engine's input system.
  bool get wasPerformedThisDynamicUpdate =>
      _lastUpdatePerformed == game.getSystem<InputSystem>()?.dynamicUpdateCount;

  /// Whether the action was canceled in this update tick.
  ///
  /// Checks the dynamic update count against the engine's input system.
  bool get wasCanceledThisDynamicUpdate =>
      _lastUpdateCanceled == game.getSystem<InputSystem>()?.dynamicUpdateCount;

  /// Alias for [wasCanceledThisDynamicUpdate].
  ///
  /// Provided for semantic clarity in different action contexts.
  bool get wasCompletedThisDynamicUpdate => wasCanceledThisDynamicUpdate;

  /// Whether any binding was released in this update tick.
  ///
  /// Returns true if at least one bound control was released in this tick.
  bool get wasReleasedThisDynamicUpdate {
    for (var b in _runtimeStates) {
      if (b.wasReleasedThisDynamicUpdate) return true;
    }
    return false;
  }

  /// Enables the action to start processing input.
  ///
  /// Once enabled, the action will begin listening to its [bindings] during
  /// the next [InputSystem.update] cycle.
  void enable() => enabled = true;

  /// Disables the action and resets its phase to waiting.
  ///
  /// Stops all input processing and immediately transitions the phase
  /// to [InputActionPhase.waiting]. No further events will fire until
  /// the action is re-enabled.
  void disable() {
    enabled = false;
    _phase = InputActionPhase.waiting;
  }

  /// Reads the current value of the action from the active binding.
  ///
  /// Iterates through [bindings] and returns the first valid value cast
  /// to [T]. If no bindings are active or the action is disabled,
  /// returns the default value for [T].
  ///
  /// * [T]: The expected value type.
  T readValue<T>() {
    if (!_enabled) return InputSystem.getDefaultValue<T>();
    for (var state in _runtimeStates) {
      final val = state.asValue<T>();
      if (val != null) return val;
    }
    return InputSystem.getDefaultValue<T>();
  }

  /// Calculates the maximum magnitude across all bindings.
  ///
  /// Iterates through [bindings] and finds the highest magnitude value.
  /// Used to determine if the action should transition to the started phase.
  double _getMagnitude() {
    double maxMag = 0;
    for (var b in _runtimeStates) {
      final mag = b.magnitude;
      if (mag > maxMag) maxMag = mag;
    }
    return maxMag;
  }

  /// Internal state machine for action phases.
  ///
  /// Processes the [currentlyPressed] state and triggers the corresponding
  /// [InputEvent]s for the action.
  void _updatePhase() {
    bool currentlyPressed = false;
    InputControl? drivingControl;

    for (var b in _runtimeStates) {
      if (b.isPressed) {
        currentlyPressed = true;
        drivingControl = b.activeControl;
        break;
      }
    }

    final updateCount = game.getSystem<InputSystem>()?.dynamicUpdateCount ?? -1;
    final currentFrame = game.getSystem<TickerState>()?.frameCount ?? -1;

    if (_phase == InputActionPhase.waiting && currentlyPressed) {
      _phase = InputActionPhase.started;
      _activeControl = drivingControl;
      _lastUpdateStarted = updateCount;
      _lastFrameStarted = currentFrame;
      started.invoke(CallbackContext(this, _phase));

      if (type == InputActionType.button) {
        _phase = InputActionPhase.performed;
        _lastUpdatePerformed = updateCount;
        _lastFramePerformed = currentFrame;
        performed.invoke(CallbackContext(this, _phase));
      }
    } else if (_phase == InputActionPhase.started &&
        type == InputActionType.value) {
      _phase = InputActionPhase.performed;
      _lastUpdatePerformed = updateCount;
      _lastFramePerformed = currentFrame;
      performed.invoke(CallbackContext(this, _phase));
    } else if (_phase == InputActionPhase.performed) {
      if (!currentlyPressed) {
        _phase = InputActionPhase.canceled;
        _lastUpdateCanceled = updateCount;
        _lastFrameCanceled = currentFrame;
        canceled.invoke(CallbackContext(this, _phase));
        _phase = InputActionPhase.waiting;
        _activeControl = null;
      } else {
        _activeControl = drivingControl;
        if (type == InputActionType.value) {
          _lastUpdatePerformed = updateCount;
          _lastFramePerformed = currentFrame;
        }
      }
    }
  }

  /// This also unregisters the action from the [InputSystem] if mounted.
  void dispose() {
    disable();
    _started.dispose();
    _performed.dispose();
    _canceled.dispose();
  }
}
