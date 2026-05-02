part of 'input.dart';

/// Provides static access to keyboard [InputBinding]s.
/// 
/// This class enables a clean, declarative syntax for defining input 
/// bindings without requiring a live [GameEngine] instance at definition time.
/// 
/// ```dart
/// bindings = [Keyboard.space];
/// ```
class Keyboard {
  Keyboard._();

  /// The Space key.
  static const InputBinding space = InputBinding.key(LogicalKeyboardKey.space);
  /// The Enter key.
  static const InputBinding enter = InputBinding.key(LogicalKeyboardKey.enter);
  /// The Escape key.
  static const InputBinding escape = InputBinding.key(LogicalKeyboardKey.escape);
  /// The Backspace key.
  static const InputBinding backspace = InputBinding.key(LogicalKeyboardKey.backspace);
  /// The Tab key.
  static const InputBinding tab = InputBinding.key(LogicalKeyboardKey.tab);

  // Letters
  
  /// The 'A' key.
  static const InputBinding keyA = InputBinding.key(LogicalKeyboardKey.keyA);
  /// The 'B' key.
  static const InputBinding keyB = InputBinding.key(LogicalKeyboardKey.keyB);
  /// The 'C' key.
  static const InputBinding keyC = InputBinding.key(LogicalKeyboardKey.keyC);
  /// The 'D' key.
  static const InputBinding keyD = InputBinding.key(LogicalKeyboardKey.keyD);
  /// The 'E' key.
  static const InputBinding keyE = InputBinding.key(LogicalKeyboardKey.keyE);
  /// The 'F' key.
  static const InputBinding keyF = InputBinding.key(LogicalKeyboardKey.keyF);
  /// The 'G' key.
  static const InputBinding keyG = InputBinding.key(LogicalKeyboardKey.keyG);
  /// The 'H' key.
  static const InputBinding keyH = InputBinding.key(LogicalKeyboardKey.keyH);
  /// The 'I' key.
  static const InputBinding keyI = InputBinding.key(LogicalKeyboardKey.keyI);
  /// The 'J' key.
  static const InputBinding keyJ = InputBinding.key(LogicalKeyboardKey.keyJ);
  /// The 'K' key.
  static const InputBinding keyK = InputBinding.key(LogicalKeyboardKey.keyK);
  /// The 'L' key.
  static const InputBinding keyL = InputBinding.key(LogicalKeyboardKey.keyL);
  /// The 'M' key.
  static const InputBinding keyM = InputBinding.key(LogicalKeyboardKey.keyM);
  /// The 'N' key.
  static const InputBinding keyN = InputBinding.key(LogicalKeyboardKey.keyN);
  /// The 'O' key.
  static const InputBinding keyO = InputBinding.key(LogicalKeyboardKey.keyO);
  /// The 'P' key.
  static const InputBinding keyP = InputBinding.key(LogicalKeyboardKey.keyP);
  /// The 'Q' key.
  static const InputBinding keyQ = InputBinding.key(LogicalKeyboardKey.keyQ);
  /// The 'R' key.
  static const InputBinding keyR = InputBinding.key(LogicalKeyboardKey.keyR);
  /// The 'S' key.
  static const InputBinding keyS = InputBinding.key(LogicalKeyboardKey.keyS);
  /// The 'T' key.
  static const InputBinding keyT = InputBinding.key(LogicalKeyboardKey.keyT);
  /// The 'U' key.
  static const InputBinding keyU = InputBinding.key(LogicalKeyboardKey.keyU);
  /// The 'V' key.
  static const InputBinding keyV = InputBinding.key(LogicalKeyboardKey.keyV);
  /// The 'W' key.
  static const InputBinding keyW = InputBinding.key(LogicalKeyboardKey.keyW);
  /// The 'X' key.
  static const InputBinding keyX = InputBinding.key(LogicalKeyboardKey.keyX);
  /// The 'Y' key.
  static const InputBinding keyY = InputBinding.key(LogicalKeyboardKey.keyY);
  /// The 'Z' key.
  static const InputBinding keyZ = InputBinding.key(LogicalKeyboardKey.keyZ);

  // Digits
  
  /// The '0' digit key.
  static const InputBinding digit0 = InputBinding.key(LogicalKeyboardKey.digit0);
  /// The '1' digit key.
  static const InputBinding digit1 = InputBinding.key(LogicalKeyboardKey.digit1);
  /// The '2' digit key.
  static const InputBinding digit2 = InputBinding.key(LogicalKeyboardKey.digit2);
  /// The '3' digit key.
  static const InputBinding digit3 = InputBinding.key(LogicalKeyboardKey.digit3);
  /// The '4' digit key.
  static const InputBinding digit4 = InputBinding.key(LogicalKeyboardKey.digit4);
  /// The '5' digit key.
  static const InputBinding digit5 = InputBinding.key(LogicalKeyboardKey.digit5);
  /// The '6' digit key.
  static const InputBinding digit6 = InputBinding.key(LogicalKeyboardKey.digit6);
  /// The '7' digit key.
  static const InputBinding digit7 = InputBinding.key(LogicalKeyboardKey.digit7);
  /// The '8' digit key.
  static const InputBinding digit8 = InputBinding.key(LogicalKeyboardKey.digit8);
  /// The '9' digit key.
  static const InputBinding digit9 = InputBinding.key(LogicalKeyboardKey.digit9);

  // Arrows
  
  /// The Up arrow key.
  static const InputBinding upArrow = InputBinding.key(LogicalKeyboardKey.arrowUp);
  /// The Down arrow key.
  static const InputBinding downArrow = InputBinding.key(LogicalKeyboardKey.arrowDown);
  /// The Left arrow key.
  static const InputBinding leftArrow = InputBinding.key(LogicalKeyboardKey.arrowLeft);
  /// The Right arrow key.
  static const InputBinding rightArrow = InputBinding.key(LogicalKeyboardKey.arrowRight);

  // Modifiers
  
  /// The Left Shift key.
  static const InputBinding shift = InputBinding.key(LogicalKeyboardKey.shiftLeft);
  /// The Right Shift key.
  static const InputBinding shiftRight = InputBinding.key(LogicalKeyboardKey.shiftRight);
  /// The Left Control key.
  static const InputBinding ctrl = InputBinding.key(LogicalKeyboardKey.controlLeft);
  /// The Right Control key.
  static const InputBinding ctrlRight = InputBinding.key(LogicalKeyboardKey.controlRight);
  /// The Left Alt/Option key.
  static const InputBinding alt = InputBinding.key(LogicalKeyboardKey.altLeft);
  /// The Right Alt/Option key.
  static const InputBinding altRight = InputBinding.key(LogicalKeyboardKey.altRight);
  /// The Left Meta/Command key.
  static const InputBinding meta = InputBinding.key(LogicalKeyboardKey.metaLeft);
  /// The Right Meta/Command key.
  static const InputBinding metaRight = InputBinding.key(LogicalKeyboardKey.metaRight);

  // Function Keys
  
  /// The F1 function key.
  static const InputBinding f1 = InputBinding.key(LogicalKeyboardKey.f1);
  /// The F2 function key.
  static const InputBinding f2 = InputBinding.key(LogicalKeyboardKey.f2);
  /// The F3 function key.
  static const InputBinding f3 = InputBinding.key(LogicalKeyboardKey.f3);
  /// The F4 function key.
  static const InputBinding f4 = InputBinding.key(LogicalKeyboardKey.f4);
  /// The F5 function key.
  static const InputBinding f5 = InputBinding.key(LogicalKeyboardKey.f5);
  /// The F6 function key.
  static const InputBinding f6 = InputBinding.key(LogicalKeyboardKey.f6);
  /// The F7 function key.
  static const InputBinding f7 = InputBinding.key(LogicalKeyboardKey.f7);
  /// The F8 function key.
  static const InputBinding f8 = InputBinding.key(LogicalKeyboardKey.f8);
  /// The F9 function key.
  static const InputBinding f9 = InputBinding.key(LogicalKeyboardKey.f9);
  /// The F10 function key.
  static const InputBinding f10 = InputBinding.key(LogicalKeyboardKey.f10);
  /// The F11 function key.
  static const InputBinding f11 = InputBinding.key(LogicalKeyboardKey.f11);
  /// The F12 function key.
  static const InputBinding f12 = InputBinding.key(LogicalKeyboardKey.f12);

  // Numpad
  
  /// The Numpad 0 key.
  static const InputBinding numpad0 = InputBinding.key(LogicalKeyboardKey.numpad0);
  /// The Numpad 1 key.
  static const InputBinding numpad1 = InputBinding.key(LogicalKeyboardKey.numpad1);
  /// The Numpad 2 key.
  static const InputBinding numpad2 = InputBinding.key(LogicalKeyboardKey.numpad2);
  /// The Numpad 3 key.
  static const InputBinding numpad3 = InputBinding.key(LogicalKeyboardKey.numpad3);
  /// The Numpad 4 key.
  static const InputBinding numpad4 = InputBinding.key(LogicalKeyboardKey.numpad4);
  /// The Numpad 5 key.
  static const InputBinding numpad5 = InputBinding.key(LogicalKeyboardKey.numpad5);
  /// The Numpad 6 key.
  static const InputBinding numpad6 = InputBinding.key(LogicalKeyboardKey.numpad6);
  /// The Numpad 7 key.
  static const InputBinding numpad7 = InputBinding.key(LogicalKeyboardKey.numpad7);
  /// The Numpad 8 key.
  static const InputBinding numpad8 = InputBinding.key(LogicalKeyboardKey.numpad8);
  /// The Numpad 9 key.
  static const InputBinding numpad9 = InputBinding.key(LogicalKeyboardKey.numpad9);
  /// The Numpad Decimal key.
  static const InputBinding numpadDecimal = InputBinding.key(LogicalKeyboardKey.numpadDecimal);
  /// The Numpad Divide key.
  static const InputBinding numpadDivide = InputBinding.key(LogicalKeyboardKey.numpadDivide);
  /// The Numpad Multiply key.
  static const InputBinding numpadMultiply = InputBinding.key(LogicalKeyboardKey.numpadMultiply);
  /// The Numpad Subtract key.
  static const InputBinding numpadSubtract = InputBinding.key(LogicalKeyboardKey.numpadSubtract);
  /// The Numpad Add key.
  static const InputBinding numpadAdd = InputBinding.key(LogicalKeyboardKey.numpadAdd);
  /// The Numpad Enter key.
  static const InputBinding numpadEnter = InputBinding.key(LogicalKeyboardKey.numpadEnter);
  /// The Numpad Equal key.
  static const InputBinding numpadEqual = InputBinding.key(LogicalKeyboardKey.numpadEqual);

  // Special Keys
  
  /// The Caps Lock key.
  static const InputBinding capsLock = InputBinding.key(LogicalKeyboardKey.capsLock);
  /// The Scroll Lock key.
  static const InputBinding scrollLock = InputBinding.key(LogicalKeyboardKey.scrollLock);
  /// The Num Lock key.
  static const InputBinding numLock = InputBinding.key(LogicalKeyboardKey.numLock);
  /// The Print Screen key.
  static const InputBinding printScreen = InputBinding.key(LogicalKeyboardKey.printScreen);
  /// The Pause/Break key.
  static const InputBinding pause = InputBinding.key(LogicalKeyboardKey.pause);
  /// The Insert key.
  static const InputBinding insert = InputBinding.key(LogicalKeyboardKey.insert);
  /// The Home key.
  static const InputBinding home = InputBinding.key(LogicalKeyboardKey.home);
  /// The End key.
  static const InputBinding end = InputBinding.key(LogicalKeyboardKey.end);
  /// The Page Up key.
  static const InputBinding pageUp = InputBinding.key(LogicalKeyboardKey.pageUp);
  /// The Page Down key.
  static const InputBinding pageDown = InputBinding.key(LogicalKeyboardKey.pageDown);
  /// The Delete key.
  static const InputBinding delete = InputBinding.key(LogicalKeyboardKey.delete);

  // Symbols
  
  /// The Grave/Backtick key (`).
  static const InputBinding grave = InputBinding.key(LogicalKeyboardKey.backquote);
  /// The Minus key (-).
  static const InputBinding minus = InputBinding.key(LogicalKeyboardKey.minus);
  /// The Equal key (=).
  static const InputBinding equal = InputBinding.key(LogicalKeyboardKey.equal);
  /// The Left Bracket key ([).
  static const InputBinding bracketLeft = InputBinding.key(LogicalKeyboardKey.bracketLeft);
  /// The Right Bracket key (]).
  static const InputBinding bracketRight = InputBinding.key(LogicalKeyboardKey.bracketRight);
  /// The Backslash key (\).
  static const InputBinding backslash = InputBinding.key(LogicalKeyboardKey.backslash);
  /// The Semicolon key (;).
  static const InputBinding semicolon = InputBinding.key(LogicalKeyboardKey.semicolon);
  /// The Quote key (').
  static const InputBinding quote = InputBinding.key(LogicalKeyboardKey.quote);
  /// The Comma key (,).
  static const InputBinding comma = InputBinding.key(LogicalKeyboardKey.comma);
  /// The Period key (.).
  static const InputBinding period = InputBinding.key(LogicalKeyboardKey.period);
  /// The Slash key (/).
  static const InputBinding slash = InputBinding.key(LogicalKeyboardKey.slash);
}
