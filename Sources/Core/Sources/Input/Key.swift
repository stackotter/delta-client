import Foundation

public enum Key: String, Hashable, Codable {
  case leftShift = "Left shift"
  case rightShift = "Right shift"
  case leftControl = "Left control"
  case rightControl = "Right control"
  case leftOption = "Left option"
  case rightOption = "Right option"
  case leftCommand = "Left command"
  case rightCommand = "Right command"
  case function = "Function"

  case a = "A"
  case b = "B"
  case c = "C"
  case d = "D"
  case e = "E"
  case f = "F"
  case g = "G"
  case h = "H"
  case i = "I"
  case j = "J"
  case k = "K"
  case l = "L"
  case m = "M"
  case n = "N"
  case o = "O"
  case p = "P"
  case q = "Q"
  case r = "R"
  case s = "S"
  case t = "T"
  case u = "U"
  case v = "V"
  case w = "W"
  case x = "X"
  case y = "Y"
  case z = "Z"

  case zero = "0"
  case one = "1"
  case two = "2"
  case three = "3"
  case four = "4"
  case five = "5"
  case six = "6"
  case seven = "7"
  case eight = "8"
  case nine = "9"

  case numberPad0 = "NP0"
  case numberPad1 = "NP1"
  case numberPad2 = "NP2"
  case numberPad3 = "NP3"
  case numberPad4 = "NP4"
  case numberPad5 = "NP5"
  case numberPad6 = "NP6"
  case numberPad7 = "NP7"
  case numberPad8 = "NP8"
  case numberPad9 = "NP9"

  case numberPadDec = "NumPad Dec"
  case numberPadPlus = "NumPad +"
  case numberPadMinus = "NumPad -"
  case numberPadEquals = "NumPad ="
  case numberPadAsterisk = "NumPad *"
  case numberPadForwardSlash = "NumPad /"
  case numberPadClear = "NumPad Clear"
  case numberPadEnter = "NumPad Enter"

  case dash = "-"
  case equals = "="
  case backSlash = "\\"
  case forwardSlash = "/"
  case openSquareBracket = "["
  case closeSquareBracket = "]"

  case comma = ","
  case period = "."
  case backTick = "`"
  case semicolon = ";"
  case singleQuote = "'"

  case tab = "Tab"
  case insert = "Ins"
  case enter = "Enter"
  case space = "Space"
  case delete = "Delete"
  case escape = "Escape"

  case f1 = "F1"
  case f2 = "F2"
  case f3 = "F3"
  case f4 = "F4"
  case f5 = "F5"
  case f6 = "F6"
  case f7 = "F7"
  case f8 = "F8"
  case f9 = "F9"
  case f10 = "F10"
  case f11 = "F11"
  case f12 = "F12"
  case f13 = "F13"
  case f14 = "F14"
  case f15 = "F15"
  case f16 = "F16"
  case f17 = "F17"
  case f18 = "F18"
  case f19 = "F19"
  case f20 = "F20"
  case fDel = "FDel"

  case home = "Home"
  case end = "End"
  case pageUp = "Page up"
  case pageDown = "Page down"

  case upArrow = "Up arrow"
  case downArrow = "Down arrow"
  case leftArrow = "Left arrow"
  case rightArrow = "Right arrow"

  // Mouse buttons

  case leftMouseButton = "Left click"
  case rightMouseButton = "Right click"
  case scrollUp = "Scroll up"
  case scrollDown = "Scroll down"

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
    0x41: .numberPadDec,
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
    0x75: .fDel,
    0x76: .f4,
    0x77: .end,
    0x78: .f2,
    0x79: .pageDown,
    0x7A: .f1,
    0x7B: .leftArrow,
    0x7C: .rightArrow,
    0x7D: .downArrow,
    0x7E: .upArrow
  ]
}
