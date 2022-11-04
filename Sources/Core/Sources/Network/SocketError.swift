import Foundation

public enum SocketError: LocalizedError {
  case actionFailed(String)
  case blocked
  case disconnected
  case unsupportedAddressFamily(rawValue: Int)

  public var errorDescription: String? {
    switch self {
      case .actionFailed(let action):
        return """
        Socket action failed.
        Action: \(action)
        """
      case .blocked:
        return "A socket action failed because it blocked and the socket was non-blocking."
      case .disconnected:
        return "A socket action failed because the socket was disconnected."
      case .unsupportedAddressFamily(let rawValue):
        return """
        Unsupported address family.
        Raw value: \(rawValue)
        """
    }
  }
}
