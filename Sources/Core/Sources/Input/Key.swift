import Foundation

public enum Key: CustomStringConvertible, Hashable {
  case leftShift
  case rightShift
  case leftControl
  case rightControl
  case leftOption
  case rightOption
  case leftCommand
  case rightCommand
  case function

  case a
  case b
  case c
  case d
  case e
  case f
  case g
  case h
  case i
  case j
  case k
  case l
  case m
  case n
  case o
  case p
  case q
  case r
  case s
  case t
  case u
  case v
  case w
  case x
  case y
  case z

  case zero
  case one
  case two
  case three
  case four
  case five
  case six
  case seven
  case eight
  case nine

  case numberPad0
  case numberPad1
  case numberPad2
  case numberPad3
  case numberPad4
  case numberPad5
  case numberPad6
  case numberPad7
  case numberPad8
  case numberPad9

  case numberPadDecimal
  case numberPadPlus
  case numberPadMinus
  case numberPadEquals
  case numberPadAsterisk
  case numberPadForwardSlash
  case numberPadClear
  case numberPadEnter

  case dash
  case equals
  case backSlash
  case forwardSlash
  case openSquareBracket
  case closeSquareBracket

  case comma
  case period
  case backTick
  case semicolon
  case singleQuote

  case tab
  case insert
  case enter
  case space
  case delete
  case escape

  case f1
  case f2
  case f3
  case f4
  case f5
  case f6
  case f7
  case f8
  case f9
  case f10
  case f11
  case f12
  case f13
  case f14
  case f15
  case f16
  case f17
  case f18
  case f19
  case f20

  case home
  case end
  case pageUp
  case pageDown
  case forwardDelete

  case upArrow
  case downArrow
  case leftArrow
  case rightArrow

  case leftMouseButton
  case rightMouseButton
  case scrollUp
  case scrollDown

  case otherMouseButton(Int)

  /// Whether the key is a control key.
  public var isControl: Bool {
    self == .leftControl || self == .rightControl
  }

  /// Whether the key is a command key.
  public var isCommand: Bool {
    self == .leftCommand || self == .rightCommand
  }

  /// Whether the key is a shift key.
  public var isShift: Bool {
    self == .leftShift || self == .rightShift
  }

  /// Whether the key is an option key.
  public var isOption: Bool {
    self == .leftOption || self == .rightOption
  }

  /// The key's display name.
  public var description: String {
    name.display
  }

  /// The key's name including both the raw and display representations.
  public var name: (raw: String, display: String) {
    switch self {
      case .leftShift: return ("leftShift", "Left shift")
      case .rightShift: return ("rightShift", "Right shift")
      case .leftControl: return ("leftControl", "Left control")
      case .rightControl: return ("rightControl", "Right control")
      case .leftOption: return ("leftOption", "Left option")
      case .rightOption: return ("rightOption", "Right option")
      case .leftCommand: return ("leftCommand", "Left command")
      case .rightCommand: return ("rightCommand", "Right command")
      case .function: return ("function", "Function")

      case .a: return ("a", "A")
      case .b: return ("b", "B")
      case .c: return ("c", "C")
      case .d: return ("d", "D")
      case .e: return ("e", "E")
      case .f: return ("f", "F")
      case .g: return ("g", "G")
      case .h: return ("h", "H")
      case .i: return ("i", "I")
      case .j: return ("j", "J")
      case .k: return ("k", "K")
      case .l: return ("l", "L")
      case .m: return ("m", "M")
      case .n: return ("n", "N")
      case .o: return ("o", "O")
      case .p: return ("p", "P")
      case .q: return ("q", "Q")
      case .r: return ("r", "R")
      case .s: return ("s", "S")
      case .t: return ("t", "T")
      case .u: return ("u", "U")
      case .v: return ("v", "V")
      case .w: return ("w", "W")
      case .x: return ("x", "X")
      case .y: return ("y", "Y")
      case .z: return ("z", "Z")

      case .zero: return ("zero", "0")
      case .one: return ("one", "1")
      case .two: return ("two", "2")
      case .three: return ("three", "3")
      case .four: return ("four", "4")
      case .five: return ("five", "5")
      case .six: return ("six", "6")
      case .seven: return ("seven", "7")
      case .eight: return ("eight", "8")
      case .nine: return ("nine", "9")

      case .numberPad0: return ("numberPad0", "Numpad 0")
      case .numberPad1: return ("numberPad1", "Numpad 1")
      case .numberPad2: return ("numberPad2", "Numpad 2")
      case .numberPad3: return ("numberPad3", "Numpad 3")
      case .numberPad4: return ("numberPad4", "Numpad 4")
      case .numberPad5: return ("numberPad5", "Numpad 5")
      case .numberPad6: return ("numberPad6", "Numpad 6")
      case .numberPad7: return ("numberPad7", "Numpad 7")
      case .numberPad8: return ("numberPad8", "Numpad 8")
      case .numberPad9: return ("numberPad9", "Numpad 9")

      case .numberPadDecimal: return ("numberPadDecimal", "Numpad .")
      case .numberPadPlus: return ("numberPadPlus", "Numpad +")
      case .numberPadMinus: return ("numberPadMinus", "Numpad -")
      case .numberPadEquals: return ("numberPadEquals", "Numpad =")
      case .numberPadAsterisk: return ("numberPadAsterisk", "Numpad *")
      case .numberPadForwardSlash: return ("numberPadForwardSlash", "Numpad /")
      case .numberPadClear: return ("numberPadClear", "Numpad clear")
      case .numberPadEnter: return ("numberPadEnter", "Numpad enter")

      case .dash: return ("dash", "-")
      case .equals: return ("equals", "=")
      case .backSlash: return ("backSlash", "\\")
      case .forwardSlash: return ("forwardSlash", "/")
      case .openSquareBracket: return ("openSquareBracket", "[")
      case .closeSquareBracket: return ("closeSquareBracket", "]")

      case .comma: return ("comma", ",")
      case .period: return ("period", ".")
      case .backTick: return ("backTick", "`")
      case .semicolon: return ("semicolon", ";")
      case .singleQuote: return ("singleQuote", "'")

      case .tab: return ("tab", "Tab")
      case .insert: return ("insert", "Insert")
      case .enter: return ("enter", "Enter")
      case .space: return ("space", "Space")
      case .delete: return ("delete", "Delete")
      case .escape: return ("escape", "Escape")

      case .f1: return ("f1", "F1")
      case .f2: return ("f2", "F2")
      case .f3: return ("f3", "F3")
      case .f4: return ("f4", "F4")
      case .f5: return ("f5", "F5")
      case .f6: return ("f6", "F6")
      case .f7: return ("f7", "F7")
      case .f8: return ("f8", "F8")
      case .f9: return ("f9", "F9")
      case .f10: return ("f10", "F10")
      case .f11: return ("f11", "F11")
      case .f12: return ("f12", "F12")
      case .f13: return ("f13", "F13")
      case .f14: return ("f14", "F14")
      case .f15: return ("f15", "F15")
      case .f16: return ("f16", "F16")
      case .f17: return ("f17", "F17")
      case .f18: return ("f18", "F18")
      case .f19: return ("f19", "F19")
      case .f20: return ("f20", "F20")
      case .forwardDelete: return ("forwardDelete", "Forward delete")

      case .home: return ("home", "Home")
      case .end: return ("end", "End")
      case .pageUp: return ("pageUp", "Page up")
      case .pageDown: return ("pageDown", "Page down")

      case .upArrow: return ("upArrow", "Up arrow")
      case .downArrow: return ("downArrow", "Down arrow")
      case .leftArrow: return ("leftArrow", "Left arrow")
      case .rightArrow: return ("rightArrow", "Right arrow")

      case .leftMouseButton: return ("leftMouseButton", "Left click")
      case .rightMouseButton: return ("rightMouseButton", "Right click")
      case .scrollUp: return ("scrollUp", "Scroll up")
      case .scrollDown: return ("scrollDown", "Scroll down")

      case .otherMouseButton(let number):
        return ("mouseButton\(number)", "Mouse button \(number)")
    }
  }

  public init?(keyCode: UInt16) {
    if let key = Self.keyCodeToKey[keyCode] {
      self = key
    } else {
      return nil
    }
  }

  private static let keyCodeToKey: [UInt16: Key] = [
    0x00: .a,
    0x01: .s,
    0x02: .d,
    0x03: .f,
    0x04: .h,
    0x05: .g,
    0x06: .z,
    0x07: .x,
    0x08: .c,
    0x09: .v,
    0x0B: .b,
    0x0C: .q,
    0x0D: .w,
    0x0E: .e,
    0x0F: .r,
    0x10: .y,
    0x11: .t,
    0x12: .one,
    0x13: .two,
    0x14: .three,
    0x15: .four,
    0x16: .six,
    0x17: .five,
    0x18: .equals,
    0x19: .nine,
    0x1A: .seven,
    0x1B: .dash,
    0x1C: .eight,
    0x1D: .zero,
    0x1E: .closeSquareBracket,
    0x1F: .o,
    0x20: .u,
    0x21: .openSquareBracket,
    0x22: .i,
    0x23: .p,
    0x25: .l,
    0x26: .j,
    0x27: .singleQuote,
    0x28: .k,
    0x29: .semicolon,
    0x2A: .backSlash,
    0x2B: .comma,
    0x2C: .forwardSlash,
    0x2D: .m,
    0x2E: .m,
    0x2F: .period,
    0x32: .backTick,
    0x41: .numberPadDecimal,
    0x43: .numberPadAsterisk,
    0x45: .numberPadPlus,
    0x47: .numberPadClear,
    0x4B: .numberPadForwardSlash,
    0x4C: .numberPadEnter,
    0x4E: .numberPadMinus,
    0x51: .numberPadEquals,
    0x52: .numberPad0,
    0x53: .numberPad1,
    0x54: .numberPad2,
    0x55: .numberPad3,
    0x56: .numberPad4,
    0x57: .numberPad5,
    0x58: .numberPad6,
    0x59: .numberPad7,
    0x5B: .numberPad8,
    0x5C: .numberPad9,
    0x24: .enter,
    0x30: .tab,
    0x31: .space,
    0x33: .delete,
    0x35: .escape,
    0x40: .f17,
    0x4F: .f18,
    0x50: .f19,
    0x5A: .f20,
    0x60: .f5,
    0x61: .f6,
    0x62: .f7,
    0x63: .f3,
    0x64: .f8,
    0x65: .f9,
    0x67: .f11,
    0x69: .f13,
    0x6A: .f16,
    0x6B: .f14,
    0x6D: .f10,
    0x6F: .f12,
    0x71: .f15,
    0x72: .insert,
    0x73: .home,
    0x74: .pageUp,
    0x75: .forwardDelete,
    0x76: .f4,
    0x77: .end,
    0x78: .f2,
    0x79: .pageDown,
    0x7A: .f1,
    0x7B: .leftArrow,
    0x7C: .rightArrow,
    0x7D: .downArrow,
    0x7E: .upArrow,
  ]
}

extension Key: RawRepresentable {
  /// The key's name in-code. More suitable for config files.
  public var rawValue: String {
    switch self {
      case let .otherMouseButton(number):
        return "mouseButton\(number)"
      default:
        return name.raw
    }
  }

  public init?(rawValue: String) {
    if rawValue.hasPrefix("mouseButton") {
      let number = rawValue.dropFirst("mouseButton".count)
      guard let number = Int(number) else {
        return nil
      }
      self = .otherMouseButton(number)
    } else {
      guard let key = Self.rawValueToKey[rawValue] else {
        return nil
      }
      self = key
    }
  }

  /// Used to convert raw values to keys. Works for all keys except
  /// ``Key/otherMouseButton`` which contains an associated value.
  private static let rawValueToKey: [String: Key] = [
    "leftShift": .leftShift,
    "rightShift": .rightShift,
    "leftControl": .leftControl,
    "rightControl": .rightControl,
    "leftOption": .leftOption,
    "rightOption": .rightOption,
    "leftCommand": .leftCommand,
    "rightCommand": .rightCommand,
    "function": .function,
    "a": .a,
    "b": .b,
    "c": .c,
    "d": .d,
    "e": .e,
    "f": .f,
    "g": .g,
    "h": .h,
    "i": .i,
    "j": .j,
    "k": .k,
    "l": .l,
    "m": .m,
    "n": .n,
    "o": .o,
    "p": .p,
    "q": .q,
    "r": .r,
    "s": .s,
    "t": .t,
    "u": .u,
    "v": .v,
    "w": .w,
    "x": .x,
    "y": .y,
    "z": .z,
    "zero": .zero,
    "one": .one,
    "two": .two,
    "three": .three,
    "four": .four,
    "five": .five,
    "six": .six,
    "seven": .seven,
    "eight": .eight,
    "nine": .nine,
    "numberPad0": .numberPad0,
    "numberPad1": .numberPad1,
    "numberPad2": .numberPad2,
    "numberPad3": .numberPad3,
    "numberPad4": .numberPad4,
    "numberPad5": .numberPad5,
    "numberPad6": .numberPad6,
    "numberPad7": .numberPad7,
    "numberPad8": .numberPad8,
    "numberPad9": .numberPad9,
    "numberPadDecimal": .numberPadDecimal,
    "numberPadPlus": .numberPadPlus,
    "numberPadMinus": .numberPadMinus,
    "numberPadEquals": .numberPadEquals,
    "numberPadAsterisk": .numberPadAsterisk,
    "numberPadForwardSlash": .numberPadForwardSlash,
    "numberPadClear": .numberPadClear,
    "numberPadEnter": .numberPadEnter,
    "dash": .dash,
    "equals": .equals,
    "backSlash": .backSlash,
    "forwardSlash": .forwardSlash,
    "openSquareBracket": .openSquareBracket,
    "closeSquareBracket": .closeSquareBracket,
    "comma": .comma,
    "period": .period,
    "backTick": .backTick,
    "semicolon": .semicolon,
    "singleQuote": .singleQuote,
    "tab": .tab,
    "insert": .insert,
    "enter": .enter,
    "space": .space,
    "delete": .delete,
    "escape": .escape,
    "f1": .f1,
    "f2": .f2,
    "f3": .f3,
    "f4": .f4,
    "f5": .f5,
    "f6": .f6,
    "f7": .f7,
    "f8": .f8,
    "f9": .f9,
    "f10": .f10,
    "f11": .f11,
    "f12": .f12,
    "f13": .f13,
    "f14": .f14,
    "f15": .f15,
    "f16": .f16,
    "f17": .f17,
    "f18": .f18,
    "f19": .f19,
    "f20": .f20,
    "forwardDelete": .forwardDelete,
    "home": .home,
    "end": .end,
    "pageUp": .pageUp,
    "pageDown": .pageDown,
    "upArrow": .upArrow,
    "downArrow": .downArrow,
    "leftArrow": .leftArrow,
    "rightArrow": .rightArrow,
    "leftMouseButton": .leftMouseButton,
    "rightMouseButton": .rightMouseButton,
    "scrollUp": .scrollUp,
    "scrollDown": .scrollDown,
  ]
}

extension Key: Codable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let rawValue = try container.decode(String.self)
    guard let key = Key(rawValue: rawValue) else {
      throw RichError("No such key '\(rawValue)'")
    }
    self = key
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}
