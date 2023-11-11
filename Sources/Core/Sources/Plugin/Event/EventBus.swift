import Foundation

/// A simple yet flexible thread-safe subscriber-based event system. Events are dispatched
/// concurrently.
public class EventBus {
  /// The maximum number of handlers that are allowed to run concurrently.
  public static let maximumConcurrentHandlers = 20

  /// The array of registered event handlers.
  private var handlers: [(Event) -> Void] = []
  /// A lock for managing thread safe read and write of ``handlers``.
  private var handlersLock = ReadWriteLock()

  /// The concurrent dispatch queue for dispatching events.
  private var dispatchQueue = DispatchQueue(label: "events", attributes: .concurrent)
  /// The serial dispatch queue for managing event dispatches without blocking callers.
  private var managementQueue = DispatchQueue(label: "EventBus.managementQueue")
  /// Used to limit the number of event handlers run at once.
  private var semaphore = DispatchSemaphore(value: maximumConcurrentHandlers)

  /// Creates a new event bus.
  public init() {}

  /// Registers a handler to receive updates.
  public func registerHandler(_ handler: @escaping (Event) -> Void) {
    handlersLock.acquireWriteLock()
    defer { handlersLock.unlock() }
    handlers.append(handler)
  }

  /// Concurrently sends an event to all registered handlers. Doesn't block the calling thread.
  public func dispatch(_ event: Event) {
    managementQueue.async {
      // Copy handlers to avoid calling handlers while inside handlersLock.
      // Some handlers may themselves want to acquire the handlersLock (e.g.
      // to register a handler)
      self.handlersLock.acquireReadLock()
      let handlers = self.handlers
      self.handlersLock.unlock()

      for handler in handlers {
        self.semaphore.wait()
        self.dispatchQueue.async {
          handler(event)
          self.semaphore.signal()
        }
      }
    }
  }
}
