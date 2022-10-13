import Foundation
import Network

public enum PingError: LocalizedError {
  case connectionFailed(NWError)
  
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
