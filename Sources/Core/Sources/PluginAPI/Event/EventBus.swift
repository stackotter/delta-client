import Foundation

/// A simple yet flexible thread-safe subscriber-based event system. Events are dispatched concurrently.
public class EventBus {
  /// The array of registered event handlers.
  private var handlers: [(Event) -> Void] = []
  /// A lock for managing thread safe read and write of `handlers`.
  private var handlersLock = ReadWriteLock()
  
  /// The concurrent dispatch queue for dispatching events.
  private var eventThread = DispatchQueue(label: "events", attributes: [.concurrent])
  
  /// Registers a handler to receive updates.
  public func registerHandler(_ handler: @escaping (Event) -> Void) {
    handlersLock.acquireWriteLock()
    defer { handlersLock.unlock() }
    handlers.append(handler)
  }
  
  /// Concurrently sends an event to all registered handlers.
  public func dispatch(_ event: Event) {
    handlersLock.acquireReadLock()
    defer { handlersLock.unlock() }
    
    for handler in handlers {
      eventThread.async {
        handler(event)
      }
    }
  }
}
