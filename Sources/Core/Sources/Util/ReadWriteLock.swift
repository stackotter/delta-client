import Atomics

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#else
#error("Unsupported platform for ReadWriteLock")
#endif

// TODO: Figure out why removing the `guiState` parameter to `compileGUI` in `PlayerInputSystem` doesn't
//   cause a deadlock every tick (it causes crashes but only in specific conditions). It should cause a
//   deadlock no matter what cause not passing the `guiState` parameter causes `compileGUI` to acquire a
//   nexus lock. After some debugging it seemed like somehow the lock was successfully getting to a lockCount
//   of 2 even though the base nexus lock held by tick scheduler each tick is a write lock (and so is the
//   lock acquired by compileGUI). That just seems like it shouldn't be possible at all???

/// A wrapper around the rwlock C api (`pthread_rwlock_t`).
///
/// Add the `DEBUG_LOCKS` custom flag to enable the `lastLockedBy` property which keeps track of the
/// latest code to acquire the lock, and the `lockCount`/`lastFullyReleasedBy` properties which
/// track the total number of locks held on the lock and the code which last unlocked the lock
/// and brought it to a `lockCount` of 0. These are very useful for debugging deadlocks and double unlocks.
public final class ReadWriteLock {
  private var lock = pthread_rwlock_t()


  #if DEBUG_LOCKS
  public var lastLockedBy: String?
  public var lastFullyReleasedBy: String?
  public var lockCount = ManagedAtomic<Int>(0)
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
    lockCount.wrappingIncrement(ordering: .relaxed)

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
    lockCount.wrappingIncrement(ordering: .relaxed)

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

  #if DEBUG_LOCKS
  /// Unlock the lock.
  public func unlock(file: String = #file, line: Int = #line, column: Int = #column) {
    let count = lockCount.wrappingDecrementThenLoad(ordering: .relaxed)

    pthread_rwlock_wrlock(&stringLock)
    precondition(count >= 0, "Detected unbalanced unlock of ReadWriteLock, unlocked by: \(file):\(line):\(column), last unlocked by: \(lastFullyReleasedBy ?? "no one")")
    if count == 0 {
      lastFullyReleasedBy = "\(file):\(line):\(column)"
    }
    pthread_rwlock_unlock(&stringLock)

    pthread_rwlock_unlock(&lock)
  }
  #else
  /// Unlock the lock.
  public func unlock() {
    pthread_rwlock_unlock(&lock)
  }
  #endif
}
