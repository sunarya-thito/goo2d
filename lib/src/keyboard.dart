part of 'input.dart';

/// Static-access class for all keyboard keys.
class Keyboard {
  static ButtonControl _key(LogicalKeyboardKey key) =>
      InputSystem._keyboardDevice[key];

  static ButtonControl get space => _key(LogicalKeyboardKey.space);
  static ButtonControl get enter => _key(LogicalKeyboardKey.enter);
  static ButtonControl get escape => _key(LogicalKeyboardKey.escape);

  static ButtonControl get w => _key(LogicalKeyboardKey.keyW);
  static ButtonControl get a => _key(LogicalKeyboardKey.keyA);
  static ButtonControl get s => _key(LogicalKeyboardKey.keyS);
  static ButtonControl get d => _key(LogicalKeyboardKey.keyD);

  static ButtonControl get upArrow => _key(LogicalKeyboardKey.arrowUp);
  static ButtonControl get downArrow => _key(LogicalKeyboardKey.arrowDown);
  static ButtonControl get leftArrow => _key(LogicalKeyboardKey.arrowLeft);
  static ButtonControl get rightArrow => _key(LogicalKeyboardKey.arrowRight);

  static ButtonControl get q => _key(LogicalKeyboardKey.keyQ);
  static ButtonControl get e => _key(LogicalKeyboardKey.keyE);
  static ButtonControl get r => _key(LogicalKeyboardKey.keyR);
  static ButtonControl get f => _key(LogicalKeyboardKey.keyF);

  static ButtonControl get shift => _key(LogicalKeyboardKey.shiftLeft);
  static ButtonControl get ctrl => _key(LogicalKeyboardKey.controlLeft);
  static ButtonControl get alt => _key(LogicalKeyboardKey.altLeft);

  static ButtonControl get backspace => _key(LogicalKeyboardKey.backspace);
  static ButtonControl get tab => _key(LogicalKeyboardKey.tab);

  static ButtonControl get digit0 => _key(LogicalKeyboardKey.digit0);
  static ButtonControl get digit1 => _key(LogicalKeyboardKey.digit1);
  static ButtonControl get digit2 => _key(LogicalKeyboardKey.digit2);
  static ButtonControl get digit3 => _key(LogicalKeyboardKey.digit3);
  static ButtonControl get digit4 => _key(LogicalKeyboardKey.digit4);
  static ButtonControl get digit5 => _key(LogicalKeyboardKey.digit5);
  static ButtonControl get digit6 => _key(LogicalKeyboardKey.digit6);
  static ButtonControl get digit7 => _key(LogicalKeyboardKey.digit7);
  static ButtonControl get digit8 => _key(LogicalKeyboardKey.digit8);
  static ButtonControl get digit9 => _key(LogicalKeyboardKey.digit9);
}
