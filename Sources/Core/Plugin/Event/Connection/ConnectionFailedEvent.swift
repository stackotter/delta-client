import Foundation
import Network

public struct ConnectionFailedEvent: Event {
  public var networkError: NWError
  
  public init(networkError: NWError) {
    self.networkError = networkError
  }
}
