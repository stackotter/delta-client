import Foundation

public enum LegacyFormattedTextError: Error {
  case missingFormattingCodeCharacter
  case invalidFormattingCodeCharacter(Character)
}
