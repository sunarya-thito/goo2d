import 'package:flutter/services.dart';
import 'package:goo2d/goo2d.dart';

part 'keyboard.dart';

enum InputActionPhase { disabled, waiting, started, performed, canceled }

enum InputActionType { value, button, passThrough }

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
    for (var listener in List<void Function(CallbackContext)>.from(_listeners)) {
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
  int lastUpdateReleased = -1;
  bool get isPressed;
  bool get wasPressedThisFrame => lastFramePressed == game.ticker.frameCount;
  bool get wasReleasedThisFrame => lastFrameReleased == game.ticker.frameCount;
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
    if (!_isPressed) lastFramePressed = game.ticker.frameCount;
    _isPressed = true;
  }

  void release() {
    if (_isPressed) {
      lastFrameReleased = game.ticker.frameCount;
      lastUpdateReleased = game.input.dynamicUpdateCount;
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

  // Helper properties for common keys
  ButtonControl get space => this[LogicalKeyboardKey.space];
  ButtonControl get enter => this[LogicalKeyboardKey.enter];
  ButtonControl get escape => this[LogicalKeyboardKey.escape];
  ButtonControl get left => this[LogicalKeyboardKey.arrowLeft];
  ButtonControl get right => this[LogicalKeyboardKey.arrowRight];
  ButtonControl get up => this[LogicalKeyboardKey.arrowUp];
  ButtonControl get down => this[LogicalKeyboardKey.arrowDown];
  ButtonControl get keyA => this[LogicalKeyboardKey.keyA];
  ButtonControl get keyD => this[LogicalKeyboardKey.keyD];
  ButtonControl get keyS => this[LogicalKeyboardKey.keyS];
  ButtonControl get keyW => this[LogicalKeyboardKey.keyW];
}

abstract class InputBinding {
  InputBinding._();
  Object? read();
  double get magnitude;
  bool get isPressed;
  InputControl? get activeControl;
  bool get wasReleasedThisFrame;
  bool get wasReleasedThisDynamicUpdate;

  T? asValue<T>() {
    final val = read();
    try {
      return val as T;
    } catch (_) {
      return null;
    }
  }

  factory InputBinding({required InputControl control}) = SimpleInputBinding;
  factory InputBinding.composite({
    required ButtonControl up,
    required ButtonControl down,
    required ButtonControl left,
    required ButtonControl right,
  }) = CompositeBinding;
}

class SimpleInputBinding extends InputBinding {
  final InputControl control;
  SimpleInputBinding({required this.control}) : super._();

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
      control.lastUpdateReleased == control.game.input.dynamicUpdateCount;
}

class CompositeBinding extends InputBinding {
  final ButtonControl up, down, left, right;
  CompositeBinding({
    required this.up,
    required this.down,
    required this.left,
    required this.right,
  }) : super._();

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
    if (up.isPressed) return up;
    if (down.isPressed) return down;
    if (left.isPressed) return left;
    if (right.isPressed) return right;
    return null;
  }

  @override
  bool get wasReleasedThisFrame =>
      up.lastFrameReleased == up.game.ticker.frameCount ||
      down.lastFrameReleased == down.game.ticker.frameCount ||
      left.lastFrameReleased == left.game.ticker.frameCount ||
      right.lastFrameReleased == right.game.ticker.frameCount;
  @override
  bool get wasReleasedThisDynamicUpdate =>
      up.lastUpdateReleased == up.game.input.dynamicUpdateCount ||
      down.lastUpdateReleased == down.game.input.dynamicUpdateCount ||
      left.lastUpdateReleased == left.game.input.dynamicUpdateCount ||
      right.lastUpdateReleased == right.game.input.dynamicUpdateCount;
}

class InputAction {
  final GameEngine game;
  final String name;
  final InputActionType type;
  final List<InputBinding> bindings;

  bool _enabled = false;
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

  InputAction({
    required this.game,
    required this.name,
    this.type = InputActionType.button,
    this.bindings = const [],
  }) {
    game.input._registerAction(this);
  }

  InputActionPhase get phase => _phase;
  bool get enabled => _enabled;
  bool get triggered => wasPerformedThisFrame;
  bool get inProgress =>
      _phase == InputActionPhase.started ||
      _phase == InputActionPhase.performed;
  InputControl? get activeControl => _activeControl;

  bool get wasPressedThisFrame => _lastFrameStarted == game.ticker.frameCount;
  bool get wasPerformedThisFrame =>
      _lastFramePerformed == game.ticker.frameCount;
  bool get wasCanceledThisFrame => _lastFrameCanceled == game.ticker.frameCount;
  bool get wasCompletedThisFrame => wasCanceledThisFrame;
  bool get wasReleasedThisFrame {
    for (var b in bindings) {
      if (b.wasReleasedThisFrame) return true;
    }
    return false;
  }

  bool get wasPressedThisDynamicUpdate =>
      _lastUpdateStarted == game.input.dynamicUpdateCount;
  bool get wasPerformedThisDynamicUpdate =>
      _lastUpdatePerformed == game.input.dynamicUpdateCount;
  bool get wasCanceledThisDynamicUpdate =>
      _lastUpdateCanceled == game.input.dynamicUpdateCount;
  bool get wasCompletedThisDynamicUpdate => wasCanceledThisDynamicUpdate;
  bool get wasReleasedThisDynamicUpdate {
    for (var b in bindings) {
      if (b.wasReleasedThisDynamicUpdate) return true;
    }
    return false;
  }

  void enable() => _enabled = true;
  void disable() {
    _enabled = false;
    _phase = InputActionPhase.waiting;
  }

  T readValue<T>() {
    if (!_enabled) return InputSystem.getDefaultValue<T>();
    for (var binding in bindings) {
      final val = binding.asValue<T>();
      if (val != null) return val;
    }
    return InputSystem.getDefaultValue<T>();
  }

  double _getMagnitude() {
    double maxMag = 0;
    for (var b in bindings) {
      final mag = b.magnitude;
      if (mag > maxMag) maxMag = mag;
    }
    return maxMag;
  }

  void _updatePhase() {
    bool currentlyPressed = false;
    InputControl? drivingControl;

    for (var b in bindings) {
      if (b.isPressed) {
        currentlyPressed = true;
        drivingControl = b.activeControl;
        break;
      }
    }

    final updateCount = game.input.dynamicUpdateCount;
    final currentFrame = game.ticker.frameCount;

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
    game.input._unregisterAction(this);
    _started.dispose();
    _performed.dispose();
    _canceled.dispose();
  }
}
