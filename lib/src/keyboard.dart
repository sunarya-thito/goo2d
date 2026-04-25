part of 'input.dart';

extension KeyboardStateKeys on KeyboardState {
  ButtonControl get space => this[LogicalKeyboardKey.space];
  ButtonControl get enter => this[LogicalKeyboardKey.enter];
  ButtonControl get escape => this[LogicalKeyboardKey.escape];
  ButtonControl get backspace => this[LogicalKeyboardKey.backspace];
  ButtonControl get tab => this[LogicalKeyboardKey.tab];

  // Letters
  // Letters
  ButtonControl get keyA => this[LogicalKeyboardKey.keyA];
  ButtonControl get keyB => this[LogicalKeyboardKey.keyB];
  ButtonControl get keyC => this[LogicalKeyboardKey.keyC];
  ButtonControl get keyD => this[LogicalKeyboardKey.keyD];
  ButtonControl get keyE => this[LogicalKeyboardKey.keyE];
  ButtonControl get keyF => this[LogicalKeyboardKey.keyF];
  ButtonControl get keyG => this[LogicalKeyboardKey.keyG];
  ButtonControl get keyH => this[LogicalKeyboardKey.keyH];
  ButtonControl get keyI => this[LogicalKeyboardKey.keyI];
  ButtonControl get keyJ => this[LogicalKeyboardKey.keyJ];
  ButtonControl get keyK => this[LogicalKeyboardKey.keyK];
  ButtonControl get keyL => this[LogicalKeyboardKey.keyL];
  ButtonControl get keyM => this[LogicalKeyboardKey.keyM];
  ButtonControl get keyN => this[LogicalKeyboardKey.keyN];
  ButtonControl get keyO => this[LogicalKeyboardKey.keyO];
  ButtonControl get keyP => this[LogicalKeyboardKey.keyP];
  ButtonControl get keyQ => this[LogicalKeyboardKey.keyQ];
  ButtonControl get keyR => this[LogicalKeyboardKey.keyR];
  ButtonControl get keyS => this[LogicalKeyboardKey.keyS];
  ButtonControl get keyT => this[LogicalKeyboardKey.keyT];
  ButtonControl get keyU => this[LogicalKeyboardKey.keyU];
  ButtonControl get keyV => this[LogicalKeyboardKey.keyV];
  ButtonControl get keyW => this[LogicalKeyboardKey.keyW];
  ButtonControl get keyX => this[LogicalKeyboardKey.keyX];
  ButtonControl get keyY => this[LogicalKeyboardKey.keyY];
  ButtonControl get keyZ => this[LogicalKeyboardKey.keyZ];

  // Digits
  ButtonControl get digit0 => this[LogicalKeyboardKey.digit0];
  ButtonControl get digit1 => this[LogicalKeyboardKey.digit1];
  ButtonControl get digit2 => this[LogicalKeyboardKey.digit2];
  ButtonControl get digit3 => this[LogicalKeyboardKey.digit3];
  ButtonControl get digit4 => this[LogicalKeyboardKey.digit4];
  ButtonControl get digit5 => this[LogicalKeyboardKey.digit5];
  ButtonControl get digit6 => this[LogicalKeyboardKey.digit6];
  ButtonControl get digit7 => this[LogicalKeyboardKey.digit7];
  ButtonControl get digit8 => this[LogicalKeyboardKey.digit8];
  ButtonControl get digit9 => this[LogicalKeyboardKey.digit9];

  // Arrows
  ButtonControl get upArrow => this[LogicalKeyboardKey.arrowUp];
  ButtonControl get downArrow => this[LogicalKeyboardKey.arrowDown];
  ButtonControl get leftArrow => this[LogicalKeyboardKey.arrowLeft];
  ButtonControl get rightArrow => this[LogicalKeyboardKey.arrowRight];

  // Modifiers
  ButtonControl get shift => this[LogicalKeyboardKey.shiftLeft];
  ButtonControl get shiftRight => this[LogicalKeyboardKey.shiftRight];
  ButtonControl get ctrl => this[LogicalKeyboardKey.controlLeft];
  ButtonControl get ctrlRight => this[LogicalKeyboardKey.controlRight];
  ButtonControl get alt => this[LogicalKeyboardKey.altLeft];
  ButtonControl get altRight => this[LogicalKeyboardKey.altRight];
  ButtonControl get meta => this[LogicalKeyboardKey.metaLeft];
  ButtonControl get metaRight => this[LogicalKeyboardKey.metaRight];

  // Function Keys
  ButtonControl get f1 => this[LogicalKeyboardKey.f1];
  ButtonControl get f2 => this[LogicalKeyboardKey.f2];
  ButtonControl get f3 => this[LogicalKeyboardKey.f3];
  ButtonControl get f4 => this[LogicalKeyboardKey.f4];
  ButtonControl get f5 => this[LogicalKeyboardKey.f5];
  ButtonControl get f6 => this[LogicalKeyboardKey.f6];
  ButtonControl get f7 => this[LogicalKeyboardKey.f7];
  ButtonControl get f8 => this[LogicalKeyboardKey.f8];
  ButtonControl get f9 => this[LogicalKeyboardKey.f9];
  ButtonControl get f10 => this[LogicalKeyboardKey.f10];
  ButtonControl get f11 => this[LogicalKeyboardKey.f11];
  ButtonControl get f12 => this[LogicalKeyboardKey.f12];

  // Numpad
  ButtonControl get numpad0 => this[LogicalKeyboardKey.numpad0];
  ButtonControl get numpad1 => this[LogicalKeyboardKey.numpad1];
  ButtonControl get numpad2 => this[LogicalKeyboardKey.numpad2];
  ButtonControl get numpad3 => this[LogicalKeyboardKey.numpad3];
  ButtonControl get numpad4 => this[LogicalKeyboardKey.numpad4];
  ButtonControl get numpad5 => this[LogicalKeyboardKey.numpad5];
  ButtonControl get numpad6 => this[LogicalKeyboardKey.numpad6];
  ButtonControl get numpad7 => this[LogicalKeyboardKey.numpad7];
  ButtonControl get numpad8 => this[LogicalKeyboardKey.numpad8];
  ButtonControl get numpad9 => this[LogicalKeyboardKey.numpad9];
  ButtonControl get numpadDecimal => this[LogicalKeyboardKey.numpadDecimal];
  ButtonControl get numpadDivide => this[LogicalKeyboardKey.numpadDivide];
  ButtonControl get numpadMultiply => this[LogicalKeyboardKey.numpadMultiply];
  ButtonControl get numpadSubtract => this[LogicalKeyboardKey.numpadSubtract];
  ButtonControl get numpadAdd => this[LogicalKeyboardKey.numpadAdd];
  ButtonControl get numpadEnter => this[LogicalKeyboardKey.numpadEnter];
  ButtonControl get numpadEqual => this[LogicalKeyboardKey.numpadEqual];

  // Special Keys
  ButtonControl get capsLock => this[LogicalKeyboardKey.capsLock];
  ButtonControl get scrollLock => this[LogicalKeyboardKey.scrollLock];
  ButtonControl get numLock => this[LogicalKeyboardKey.numLock];
  ButtonControl get printScreen => this[LogicalKeyboardKey.printScreen];
  ButtonControl get pause => this[LogicalKeyboardKey.pause];
  ButtonControl get insert => this[LogicalKeyboardKey.insert];
  ButtonControl get home => this[LogicalKeyboardKey.home];
  ButtonControl get end => this[LogicalKeyboardKey.end];
  ButtonControl get pageUp => this[LogicalKeyboardKey.pageUp];
  ButtonControl get pageDown => this[LogicalKeyboardKey.pageDown];
  ButtonControl get delete => this[LogicalKeyboardKey.delete];
}
