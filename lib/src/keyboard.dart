part of 'input.dart';

/// A centralized collection of pre-defined [InputBinding]s for keyboard keys.
///
/// The [Keyboard] class provides an ergonomic and type-safe layer over the
/// standard Flutter [LogicalKeyboardKey] system. By providing pre-defined
/// [InputBinding] constants, it allows developers to configure [InputAction]s
/// with minimal boilerplate while ensuring that all keyboard interactions
/// follow a consistent, declarative pattern.
///
/// Using these constants is preferred over manual [InputBinding.key] creation
/// as it enables better IDE auto-completion and ensures that bindings are
/// consistent across different parts of the application logic.
///
/// ```dart
/// // Configuring a multi-binding action for character movement
/// final moveAction = InputAction()
///   ..bindings = [
///     Keyboard.keyW,    // Primary: W key
///     Keyboard.upArrow, // Secondary: Up Arrow
///   ];
/// ```
///
/// See also:
/// * [InputBinding], the core class for mapping raw input to actions.
/// * [InputAction], the component that processes these bindings.
class Keyboard {
  Keyboard._();
  /// Pre-defined binding for the [LogicalKeyboardKey.space] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding space = InputBinding.key(LogicalKeyboardKey.space);
  /// Pre-defined binding for the [LogicalKeyboardKey.enter] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding enter = InputBinding.key(LogicalKeyboardKey.enter);
  /// Pre-defined binding for the [LogicalKeyboardKey.escape] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding escape = InputBinding.key(
    LogicalKeyboardKey.escape,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.backspace] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding backspace = InputBinding.key(
    LogicalKeyboardKey.backspace,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.tab] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding tab = InputBinding.key(LogicalKeyboardKey.tab);

  // Letters
  /// Pre-defined binding for the [LogicalKeyboardKey.keyA] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding keyA = InputBinding.key(LogicalKeyboardKey.keyA);
  /// Pre-defined binding for the [LogicalKeyboardKey.keyB] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding keyB = InputBinding.key(LogicalKeyboardKey.keyB);
  /// Pre-defined binding for the [LogicalKeyboardKey.keyC] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding keyC = InputBinding.key(LogicalKeyboardKey.keyC);
  /// Pre-defined binding for the [LogicalKeyboardKey.keyD] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding keyD = InputBinding.key(LogicalKeyboardKey.keyD);
  /// Pre-defined binding for the [LogicalKeyboardKey.keyE] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding keyE = InputBinding.key(LogicalKeyboardKey.keyE);
  /// Pre-defined binding for the [LogicalKeyboardKey.keyF] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding keyF = InputBinding.key(LogicalKeyboardKey.keyF);
  /// Pre-defined binding for the [LogicalKeyboardKey.keyG] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding keyG = InputBinding.key(LogicalKeyboardKey.keyG);
  /// Pre-defined binding for the [LogicalKeyboardKey.keyH] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding keyH = InputBinding.key(LogicalKeyboardKey.keyH);
  /// Pre-defined binding for the [LogicalKeyboardKey.keyI] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding keyI = InputBinding.key(LogicalKeyboardKey.keyI);
  /// Pre-defined binding for the [LogicalKeyboardKey.keyJ] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding keyJ = InputBinding.key(LogicalKeyboardKey.keyJ);
  /// Pre-defined binding for the [LogicalKeyboardKey.keyK] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding keyK = InputBinding.key(LogicalKeyboardKey.keyK);
  /// Pre-defined binding for the [LogicalKeyboardKey.keyL] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding keyL = InputBinding.key(LogicalKeyboardKey.keyL);
  /// Pre-defined binding for the [LogicalKeyboardKey.keyM] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding keyM = InputBinding.key(LogicalKeyboardKey.keyM);
  /// Pre-defined binding for the [LogicalKeyboardKey.keyN] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding keyN = InputBinding.key(LogicalKeyboardKey.keyN);
  /// Pre-defined binding for the [LogicalKeyboardKey.keyO] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding keyO = InputBinding.key(LogicalKeyboardKey.keyO);
  /// Pre-defined binding for the [LogicalKeyboardKey.keyP] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding keyP = InputBinding.key(LogicalKeyboardKey.keyP);
  /// Pre-defined binding for the [LogicalKeyboardKey.keyQ] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding keyQ = InputBinding.key(LogicalKeyboardKey.keyQ);
  /// Pre-defined binding for the [LogicalKeyboardKey.keyR] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding keyR = InputBinding.key(LogicalKeyboardKey.keyR);
  /// Pre-defined binding for the [LogicalKeyboardKey.keyS] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding keyS = InputBinding.key(LogicalKeyboardKey.keyS);
  /// Pre-defined binding for the [LogicalKeyboardKey.keyT] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding keyT = InputBinding.key(LogicalKeyboardKey.keyT);
  /// Pre-defined binding for the [LogicalKeyboardKey.keyU] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding keyU = InputBinding.key(LogicalKeyboardKey.keyU);
  /// Pre-defined binding for the [LogicalKeyboardKey.keyV] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding keyV = InputBinding.key(LogicalKeyboardKey.keyV);
  /// Pre-defined binding for the [LogicalKeyboardKey.keyW] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding keyW = InputBinding.key(LogicalKeyboardKey.keyW);
  /// Pre-defined binding for the [LogicalKeyboardKey.keyX] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding keyX = InputBinding.key(LogicalKeyboardKey.keyX);
  /// Pre-defined binding for the [LogicalKeyboardKey.keyY] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding keyY = InputBinding.key(LogicalKeyboardKey.keyY);
  /// Pre-defined binding for the [LogicalKeyboardKey.keyZ] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding keyZ = InputBinding.key(LogicalKeyboardKey.keyZ);

  // Digits
  /// Pre-defined binding for the [LogicalKeyboardKey.digit0] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding digit0 = InputBinding.key(
    LogicalKeyboardKey.digit0,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.digit1] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding digit1 = InputBinding.key(
    LogicalKeyboardKey.digit1,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.digit2] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding digit2 = InputBinding.key(
    LogicalKeyboardKey.digit2,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.digit3] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding digit3 = InputBinding.key(
    LogicalKeyboardKey.digit3,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.digit4] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding digit4 = InputBinding.key(
    LogicalKeyboardKey.digit4,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.digit5] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding digit5 = InputBinding.key(
    LogicalKeyboardKey.digit5,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.digit6] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding digit6 = InputBinding.key(
    LogicalKeyboardKey.digit6,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.digit7] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding digit7 = InputBinding.key(
    LogicalKeyboardKey.digit7,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.digit8] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding digit8 = InputBinding.key(
    LogicalKeyboardKey.digit8,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.digit9] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding digit9 = InputBinding.key(
    LogicalKeyboardKey.digit9,
  );

  // Arrows
  /// Pre-defined binding for the [LogicalKeyboardKey.arrowUp] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding upArrow = InputBinding.key(
    LogicalKeyboardKey.arrowUp,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.arrowDown] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding downArrow = InputBinding.key(
    LogicalKeyboardKey.arrowDown,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.arrowLeft] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding leftArrow = InputBinding.key(
    LogicalKeyboardKey.arrowLeft,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.arrowRight] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding rightArrow = InputBinding.key(
    LogicalKeyboardKey.arrowRight,
  );

  // Modifiers
  /// Pre-defined binding for the [LogicalKeyboardKey.shiftLeft] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding shift = InputBinding.key(
    LogicalKeyboardKey.shiftLeft,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.shiftRight] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding shiftRight = InputBinding.key(
    LogicalKeyboardKey.shiftRight,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.controlLeft] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding ctrl = InputBinding.key(
    LogicalKeyboardKey.controlLeft,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.controlRight] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding ctrlRight = InputBinding.key(
    LogicalKeyboardKey.controlRight,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.altLeft] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding alt = InputBinding.key(LogicalKeyboardKey.altLeft);
  /// Pre-defined binding for the [LogicalKeyboardKey.altRight] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding altRight = InputBinding.key(
    LogicalKeyboardKey.altRight,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.metaLeft] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding meta = InputBinding.key(
    LogicalKeyboardKey.metaLeft,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.metaRight] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding metaRight = InputBinding.key(
    LogicalKeyboardKey.metaRight,
  );

  // Function Keys
  /// Pre-defined binding for the [LogicalKeyboardKey.f1] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding f1 = InputBinding.key(LogicalKeyboardKey.f1);
  /// Pre-defined binding for the [LogicalKeyboardKey.f2] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding f2 = InputBinding.key(LogicalKeyboardKey.f2);
  /// Pre-defined binding for the [LogicalKeyboardKey.f3] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding f3 = InputBinding.key(LogicalKeyboardKey.f3);
  /// Pre-defined binding for the [LogicalKeyboardKey.f4] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding f4 = InputBinding.key(LogicalKeyboardKey.f4);
  /// Pre-defined binding for the [LogicalKeyboardKey.f5] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding f5 = InputBinding.key(LogicalKeyboardKey.f5);
  /// Pre-defined binding for the [LogicalKeyboardKey.f6] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding f6 = InputBinding.key(LogicalKeyboardKey.f6);
  /// Pre-defined binding for the [LogicalKeyboardKey.f7] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding f7 = InputBinding.key(LogicalKeyboardKey.f7);
  /// Pre-defined binding for the [LogicalKeyboardKey.f8] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding f8 = InputBinding.key(LogicalKeyboardKey.f8);
  /// Pre-defined binding for the [LogicalKeyboardKey.f9] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding f9 = InputBinding.key(LogicalKeyboardKey.f9);
  /// Pre-defined binding for the [LogicalKeyboardKey.f10] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding f10 = InputBinding.key(LogicalKeyboardKey.f10);
  /// Pre-defined binding for the [LogicalKeyboardKey.f11] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding f11 = InputBinding.key(LogicalKeyboardKey.f11);
  /// Pre-defined binding for the [LogicalKeyboardKey.f12] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding f12 = InputBinding.key(LogicalKeyboardKey.f12);

  // Numpad
  /// Pre-defined binding for the [LogicalKeyboardKey.numpad0] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding numpad0 = InputBinding.key(
    LogicalKeyboardKey.numpad0,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.numpad1] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding numpad1 = InputBinding.key(
    LogicalKeyboardKey.numpad1,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.numpad2] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding numpad2 = InputBinding.key(
    LogicalKeyboardKey.numpad2,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.numpad3] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding numpad3 = InputBinding.key(
    LogicalKeyboardKey.numpad3,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.numpad4] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding numpad4 = InputBinding.key(
    LogicalKeyboardKey.numpad4,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.numpad5] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding numpad5 = InputBinding.key(
    LogicalKeyboardKey.numpad5,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.numpad6] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding numpad6 = InputBinding.key(
    LogicalKeyboardKey.numpad6,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.numpad7] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding numpad7 = InputBinding.key(
    LogicalKeyboardKey.numpad7,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.numpad8] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding numpad8 = InputBinding.key(
    LogicalKeyboardKey.numpad8,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.numpad9] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding numpad9 = InputBinding.key(
    LogicalKeyboardKey.numpad9,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.numpadDecimal] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding numpadDecimal = InputBinding.key(
    LogicalKeyboardKey.numpadDecimal,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.numpadDivide] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding numpadDivide = InputBinding.key(
    LogicalKeyboardKey.numpadDivide,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.numpadMultiply] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding numpadMultiply = InputBinding.key(
    LogicalKeyboardKey.numpadMultiply,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.numpadSubtract] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding numpadSubtract = InputBinding.key(
    LogicalKeyboardKey.numpadSubtract,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.numpadAdd] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding numpadAdd = InputBinding.key(
    LogicalKeyboardKey.numpadAdd,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.numpadEnter] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding numpadEnter = InputBinding.key(
    LogicalKeyboardKey.numpadEnter,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.numpadEqual] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding numpadEqual = InputBinding.key(
    LogicalKeyboardKey.numpadEqual,
  );

  // Special Keys
  /// Pre-defined binding for the [LogicalKeyboardKey.capsLock] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding capsLock = InputBinding.key(
    LogicalKeyboardKey.capsLock,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.scrollLock] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding scrollLock = InputBinding.key(
    LogicalKeyboardKey.scrollLock,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.numLock] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding numLock = InputBinding.key(
    LogicalKeyboardKey.numLock,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.printScreen] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding printScreen = InputBinding.key(
    LogicalKeyboardKey.printScreen,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.pause] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding pause = InputBinding.key(LogicalKeyboardKey.pause);
  /// Pre-defined binding for the [LogicalKeyboardKey.insert] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding insert = InputBinding.key(
    LogicalKeyboardKey.insert,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.home] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding home = InputBinding.key(LogicalKeyboardKey.home);
  /// Pre-defined binding for the [LogicalKeyboardKey.end] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding end = InputBinding.key(LogicalKeyboardKey.end);
  /// Pre-defined binding for the [LogicalKeyboardKey.pageUp] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding pageUp = InputBinding.key(
    LogicalKeyboardKey.pageUp,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.pageDown] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding pageDown = InputBinding.key(
    LogicalKeyboardKey.pageDown,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.delete] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding delete = InputBinding.key(
    LogicalKeyboardKey.delete,
  );

  // Symbols
  /// Pre-defined binding for the [LogicalKeyboardKey.backquote] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding grave = InputBinding.key(
    LogicalKeyboardKey.backquote,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.minus] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding minus = InputBinding.key(LogicalKeyboardKey.minus);
  /// Pre-defined binding for the [LogicalKeyboardKey.equal] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding equal = InputBinding.key(LogicalKeyboardKey.equal);
  /// Pre-defined binding for the [LogicalKeyboardKey.bracketLeft] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding bracketLeft = InputBinding.key(
    LogicalKeyboardKey.bracketLeft,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.bracketRight] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding bracketRight = InputBinding.key(
    LogicalKeyboardKey.bracketRight,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.backslash] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding backslash = InputBinding.key(
    LogicalKeyboardKey.backslash,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.semicolon] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding semicolon = InputBinding.key(
    LogicalKeyboardKey.semicolon,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.quote] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding quote = InputBinding.key(LogicalKeyboardKey.quote);
  /// Pre-defined binding for the [LogicalKeyboardKey.comma] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding comma = InputBinding.key(LogicalKeyboardKey.comma);
  /// Pre-defined binding for the [LogicalKeyboardKey.period] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding period = InputBinding.key(
    LogicalKeyboardKey.period,
  );
  /// Pre-defined binding for the [LogicalKeyboardKey.slash] key.
  ///
  /// Use this binding to map physical keyboard input to an [InputAction].
  static const InputBinding slash = InputBinding.key(LogicalKeyboardKey.slash);
}
