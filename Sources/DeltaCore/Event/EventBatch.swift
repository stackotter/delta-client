import Foundation

public struct EventBatch {
  public var events: [Event] = []
  
  public var isEmpty: Bool {
    return events.isEmpty
  }
  
  public mutating func add(_ event: Event) {
    events.append(event)
  }
}
