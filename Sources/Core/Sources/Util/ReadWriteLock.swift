#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#else
#error("Unsupported platform for ReadWriteLock")
#endif

/// A wrapper around the rwlock C api (`pthread_rwlock_t`).
///
/// Add the `DEBUG_LOCKS` custom flag to enable the `lastLockedBy` property which keeps track of the
/// latest code to acquire the lock. This is very useful for debugging deadlocks.
public final class ReadWriteLock {
  private var lock = pthread_rwlock_t()

  #if DEBUG_LOCKS
  public var lastLockedBy: String?
  private var stringLock = pthread_rwlock_t()
  #endif

  /// Creates a new lock.
  public init() {
    pthread_rwlock_init(&lock, nil)
    #if DEBUG_LOCKS
    pthread_rwlock_init(&stringLock, nil)
    #endif
  }

  deinit {
    pthread_rwlock_destroy(&lock)
    #if DEBUG_LOCKS
    pthread_rwlock_destroy(&stringLock)
    #endif
  }

  #if DEBUG_LOCKS
  /// Acquire the lock for reading.
  @inline(never)
  public func acquireReadLock(file: String = #file, line: Int = #line, column: Int = #column) {
    pthread_rwlock_rdlock(&lock)

    pthread_rwlock_wrlock(&stringLock)
    lastLockedBy = "\(file):\(line):\(column)"
    pthread_rwlock_unlock(&stringLock)
  }
  #else
  /// Acquire the lock for reading.
  public func acquireReadLock() {
    pthread_rwlock_rdlock(&lock)
  }
  #endif

  #if DEBUG_LOCKS
  /// Acquire the lock for writing.
  @inline(never)
  public func acquireWriteLock(file: String = #file, line: Int = #line, column: Int = #column) {
    pthread_rwlock_wrlock(&lock)

    pthread_rwlock_wrlock(&stringLock)
    lastLockedBy = "\(file):\(line):\(column)"
    pthread_rwlock_unlock(&stringLock)
  }
  #else
  /// Acquire the lock for writing.
  public func acquireWriteLock() {
    pthread_rwlock_wrlock(&lock)
  }
  #endif

  /// Unlock the lock.
  public func unlock() {
    pthread_rwlock_unlock(&lock)
  }
}
