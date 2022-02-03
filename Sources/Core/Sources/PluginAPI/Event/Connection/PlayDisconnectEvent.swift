import Foundation

public struct PlayDisconnectEvent: Event {
  public var reason: String
  
  public init(reason: String) {
    self.reason = reason
  }
}
