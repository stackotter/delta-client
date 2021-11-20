import Foundation

/// A simple yet flexible subscriber-based event system.
public class EventBus {
  /// The array of registered event handlers.
  private var handlers: [(Event) -> Void] = []
  
  /// The dispatch queue for dispatching events. It's serial, not concurrent.
  private var eventThread = DispatchQueue(label: "events")
  
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
