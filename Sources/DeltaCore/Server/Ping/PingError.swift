import Foundation
import Network

public enum PingError: LocalizedError {
  case connectionFailed(NWError)
}
