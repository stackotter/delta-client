import Foundation

public enum IdentifierError: LocalizedError {
  case invalidIdentifier(String, Error)
  case emptyNamespace
  case emptyName
}
