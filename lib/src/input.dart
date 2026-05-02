import 'package:flutter/services.dart';
import 'package:goo2d/src/game.dart';
import 'package:goo2d/src/component.dart';
import 'package:goo2d/src/lifecycle.dart';

part 'keyboard.dart';

enum InputActionPhase {
  disabled,
  waiting,
  started,
  performed,
  canceled,
}

enum InputActionType {
  value,
  button,
  passThrough,
}

class CallbackContext {
  final InputAction action;
  final InputActionPhase phase;
  T readValue<T>() => action.readValue<T>();
  double get magnitude => action._getMagnitude();
  InputControl? get control => action.activeControl;
  CallbackContext(this.action, this.phase);
}

class InputEvent {
  final List<void Function(CallbackContext)> _listeners = [];
  InputEvent operator +(void Function(CallbackContext) listener) {
    _listeners.add(listener);
    return this;
  }

  InputEvent operator -(void Function(CallbackContext) listener) {
    _listeners.remove(listener);
    return this;
  }

  void invoke(CallbackContext context) {
    for (var listener in List<void Function(CallbackContext)>.from(
      _listeners,
    )) {
      listener(context);
    }
  }

  void dispose() => _listeners.clear();
}

class InputSystem implements GameSystem {
  KeyboardState? _keyboard;
  KeyboardState get keyboard {
    assert(
      _keyboard != null,
      'KeyboardState is not ready. Did you call initialize() on GameEngine?',
    );
    return _keyboard!;
  }

  final List<InputAction> _actions = [];
  int dynamicUpdateCount = 0;
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
  InputSystem();

  @override
  void attach(GameEngine game) {
    _game = game;
    _keyboard = KeyboardState(game);
  }

  static void registerDefaultValue<T extends Object>(T Function() provider) =>
      _defaultValues[T] = provider;
  static T getDefaultValue<T>() {
    final provider = _defaultValues[T];
    if (provider == null) throw UnimplementedError('No default value for $T');
    return provider() as T;
  }

  void _registerAction(InputAction action) => _actions.add(action);
  void _unregisterAction(InputAction action) => _actions.remove(action);
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

abstract class InputControl<T> {
  GameEngine get game;
  T get value;
  double get magnitude;
  int lastFramePressed = -1;
  int lastFrameReleased = -1;
  int lastUpdatePressed = -1;
  int lastUpdateReleased = -1;
  bool get isPressed;
  bool get wasPressedThisFrame =>
      lastFramePressed == game.getSystem<TickerState>()?.frameCount;
  bool get wasReleasedThisFrame =>
      lastFrameReleased == game.getSystem<TickerState>()?.frameCount;
}

class ButtonControl extends InputControl<bool> {
  @override
  final GameEngine game;
  bool _isPressed = false;
  ButtonControl(this.game);

  @override
  bool get value => _isPressed;
  @override
  bool get isPressed => _isPressed;
  @override
  double get magnitude => _isPressed ? 1.0 : 0.0;
  void press() {
    if (!_isPressed) {
      lastFramePressed = game.getSystem<TickerState>()?.frameCount ?? -1;
      lastUpdatePressed =
          game.getSystem<InputSystem>()?.dynamicUpdateCount ?? -1;
    }
    _isPressed = true;
  }

  void release() {
    if (_isPressed) {
      lastFrameReleased = game.getSystem<TickerState>()?.frameCount ?? -1;
      lastUpdateReleased =
          game.getSystem<InputSystem>()?.dynamicUpdateCount ?? -1;
    }
    _isPressed = false;
  }
}

class KeyboardState {
  final GameEngine game;
  final Map<LogicalKeyboardKey, ButtonControl> _keys = {};
  KeyboardState(this.game) {
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }
  ButtonControl operator [](LogicalKeyboardKey key) =>
      _keys.putIfAbsent(key, () => ButtonControl(game));
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

  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
  }
}

abstract class InputBinding {
  const InputBinding._();
  BindingState createState(GameEngine game);
  bool isPressed(GameEngine game);
  bool wasPressedThisFrame(GameEngine game);
  bool wasReleasedThisFrame(GameEngine game);
  double magnitude(GameEngine game);
  T readValue<T>(GameEngine game);
  const factory InputBinding(InputControl control) = SimpleInputBinding;
  const factory InputBinding.key(LogicalKeyboardKey key) = KeyInputBinding;
  const factory InputBinding.composite({
    required InputBinding up,
    required InputBinding down,
    required InputBinding left,
    required InputBinding right,
  }) = CompositeBinding;
}

abstract class BindingState {
  final GameEngine game;
  BindingState(this.game);
  Object? read();
  double get magnitude;
  bool get isPressed;
  InputControl? get activeControl;
  bool get wasReleasedThisFrame;
  bool get wasReleasedThisDynamicUpdate;
  bool get wasPressedThisFrame;
  bool get wasPressedThisDynamicUpdate;
  T? asValue<T>() {
    final val = read();
    try {
      return val as T;
    } catch (_) {
      return null;
    }
  }
}

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
  T readValue<T>(GameEngine game) => control.value is T
      ? control.value as T
      : InputSystem.getDefaultValue<T>();
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
      game.getSystem<InputSystem>()?.keyboard[key].wasReleasedThisFrame ??
      false;
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

class InputAction extends Behavior with LifecycleListener, MultiComponent {
  @override
  String name = '';
  InputActionType type = InputActionType.button;

  List<InputBinding> _bindings = [];
  List<InputBinding> get bindings => _bindings;
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
  InputEvent get started => _started;
  InputEvent get performed => _performed;
  InputEvent get canceled => _canceled;
  set started(InputEvent value) {}
  set performed(InputEvent value) {}
  set canceled(InputEvent value) {}
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

  InputActionPhase get phase => _phase;
  bool get triggered => wasPerformedThisFrame;
  bool get inProgress =>
      _phase == InputActionPhase.started ||
      _phase == InputActionPhase.performed;
  InputControl? get activeControl => _activeControl;
  bool get wasPressedThisFrame =>
      _lastFrameStarted == game.getSystem<TickerState>()?.frameCount;
  bool get wasPerformedThisFrame =>
      _lastFramePerformed == game.getSystem<TickerState>()?.frameCount;
  bool get wasCanceledThisFrame =>
      _lastFrameCanceled == game.getSystem<TickerState>()?.frameCount;
  bool get wasCompletedThisFrame => wasCanceledThisFrame;
  bool get wasReleasedThisFrame {
    for (var b in _runtimeStates) {
      if (b.wasReleasedThisFrame) return true;
    }
    return false;
  }

  bool get wasPressedThisDynamicUpdate =>
      _lastUpdateStarted == game.getSystem<InputSystem>()?.dynamicUpdateCount;
  bool get wasPerformedThisDynamicUpdate =>
      _lastUpdatePerformed == game.getSystem<InputSystem>()?.dynamicUpdateCount;
  bool get wasCanceledThisDynamicUpdate =>
      _lastUpdateCanceled == game.getSystem<InputSystem>()?.dynamicUpdateCount;
  bool get wasCompletedThisDynamicUpdate => wasCanceledThisDynamicUpdate;
  bool get wasReleasedThisDynamicUpdate {
    for (var b in _runtimeStates) {
      if (b.wasReleasedThisDynamicUpdate) return true;
    }
    return false;
  }

  void enable() => enabled = true;
  void disable() {
    enabled = false;
    _phase = InputActionPhase.waiting;
  }

  T readValue<T>() {
    if (!_enabled) return InputSystem.getDefaultValue<T>();
    for (var state in _runtimeStates) {
      final val = state.asValue<T>();
      if (val != null) return val;
    }
    return InputSystem.getDefaultValue<T>();
  }

  double _getMagnitude() {
    double maxMag = 0;
    for (var b in _runtimeStates) {
      final mag = b.magnitude;
      if (mag > maxMag) maxMag = mag;
    }
    return maxMag;
  }

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

  void dispose() {
    disable();
    _started.dispose();
    _performed.dispose();
    _canceled.dispose();
  }
}
