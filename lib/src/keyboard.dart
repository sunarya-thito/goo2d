part of 'input.dart';

/// Provides convenience getters for common physical keys.
/// 
/// This extension simplifies access to frequently used keys like 
/// arrows, WASD, and modifiers by providing named shortcuts 
/// instead of requiring [LogicalKeyboardKey] constants.
extension KeyboardStateKeys on KeyboardState {
  /// The Space key.
  /// 
  /// Maps to [LogicalKeyboardKey.space].
  ButtonControl get space => this[LogicalKeyboardKey.space];
  /// The Enter key.
  /// 
  /// Maps to [LogicalKeyboardKey.enter].
  ButtonControl get enter => this[LogicalKeyboardKey.enter];
  /// The Escape key.
  /// 
  /// Maps to [LogicalKeyboardKey.escape].
  ButtonControl get escape => this[LogicalKeyboardKey.escape];
  /// The Backspace key.
  /// 
  /// Maps to [LogicalKeyboardKey.backspace].
  ButtonControl get backspace => this[LogicalKeyboardKey.backspace];
  /// The Tab key.
  /// 
  /// Maps to [LogicalKeyboardKey.tab].
  ButtonControl get tab => this[LogicalKeyboardKey.tab];

  // Letters
  
  /// The 'A' key.
  /// 
  /// Maps to [LogicalKeyboardKey.keyA].
  ButtonControl get keyA => this[LogicalKeyboardKey.keyA];
  /// The 'B' key.
  /// 
  /// Maps to [LogicalKeyboardKey.keyB].
  ButtonControl get keyB => this[LogicalKeyboardKey.keyB];
  /// The 'C' key.
  /// 
  /// Maps to [LogicalKeyboardKey.keyC].
  ButtonControl get keyC => this[LogicalKeyboardKey.keyC];
  /// The 'D' key.
  /// 
  /// Maps to [LogicalKeyboardKey.keyD].
  ButtonControl get keyD => this[LogicalKeyboardKey.keyD];
  /// The 'E' key.
  /// 
  /// Maps to [LogicalKeyboardKey.keyE].
  ButtonControl get keyE => this[LogicalKeyboardKey.keyE];
  /// The 'F' key.
  /// 
  /// Maps to [LogicalKeyboardKey.keyF].
  ButtonControl get keyF => this[LogicalKeyboardKey.keyF];
  /// The 'G' key.
  /// 
  /// Maps to [LogicalKeyboardKey.keyG].
  ButtonControl get keyG => this[LogicalKeyboardKey.keyG];
  /// The 'H' key.
  /// 
  /// Maps to [LogicalKeyboardKey.keyH].
  ButtonControl get keyH => this[LogicalKeyboardKey.keyH];
  /// The 'I' key.
  /// 
  /// Maps to [LogicalKeyboardKey.keyI].
  ButtonControl get keyI => this[LogicalKeyboardKey.keyI];
  /// The 'J' key.
  /// 
  /// Maps to [LogicalKeyboardKey.keyJ].
  ButtonControl get keyJ => this[LogicalKeyboardKey.keyJ];
  /// The 'K' key.
  /// 
  /// Maps to [LogicalKeyboardKey.keyK].
  ButtonControl get keyK => this[LogicalKeyboardKey.keyK];
  /// The 'L' key.
  /// 
  /// Maps to [LogicalKeyboardKey.keyL].
  ButtonControl get keyL => this[LogicalKeyboardKey.keyL];
  /// The 'M' key.
  /// 
  /// Maps to [LogicalKeyboardKey.keyM].
  ButtonControl get keyM => this[LogicalKeyboardKey.keyM];
  /// The 'N' key.
  /// 
  /// Maps to [LogicalKeyboardKey.keyN].
  ButtonControl get keyN => this[LogicalKeyboardKey.keyN];
  /// The 'O' key.
  /// 
  /// Maps to [LogicalKeyboardKey.keyO].
  ButtonControl get keyO => this[LogicalKeyboardKey.keyO];
  /// The 'P' key.
  /// 
  /// Maps to [LogicalKeyboardKey.keyP].
  ButtonControl get keyP => this[LogicalKeyboardKey.keyP];
  /// The 'Q' key.
  /// 
  /// Maps to [LogicalKeyboardKey.keyQ].
  ButtonControl get keyQ => this[LogicalKeyboardKey.keyQ];
  /// The 'R' key.
  /// 
  /// Maps to [LogicalKeyboardKey.keyR].
  ButtonControl get keyR => this[LogicalKeyboardKey.keyR];
  /// The 'S' key.
  /// 
  /// Maps to [LogicalKeyboardKey.keyS].
  ButtonControl get keyS => this[LogicalKeyboardKey.keyS];
  /// The 'T' key.
  /// 
  /// Maps to [LogicalKeyboardKey.keyT].
  ButtonControl get keyT => this[LogicalKeyboardKey.keyT];
  /// The 'U' key.
  /// 
  /// Maps to [LogicalKeyboardKey.keyU].
  ButtonControl get keyU => this[LogicalKeyboardKey.keyU];
  /// The 'V' key.
  /// 
  /// Maps to [LogicalKeyboardKey.keyV].
  ButtonControl get keyV => this[LogicalKeyboardKey.keyV];
  /// The 'W' key.
  /// 
  /// Maps to [LogicalKeyboardKey.keyW].
  ButtonControl get keyW => this[LogicalKeyboardKey.keyW];
  /// The 'X' key.
  /// 
  /// Maps to [LogicalKeyboardKey.keyX].
  ButtonControl get keyX => this[LogicalKeyboardKey.keyX];
  /// The 'Y' key.
  /// 
  /// Maps to [LogicalKeyboardKey.keyY].
  ButtonControl get keyY => this[LogicalKeyboardKey.keyY];
  /// The 'Z' key.
  /// 
  /// Maps to [LogicalKeyboardKey.keyZ].
  ButtonControl get keyZ => this[LogicalKeyboardKey.keyZ];

  // Digits
  
  /// The '0' digit key.
  /// 
  /// Maps to [LogicalKeyboardKey.digit0].
  ButtonControl get digit0 => this[LogicalKeyboardKey.digit0];
  /// The '1' digit key.
  /// 
  /// Maps to [LogicalKeyboardKey.digit1].
  ButtonControl get digit1 => this[LogicalKeyboardKey.digit1];
  /// The '2' digit key.
  /// 
  /// Maps to [LogicalKeyboardKey.digit2].
  ButtonControl get digit2 => this[LogicalKeyboardKey.digit2];
  /// The '3' digit key.
  /// 
  /// Maps to [LogicalKeyboardKey.digit3].
  ButtonControl get digit3 => this[LogicalKeyboardKey.digit3];
  /// The '4' digit key.
  /// 
  /// Maps to [LogicalKeyboardKey.digit4].
  ButtonControl get digit4 => this[LogicalKeyboardKey.digit4];
  /// The '5' digit key.
  /// 
  /// Maps to [LogicalKeyboardKey.digit5].
  ButtonControl get digit5 => this[LogicalKeyboardKey.digit5];
  /// The '6' digit key.
  /// 
  /// Maps to [LogicalKeyboardKey.digit6].
  ButtonControl get digit6 => this[LogicalKeyboardKey.digit6];
  /// The '7' digit key.
  /// 
  /// Maps to [LogicalKeyboardKey.digit7].
  ButtonControl get digit7 => this[LogicalKeyboardKey.digit7];
  /// The '8' digit key.
  /// 
  /// Maps to [LogicalKeyboardKey.digit8].
  ButtonControl get digit8 => this[LogicalKeyboardKey.digit8];
  /// The '9' digit key.
  /// 
  /// Maps to [LogicalKeyboardKey.digit9].
  ButtonControl get digit9 => this[LogicalKeyboardKey.digit9];

  // Arrows
  
  /// The Up arrow key.
  /// 
  /// Maps to [LogicalKeyboardKey.arrowUp].
  ButtonControl get upArrow => this[LogicalKeyboardKey.arrowUp];
  /// The Down arrow key.
  /// 
  /// Maps to [LogicalKeyboardKey.arrowDown].
  ButtonControl get downArrow => this[LogicalKeyboardKey.arrowDown];
  /// The Left arrow key.
  /// 
  /// Maps to [LogicalKeyboardKey.arrowLeft].
  ButtonControl get leftArrow => this[LogicalKeyboardKey.arrowLeft];
  /// The Right arrow key.
  /// 
  /// Maps to [LogicalKeyboardKey.arrowRight].
  ButtonControl get rightArrow => this[LogicalKeyboardKey.arrowRight];

  // Modifiers
  
  /// The Left Shift key.
  /// 
  /// Maps to [LogicalKeyboardKey.shiftLeft].
  ButtonControl get shift => this[LogicalKeyboardKey.shiftLeft];
  /// The Right Shift key.
  /// 
  /// Maps to [LogicalKeyboardKey.shiftRight].
  ButtonControl get shiftRight => this[LogicalKeyboardKey.shiftRight];
  /// The Left Control key.
  /// 
  /// Maps to [LogicalKeyboardKey.ctrlLeft].
  ButtonControl get ctrl => this[LogicalKeyboardKey.controlLeft];
  /// The Right Control key.
  /// 
  /// Maps to [LogicalKeyboardKey.ctrlRight].
  ButtonControl get ctrlRight => this[LogicalKeyboardKey.controlRight];
  /// The Left Alt/Option key.
  /// 
  /// Maps to [LogicalKeyboardKey.altLeft].
  ButtonControl get alt => this[LogicalKeyboardKey.altLeft];
  /// The Right Alt/Option key.
  /// 
  /// Maps to [LogicalKeyboardKey.altRight].
  ButtonControl get altRight => this[LogicalKeyboardKey.altRight];
  /// The Left Meta/Command key.
  /// 
  /// Maps to [LogicalKeyboardKey.metaLeft].
  ButtonControl get meta => this[LogicalKeyboardKey.metaLeft];
  /// The Right Meta/Command key.
  /// 
  /// Maps to [LogicalKeyboardKey.metaRight].
  ButtonControl get metaRight => this[LogicalKeyboardKey.metaRight];

  // Function Keys
  
  /// The F1 function key.
  /// 
  /// Maps to [LogicalKeyboardKey.f1].
  ButtonControl get f1 => this[LogicalKeyboardKey.f1];
  /// The F2 function key.
  /// 
  /// Maps to [LogicalKeyboardKey.f2].
  ButtonControl get f2 => this[LogicalKeyboardKey.f2];
  /// The F3 function key.
  /// 
  /// Maps to [LogicalKeyboardKey.f3].
  ButtonControl get f3 => this[LogicalKeyboardKey.f3];
  /// The F4 function key.
  /// 
  /// Maps to [LogicalKeyboardKey.f4].
  ButtonControl get f4 => this[LogicalKeyboardKey.f4];
  /// The F5 function key.
  /// 
  /// Maps to [LogicalKeyboardKey.f5].
  ButtonControl get f5 => this[LogicalKeyboardKey.f5];
  /// The F6 function key.
  /// 
  /// Maps to [LogicalKeyboardKey.f6].
  ButtonControl get f6 => this[LogicalKeyboardKey.f6];
  /// The F7 function key.
  /// 
  /// Maps to [LogicalKeyboardKey.f7].
  ButtonControl get f7 => this[LogicalKeyboardKey.f7];
  /// The F8 function key.
  /// 
  /// Maps to [LogicalKeyboardKey.f8].
  ButtonControl get f8 => this[LogicalKeyboardKey.f8];
  /// The F9 function key.
  /// 
  /// Maps to [LogicalKeyboardKey.f9].
  ButtonControl get f9 => this[LogicalKeyboardKey.f9];
  /// The F10 function key.
  /// 
  /// Maps to [LogicalKeyboardKey.f10].
  ButtonControl get f10 => this[LogicalKeyboardKey.f10];
  /// The F11 function key.
  /// 
  /// Maps to [LogicalKeyboardKey.f11].
  ButtonControl get f11 => this[LogicalKeyboardKey.f11];
  /// The F12 function key.
  /// 
  /// Maps to [LogicalKeyboardKey.f12].
  ButtonControl get f12 => this[LogicalKeyboardKey.f12];

  // Numpad
  
  /// The Numpad 0 key.
  /// 
  /// Maps to [LogicalKeyboardKey.numpad0].
  ButtonControl get numpad0 => this[LogicalKeyboardKey.numpad0];
  /// The Numpad 1 key.
  /// 
  /// Maps to [LogicalKeyboardKey.numpad1].
  ButtonControl get numpad1 => this[LogicalKeyboardKey.numpad1];
  /// The Numpad 2 key.
  /// 
  /// Maps to [LogicalKeyboardKey.numpad2].
  ButtonControl get numpad2 => this[LogicalKeyboardKey.numpad2];
  /// The Numpad 3 key.
  /// 
  /// Maps to [LogicalKeyboardKey.numpad3].
  ButtonControl get numpad3 => this[LogicalKeyboardKey.numpad3];
  /// The Numpad 4 key.
  /// 
  /// Maps to [LogicalKeyboardKey.numpad4].
  ButtonControl get numpad4 => this[LogicalKeyboardKey.numpad4];
  /// The Numpad 5 key.
  /// 
  /// Maps to [LogicalKeyboardKey.numpad5].
  ButtonControl get numpad5 => this[LogicalKeyboardKey.numpad5];
  /// The Numpad 6 key.
  /// 
  /// Maps to [LogicalKeyboardKey.numpad6].
  ButtonControl get numpad6 => this[LogicalKeyboardKey.numpad6];
  /// The Numpad 7 key.
  /// 
  /// Maps to [LogicalKeyboardKey.numpad7].
  ButtonControl get numpad7 => this[LogicalKeyboardKey.numpad7];
  /// The Numpad 8 key.
  /// 
  /// Maps to [LogicalKeyboardKey.numpad8].
  ButtonControl get numpad8 => this[LogicalKeyboardKey.numpad8];
  /// The Numpad 9 key.
  /// 
  /// Maps to [LogicalKeyboardKey.numpad9].
  ButtonControl get numpad9 => this[LogicalKeyboardKey.numpad9];
  /// The Numpad Decimal key.
  /// 
  /// Maps to [LogicalKeyboardKey.numpadDecimal].
  ButtonControl get numpadDecimal => this[LogicalKeyboardKey.numpadDecimal];
  /// The Numpad Divide key.
  /// 
  /// Maps to [LogicalKeyboardKey.numpadDivide].
  ButtonControl get numpadDivide => this[LogicalKeyboardKey.numpadDivide];
  /// The Numpad Multiply key.
  /// 
  /// Maps to [LogicalKeyboardKey.numpadMultiply].
  ButtonControl get numpadMultiply => this[LogicalKeyboardKey.numpadMultiply];
  /// The Numpad Subtract key.
  /// 
  /// Maps to [LogicalKeyboardKey.numpadSubtract].
  ButtonControl get numpadSubtract => this[LogicalKeyboardKey.numpadSubtract];
  /// The Numpad Add key.
  /// 
  /// Maps to [LogicalKeyboardKey.numpadAdd].
  ButtonControl get numpadAdd => this[LogicalKeyboardKey.numpadAdd];
  /// The Numpad Enter key.
  /// 
  /// Maps to [LogicalKeyboardKey.numpadEnter].
  ButtonControl get numpadEnter => this[LogicalKeyboardKey.numpadEnter];
  /// The Numpad Equal key.
  /// 
  /// Maps to [LogicalKeyboardKey.numpadEqual].
  ButtonControl get numpadEqual => this[LogicalKeyboardKey.numpadEqual];

  // Special Keys
  
  /// The Caps Lock key.
  /// 
  /// Maps to [LogicalKeyboardKey.capsLock].
  ButtonControl get capsLock => this[LogicalKeyboardKey.capsLock];
  /// The Scroll Lock key.
  /// 
  /// Maps to [LogicalKeyboardKey.scrollLock].
  ButtonControl get scrollLock => this[LogicalKeyboardKey.scrollLock];
  /// The Num Lock key.
  /// 
  /// Maps to [LogicalKeyboardKey.numLock].
  ButtonControl get numLock => this[LogicalKeyboardKey.numLock];
  /// The Print Screen key.
  /// 
  /// Maps to [LogicalKeyboardKey.printScreen].
  ButtonControl get printScreen => this[LogicalKeyboardKey.printScreen];
  /// The Pause/Break key.
  /// 
  /// Maps to [LogicalKeyboardKey.pause].
  ButtonControl get pause => this[LogicalKeyboardKey.pause];
  /// The Insert key.
  /// 
  /// Maps to [LogicalKeyboardKey.insert].
  ButtonControl get insert => this[LogicalKeyboardKey.insert];
  /// The Home key.
  /// 
  /// Maps to [LogicalKeyboardKey.home].
  ButtonControl get home => this[LogicalKeyboardKey.home];
  /// The End key.
  /// 
  /// Maps to [LogicalKeyboardKey.end].
  ButtonControl get end => this[LogicalKeyboardKey.end];
  /// The Page Up key.
  /// 
  /// Maps to [LogicalKeyboardKey.pageUp].
  ButtonControl get pageUp => this[LogicalKeyboardKey.pageUp];
  /// The Page Down key.
  /// 
  /// Maps to [LogicalKeyboardKey.pageDown].
  ButtonControl get pageDown => this[LogicalKeyboardKey.pageDown];
  /// The Delete key.
  /// 
  /// Maps to [LogicalKeyboardKey.delete].
  ButtonControl get delete => this[LogicalKeyboardKey.delete];
}
