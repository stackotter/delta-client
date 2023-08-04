import Foundation

public enum Key: Hashable, Codable {
  typealias RawValue = String
  
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

  case numberPadDec
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
  case fDel

  case home
  case end
  case pageUp
  case pageDown

  case upArrow
  case downArrow
  case leftArrow
  case rightArrow

  // Mouse buttons

  case leftMouseButton
  case rightMouseButton
  case scrollUp
  case scrollDown

  case otherMouseButton(Int)

  public var rawValue: String {
    switch self {
      case .leftShift: return "Left shift"
      case .rightShift: return "Right shift"
      case .leftControl: return "Left control"
      case .rightControl: return "Right control"
      case .leftOption: return "Left option"
      case .rightOption: return "Right option"
      case .leftCommand: return "Left command"
      case .rightCommand: return "Right command"
      case .function: return "Function"

      case .a: return "A"
      case .b: return "B"
      case .c: return "C"
      case .d: return "D"
      case .e: return "E"
      case .f: return "F"
      case .g: return "G"
      case .h: return "H"
      case .i: return "I"
      case .j: return "J"
      case .k: return "K"
      case .l: return "L"
      case .m: return "M"
      case .n: return "N"
      case .o: return "O"
      case .p: return "P"
      case .q: return "Q"
      case .r: return "R"
      case .s: return "S"
      case .t: return "T"
      case .u: return "U"
      case .v: return "V"
      case .w: return "W"
      case .x: return "X"
      case .y: return "Y"
      case .z: return "Z"

      case .zero: return "0"
      case .one: return "1"
      case .two: return "2"
      case .three: return "3"
      case .four: return "4"
      case .five: return "5"
      case .six: return "6"
      case .seven: return "7"
      case .eight: return "8"
      case .nine: return "9"

      case .numberPad0: return "NP0"
      case .numberPad1: return "NP1"
      case .numberPad2: return "NP2"
      case .numberPad3: return "NP3"
      case .numberPad4: return "NP4"
      case .numberPad5: return "NP5"
      case .numberPad6: return "NP6"
      case .numberPad7: return "NP7"
      case .numberPad8: return "NP8"
      case .numberPad9: return "NP9"

      case .numberPadDec: return "NumPad Dec"
      case .numberPadPlus: return "NumPad +"
      case .numberPadMinus: return "NumPad -"
      case .numberPadEquals: return "NumPad: return"
      case .numberPadAsterisk: return "NumPad *"
      case .numberPadForwardSlash: return "NumPad /"
      case .numberPadClear: return "NumPad Clear"
      case .numberPadEnter: return "NumPad Enter"

      case .dash: return "-"
      case .equals: return "="
      case .backSlash: return "\\"
      case .forwardSlash: return "/"
      case .openSquareBracket: return "["
      case .closeSquareBracket: return "]"

      case .comma: return ","
      case .period: return "."
      case .backTick: return "`"
      case .semicolon: return ";"
      case .singleQuote: return "'"

      case .tab: return "Tab"
      case .insert: return "Ins"
      case .enter: return "Enter"
      case .space: return "Space"
      case .delete: return "Delete"
      case .escape: return "Escape"

      case .f1: return "F1"
      case .f2: return "F2"
      case .f3: return "F3"
      case .f4: return "F4"
      case .f5: return "F5"
      case .f6: return "F6"
      case .f7: return "F7"
      case .f8: return "F8"
      case .f9: return "F9"
      case .f10: return "F10"
      case .f11: return "F11"
      case .f12: return "F12"
      case .f13: return "F13"
      case .f14: return "F14"
      case .f15: return "F15"
      case .f16: return "F16"
      case .f17: return "F17"
      case .f18: return "F18"
      case .f19: return "F19"
      case .f20: return "F20"
      case .fDel: return "FDel"

      case .home: return "Home"
      case .end: return "End"
      case .pageUp: return "Page up"
      case .pageDown: return "Page down"

      case .upArrow: return "Up arrow"
      case .downArrow: return "Down arrow"
      case .leftArrow: return "Left arrow"
      case .rightArrow: return "Right arrow"

      // Mouse buttons

      case .leftMouseButton: return "Left click"
      case .rightMouseButton: return "Right click"
      case .scrollUp: return "Scroll up"
      case .scrollDown: return "Scroll down"

      case .otherMouseButton(let number):
        return "Mouse button \(number)"
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
