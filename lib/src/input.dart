import 'package:flutter/services.dart';
import 'package:goo2d/goo2d.dart';
import 'package:vector_math/vector_math_64.dart' show Vector2;

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
    for (var listener in _listeners) {
      listener(context);
    }
  }

  void dispose() => _listeners.clear();
}

class InputSystem {
  static final KeyboardDevice _keyboardDevice = KeyboardDevice();
  static bool _initialized = false;
  static final List<InputAction> _actions = [];
  static int dynamicUpdateCount = 0;

  static final Map<Type, Object Function()> _defaultValues = {
    bool: () => false,
    double: () => 0.0,
    Vector2: () => Vector2.zero(),
  };

  static void registerDefaultValue<T extends Object>(T Function() provider) =>
      _defaultValues[T] = provider;
  static T getDefaultValue<T>() {
    final provider = _defaultValues[T];
    if (provider == null) throw UnimplementedError('No default value for $T');
    return provider() as T;
  }

  static void init() {
    if (_initialized) return;
    _initialized = true;
    ServicesBinding.instance.keyboard.addHandler((event) {
      if (event is KeyDownEvent) {
        _keyboardDevice[event.logicalKey].press();
      } else if (event is KeyUpEvent) {
        _keyboardDevice[event.logicalKey].release();
      }
      return false;
    });
  }

  static void _registerAction(InputAction action) => _actions.add(action);
  static void _unregisterAction(InputAction action) => _actions.remove(action);

  static void update() {
    dynamicUpdateCount++;
    for (var action in _actions) {
      if (action.enabled) action._updatePhase();
    }
  }
}

abstract class InputControl<T> {
  T get value;
  double get magnitude;
  int lastFramePressed = -1;
  int lastFrameReleased = -1;
  int lastUpdateReleased = -1;
  bool get isPressed;
}

class ButtonControl extends InputControl<bool> {
  bool _isPressed = false;
  @override
  bool get value => _isPressed;
  @override
  bool get isPressed => _isPressed;
  @override
  double get magnitude => _isPressed ? 1.0 : 0.0;

  void press() {
    if (!_isPressed) lastFramePressed = frameCount;
    _isPressed = true;
  }

  void release() {
    if (_isPressed) {
      lastFrameReleased = frameCount;
      lastUpdateReleased = InputSystem.dynamicUpdateCount;
    }
    _isPressed = false;
  }
}

class KeyboardDevice {
  final Map<LogicalKeyboardKey, ButtonControl> _keys = {};
  ButtonControl operator [](LogicalKeyboardKey key) =>
      _keys.putIfAbsent(key, () => ButtonControl());
}

abstract class InputBinding {
  InputBinding._();
  Object? read();
  double get magnitude;
  bool get isPressed;
  InputControl? get activeControl;
  bool get wasReleasedThisFrame;
  bool get wasReleasedThisDynamicUpdate;

  // Polymorphic cast to avoid 'is T' checks in the core loop
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
  }) = Vector2CompositeBinding;
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
  bool get wasReleasedThisFrame => control.lastFrameReleased == frameCount;
  @override
  bool get wasReleasedThisDynamicUpdate =>
      control.lastUpdateReleased == InputSystem.dynamicUpdateCount;
}

class Vector2CompositeBinding extends InputBinding {
  final ButtonControl up, down, left, right;
  Vector2CompositeBinding({
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
    return Vector2(x, y);
  }

  @override
  double get magnitude => (read() as Vector2).length;
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
      up.lastFrameReleased == frameCount ||
      down.lastFrameReleased == frameCount ||
      left.lastFrameReleased == frameCount ||
      right.lastFrameReleased == frameCount;
  @override
  bool get wasReleasedThisDynamicUpdate =>
      up.lastUpdateReleased == InputSystem.dynamicUpdateCount ||
      down.lastUpdateReleased == InputSystem.dynamicUpdateCount ||
      left.lastUpdateReleased == InputSystem.dynamicUpdateCount ||
      right.lastUpdateReleased == InputSystem.dynamicUpdateCount;
}

class InputAction {
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
    required this.name,
    this.type = InputActionType.button,
    this.bindings = const [],
  }) {
    InputSystem._registerAction(this);
  }

  InputActionPhase get phase => _phase;
  bool get enabled => _enabled;
  bool get triggered => wasPerformedThisFrame;
  bool get inProgress =>
      _phase == InputActionPhase.started ||
      _phase == InputActionPhase.performed;
  InputControl? get activeControl => _activeControl;

  bool get wasPressedThisFrame => _lastFrameStarted == frameCount;
  bool get wasPerformedThisFrame => _lastFramePerformed == frameCount;
  bool get wasCompletedThisFrame => _lastFrameCanceled == frameCount;
  bool get wasReleasedThisFrame {
    for (var b in bindings) {
      if (b.wasReleasedThisFrame) return true;
    }
    return false;
  }

  bool get wasPressedThisDynamicUpdate =>
      _lastUpdateStarted == InputSystem.dynamicUpdateCount;
  bool get wasPerformedThisDynamicUpdate =>
      _lastUpdatePerformed == InputSystem.dynamicUpdateCount;
  bool get wasCompletedThisDynamicUpdate =>
      _lastUpdateCanceled == InputSystem.dynamicUpdateCount;
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

    final updateCount = InputSystem.dynamicUpdateCount;
    final currentFrame = frameCount;

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
    InputSystem._unregisterAction(this);
    _started.dispose();
    _performed.dispose();
    _canceled.dispose();
  }
}
