import Foundation

public enum IdentifierError: LocalizedError {
  case invalidIdentifier(String, Error)
  
  public var errorDescription: String? {
    switch self {
      case .invalidIdentifier(let string, let error):
        return """
        Invalid identifier for string: \(string).
        Reason: \(error.localizedDescription)
        """
    }
  }
}
