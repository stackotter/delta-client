import Darwin
import Concurrency

/// A wrapper around the rwlock C api (`pthread_rwlock_t`).
public final class ReadWriteLock {
  private var lock = pthread_rwlock_t()
  private var lockCount = AtomicInt(initialValue: 0)
  
  public init() {
    pthread_rwlock_init(&lock, nil)
  }
  
  deinit {
    pthread_rwlock_destroy(&lock)
  }
  
  /// Acquire the lock for reading.
  public func acquireReadLock() {
    pthread_rwlock_rdlock(&lock)
    lockCount.value += 1
  }
  
  /// Acquire the lock for writing.
  public func acquireWriteLock() {
    pthread_rwlock_wrlock(&lock)
    lockCount.value += 1
  }
  
  /// Unlock the lock.
  public func unlock() {
    if lockCount.value != 0 {
      pthread_rwlock_unlock(&lock)
      lockCount.value -= 1
    } else {
      log.error("Attempted to unlock a ReadWriteLock yet no lock was acquired")
    }
  }
}
