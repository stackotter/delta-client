import Foundation

public struct LoginDisconnectEvent: Event {
  public var reason: String
  
  public init(reason: String) {
    self.reason = reason
  }
}
