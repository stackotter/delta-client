import Foundation

public struct ConnectionFailedEvent: Event {
  public var networkError: Error

  public init(networkError: Error) {
    self.networkError = networkError
  }
}
