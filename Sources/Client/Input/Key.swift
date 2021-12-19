import Foundation
import Carbon

public enum Key: Hashable, Codable {
  case code(Int)
  case modifier(ModifierKey)
	
  public var humanReadableLabel: String {
    switch self {
      case .modifier(let modifier):
        switch modifier {
          case .leftShift:
            return "Left shift"
          case .rightShift:
            return "Right shift"
          case .leftControl:
            return "Left control"
          case .rightControl:
            return "Right control"
          case .leftOption:
            return "Left option"
          case .rightOption:
            return "Right option"
          case .leftCommand:
            return "Left command"
          case .rightCommand:
            return "Right command"
          case .function:
            return "Function"
        }
      case .code(let code):
        return Self.keyCodeStrings[code] ?? "Key \(code)"
    }
  }
  
  private static let keyCodeStrings: [Int: String] = [
    0x00: "A",
    0x01: "S",
    0x02: "D",
    0x03: "F",
    0x04: "H",
    0x05: "G",
    0x06: "Z",
    0x07: "X",
    0x08: "C",
    0x09: "V",
    0x0B: "B",
    0x0C: "Q",
    0x0D: "W",
    0x0E: "E",
    0x0F: "R",
    0x10: "Y",
    0x11: "T",
    0x12: "1",
    0x13: "2",
    0x14: "3",
    0x15: "4",
    0x16: "6",
    0x17: "5",
    0x18: "=",
    0x19: "9",
    0x1A: "7",
    0x1B: "-",
    0x1C: "8",
    0x1D: "0",
    0x1E: "]",
    0x1F: "O",
    0x20: "U",
    0x21: "[",
    0x22: "I",
    0x23: "P",
    0x25: "L",
    0x26: "J",
    0x27: "'",
    0x28: "K",
    0x29: ";",
    0x2A: "\\",
    0x2B: ",",
    0x2C: "/",
    0x2D: "N",
    0x2E: "M",
    0x2F: ".",
    0x32: "`",
    0x41: "NP_Dec",
    0x43: "NP*",
    0x45: "NP+",
    0x47: "NP_Clr",
    0x4B: "NP/",
    0x4C: "NP_Enter",
    0x4E: "NP-",
    0x51: "NP=",
    0x52: "NP0",
    0x53: "NP1",
    0x54: "NP2",
    0x55: "NP3",
    0x56: "NP4",
    0x57: "NP5",
    0x58: "NP6",
    0x59: "NP7",
    0x5B: "NP8",
    0x5C: "NP9",
    0x24: "Enter",
    0x30: "Tab",
    0x31: "Space",
    0x33: "Delete",
    0x35: "Escape",
    0x40: "F17",
    0x4F: "F18",
    0x50: "F19",
    0x5A: "F20",
    0x60: "F5",
    0x61: "F6",
    0x62: "F7",
    0x63: "F3",
    0x64: "F8",
    0x65: "F9",
    0x67: "F11",
    0x69: "F13",
    0x6A: "F16",
    0x6B: "F14",
    0x6D: "F10",
    0x6F: "F12",
    0x71: "F15",
    0x72: "Ins",
    0x73: "Home",
    0x74: "Page up",
    0x75: "FDel",
    0x76: "F4",
    0x77: "End",
    0x78: "F2",
    0x79: "Page down",
    0x7A: "F1",
    0x7B: "Left arrow",
    0x7C: "Right arrow",
    0x7D: "Down arrow",
    0x7E: "Up arrow",
  ]
}
