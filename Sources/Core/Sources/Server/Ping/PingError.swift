import Foundation

public enum PingError: LocalizedError {
  case connectionFailed(Error)

  public var errorDescription: String? {
    switch self {
      case .connectionFailed(let error):
        return """
        Connection failed.
        Reason: \(error.localizedDescription)
        """
    }
  }
}
