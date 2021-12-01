import Foundation

/// A simple yet flexible subscriber-based event system.
public class EventBus {
  /// The array of registered event handlers.
  private var handlers: [(Event) -> Void] = []
  
  /// The dispatch queue for concurrently dispatching events.
  private var eventThread = DispatchQueue(label: "events", attributes: .concurrent)
  
  public init() {}
  
  /// Registers a handler to receive updates.
  public func registerHandler(_ handler: @escaping (Event) -> Void) {
    handlers.append(handler)
  }
  
  /// Sends an event to all registered handlers.
  public func dispatch(_ event: Event) {
    for handler in handlers {
      eventThread.async {
        handler(event)
      }
    }
  }
}
