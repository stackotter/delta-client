import Foundation

public enum IdentifierError: LocalizedError {
  case invalidIdentifier(String, Error)
}
