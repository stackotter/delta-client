import Foundation

public struct ErrorEvent: Event {
  public var error: Error
  public var message: String?
  
  public init(error: Error, message: String? = nil) {
    self.error = error
    self.message = message
  }
}
