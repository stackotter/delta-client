import Foundation

public struct ConnectionFailedEvent: Event {
  public var networkError: Error
}
