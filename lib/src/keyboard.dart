part of 'input.dart';

class Keyboard {
  Keyboard._();
  static const InputBinding space = InputBinding.key(LogicalKeyboardKey.space);
  static const InputBinding enter = InputBinding.key(LogicalKeyboardKey.enter);
  static const InputBinding escape = InputBinding.key(
    LogicalKeyboardKey.escape,
  );
  static const InputBinding backspace = InputBinding.key(
    LogicalKeyboardKey.backspace,
  );
  static const InputBinding tab = InputBinding.key(LogicalKeyboardKey.tab);

  // Letters
  static const InputBinding keyA = InputBinding.key(LogicalKeyboardKey.keyA);
  static const InputBinding keyB = InputBinding.key(LogicalKeyboardKey.keyB);
  static const InputBinding keyC = InputBinding.key(LogicalKeyboardKey.keyC);
  static const InputBinding keyD = InputBinding.key(LogicalKeyboardKey.keyD);
  static const InputBinding keyE = InputBinding.key(LogicalKeyboardKey.keyE);
  static const InputBinding keyF = InputBinding.key(LogicalKeyboardKey.keyF);
  static const InputBinding keyG = InputBinding.key(LogicalKeyboardKey.keyG);
  static const InputBinding keyH = InputBinding.key(LogicalKeyboardKey.keyH);
  static const InputBinding keyI = InputBinding.key(LogicalKeyboardKey.keyI);
  static const InputBinding keyJ = InputBinding.key(LogicalKeyboardKey.keyJ);
  static const InputBinding keyK = InputBinding.key(LogicalKeyboardKey.keyK);
  static const InputBinding keyL = InputBinding.key(LogicalKeyboardKey.keyL);
  static const InputBinding keyM = InputBinding.key(LogicalKeyboardKey.keyM);
  static const InputBinding keyN = InputBinding.key(LogicalKeyboardKey.keyN);
  static const InputBinding keyO = InputBinding.key(LogicalKeyboardKey.keyO);
  static const InputBinding keyP = InputBinding.key(LogicalKeyboardKey.keyP);
  static const InputBinding keyQ = InputBinding.key(LogicalKeyboardKey.keyQ);
  static const InputBinding keyR = InputBinding.key(LogicalKeyboardKey.keyR);
  static const InputBinding keyS = InputBinding.key(LogicalKeyboardKey.keyS);
  static const InputBinding keyT = InputBinding.key(LogicalKeyboardKey.keyT);
  static const InputBinding keyU = InputBinding.key(LogicalKeyboardKey.keyU);
  static const InputBinding keyV = InputBinding.key(LogicalKeyboardKey.keyV);
  static const InputBinding keyW = InputBinding.key(LogicalKeyboardKey.keyW);
  static const InputBinding keyX = InputBinding.key(LogicalKeyboardKey.keyX);
  static const InputBinding keyY = InputBinding.key(LogicalKeyboardKey.keyY);
  static const InputBinding keyZ = InputBinding.key(LogicalKeyboardKey.keyZ);

  // Digits
  static const InputBinding digit0 = InputBinding.key(
    LogicalKeyboardKey.digit0,
  );
  static const InputBinding digit1 = InputBinding.key(
    LogicalKeyboardKey.digit1,
  );
  static const InputBinding digit2 = InputBinding.key(
    LogicalKeyboardKey.digit2,
  );
  static const InputBinding digit3 = InputBinding.key(
    LogicalKeyboardKey.digit3,
  );
  static const InputBinding digit4 = InputBinding.key(
    LogicalKeyboardKey.digit4,
  );
  static const InputBinding digit5 = InputBinding.key(
    LogicalKeyboardKey.digit5,
  );
  static const InputBinding digit6 = InputBinding.key(
    LogicalKeyboardKey.digit6,
  );
  static const InputBinding digit7 = InputBinding.key(
    LogicalKeyboardKey.digit7,
  );
  static const InputBinding digit8 = InputBinding.key(
    LogicalKeyboardKey.digit8,
  );
  static const InputBinding digit9 = InputBinding.key(
    LogicalKeyboardKey.digit9,
  );

  // Arrows
  static const InputBinding upArrow = InputBinding.key(
    LogicalKeyboardKey.arrowUp,
  );
  static const InputBinding downArrow = InputBinding.key(
    LogicalKeyboardKey.arrowDown,
  );
  static const InputBinding leftArrow = InputBinding.key(
    LogicalKeyboardKey.arrowLeft,
  );
  static const InputBinding rightArrow = InputBinding.key(
    LogicalKeyboardKey.arrowRight,
  );

  // Modifiers
  static const InputBinding shift = InputBinding.key(
    LogicalKeyboardKey.shiftLeft,
  );
  static const InputBinding shiftRight = InputBinding.key(
    LogicalKeyboardKey.shiftRight,
  );
  static const InputBinding ctrl = InputBinding.key(
    LogicalKeyboardKey.controlLeft,
  );
  static const InputBinding ctrlRight = InputBinding.key(
    LogicalKeyboardKey.controlRight,
  );
  static const InputBinding alt = InputBinding.key(LogicalKeyboardKey.altLeft);
  static const InputBinding altRight = InputBinding.key(
    LogicalKeyboardKey.altRight,
  );
  static const InputBinding meta = InputBinding.key(
    LogicalKeyboardKey.metaLeft,
  );
  static const InputBinding metaRight = InputBinding.key(
    LogicalKeyboardKey.metaRight,
  );

  // Function Keys
  static const InputBinding f1 = InputBinding.key(LogicalKeyboardKey.f1);
  static const InputBinding f2 = InputBinding.key(LogicalKeyboardKey.f2);
  static const InputBinding f3 = InputBinding.key(LogicalKeyboardKey.f3);
  static const InputBinding f4 = InputBinding.key(LogicalKeyboardKey.f4);
  static const InputBinding f5 = InputBinding.key(LogicalKeyboardKey.f5);
  static const InputBinding f6 = InputBinding.key(LogicalKeyboardKey.f6);
  static const InputBinding f7 = InputBinding.key(LogicalKeyboardKey.f7);
  static const InputBinding f8 = InputBinding.key(LogicalKeyboardKey.f8);
  static const InputBinding f9 = InputBinding.key(LogicalKeyboardKey.f9);
  static const InputBinding f10 = InputBinding.key(LogicalKeyboardKey.f10);
  static const InputBinding f11 = InputBinding.key(LogicalKeyboardKey.f11);
  static const InputBinding f12 = InputBinding.key(LogicalKeyboardKey.f12);

  // Numpad
  static const InputBinding numpad0 = InputBinding.key(
    LogicalKeyboardKey.numpad0,
  );
  static const InputBinding numpad1 = InputBinding.key(
    LogicalKeyboardKey.numpad1,
  );
  static const InputBinding numpad2 = InputBinding.key(
    LogicalKeyboardKey.numpad2,
  );
  static const InputBinding numpad3 = InputBinding.key(
    LogicalKeyboardKey.numpad3,
  );
  static const InputBinding numpad4 = InputBinding.key(
    LogicalKeyboardKey.numpad4,
  );
  static const InputBinding numpad5 = InputBinding.key(
    LogicalKeyboardKey.numpad5,
  );
  static const InputBinding numpad6 = InputBinding.key(
    LogicalKeyboardKey.numpad6,
  );
  static const InputBinding numpad7 = InputBinding.key(
    LogicalKeyboardKey.numpad7,
  );
  static const InputBinding numpad8 = InputBinding.key(
    LogicalKeyboardKey.numpad8,
  );
  static const InputBinding numpad9 = InputBinding.key(
    LogicalKeyboardKey.numpad9,
  );
  static const InputBinding numpadDecimal = InputBinding.key(
    LogicalKeyboardKey.numpadDecimal,
  );
  static const InputBinding numpadDivide = InputBinding.key(
    LogicalKeyboardKey.numpadDivide,
  );
  static const InputBinding numpadMultiply = InputBinding.key(
    LogicalKeyboardKey.numpadMultiply,
  );
  static const InputBinding numpadSubtract = InputBinding.key(
    LogicalKeyboardKey.numpadSubtract,
  );
  static const InputBinding numpadAdd = InputBinding.key(
    LogicalKeyboardKey.numpadAdd,
  );
  static const InputBinding numpadEnter = InputBinding.key(
    LogicalKeyboardKey.numpadEnter,
  );
  static const InputBinding numpadEqual = InputBinding.key(
    LogicalKeyboardKey.numpadEqual,
  );

  // Special Keys
  static const InputBinding capsLock = InputBinding.key(
    LogicalKeyboardKey.capsLock,
  );
  static const InputBinding scrollLock = InputBinding.key(
    LogicalKeyboardKey.scrollLock,
  );
  static const InputBinding numLock = InputBinding.key(
    LogicalKeyboardKey.numLock,
  );
  static const InputBinding printScreen = InputBinding.key(
    LogicalKeyboardKey.printScreen,
  );
  static const InputBinding pause = InputBinding.key(LogicalKeyboardKey.pause);
  static const InputBinding insert = InputBinding.key(
    LogicalKeyboardKey.insert,
  );
  static const InputBinding home = InputBinding.key(LogicalKeyboardKey.home);
  static const InputBinding end = InputBinding.key(LogicalKeyboardKey.end);
  static const InputBinding pageUp = InputBinding.key(
    LogicalKeyboardKey.pageUp,
  );
  static const InputBinding pageDown = InputBinding.key(
    LogicalKeyboardKey.pageDown,
  );
  static const InputBinding delete = InputBinding.key(
    LogicalKeyboardKey.delete,
  );

  // Symbols
  static const InputBinding grave = InputBinding.key(
    LogicalKeyboardKey.backquote,
  );
  static const InputBinding minus = InputBinding.key(LogicalKeyboardKey.minus);
  static const InputBinding equal = InputBinding.key(LogicalKeyboardKey.equal);
  static const InputBinding bracketLeft = InputBinding.key(
    LogicalKeyboardKey.bracketLeft,
  );
  static const InputBinding bracketRight = InputBinding.key(
    LogicalKeyboardKey.bracketRight,
  );
  static const InputBinding backslash = InputBinding.key(
    LogicalKeyboardKey.backslash,
  );
  static const InputBinding semicolon = InputBinding.key(
    LogicalKeyboardKey.semicolon,
  );
  static const InputBinding quote = InputBinding.key(LogicalKeyboardKey.quote);
  static const InputBinding comma = InputBinding.key(LogicalKeyboardKey.comma);
  static const InputBinding period = InputBinding.key(
    LogicalKeyboardKey.period,
  );
  static const InputBinding slash = InputBinding.key(LogicalKeyboardKey.slash);
}
