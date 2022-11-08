import Atomics
import Foundation
import FirebladeECS

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#else
#error("Unsupported platform for TickScheduler")
#endif

/// A highly accurate timer used to implement the ticking mechanism.
public final class TickScheduler {
  // MARK: Public properties

  /// The number of ticks to perform per second.
  public var ticksPerSecond: Double = 20
  /// Incremented each tick.
  public private(set) var tickNumber = 0
  /// The time that the most recent tick began, in unix epoch seconds.
  public private(set) var mostRecentTick: Double = CFAbsoluteTimeGetCurrent()

  // MARK: Private properties

  /// The ECS nexus to perform operations on.
  private var nexus: Nexus
  /// The lock to acquire before accessing ``nexus``.
  private var nexusLock: ReadWriteLock
  /// The current world.
  private var world: World
  /// The lock to acquire before accessing ``world``.
  private var worldLock: ReadWriteLock
  /// The systems to run each tick. In execution order.
  public var systems: [System] = []
  /// If `true`, the tick loop will be stopped at the start of the next tick.
  private var shouldCancel = ManagedAtomic<Bool>(false)

  #if canImport(Darwin)
  /// Time base information used in time calculations.
  private var timebaseInfo = mach_timebase_info_data_t()
  #endif

  // MARK: Init

  /// Creates a new tick scheduler.
  /// - Parameters:
  ///   - nexus: The nexus to run updates on.
  ///   - nexusLock: The lock to acquire for each tick to keep the nexus threadsafe.
  public init(_ nexus: Nexus, nexusLock: ReadWriteLock, _ world: World) {
    self.nexus = nexus
    self.nexusLock = nexusLock
    self.world = world
    worldLock = ReadWriteLock()
  }

  deinit {
    cancel()
  }

  // MARK: Public methods

  /// Sets the world to give to the systems each tick.
  /// - Parameter newWorld: The new world.
  public func setWorld(to newWorld: World) {
    worldLock.acquireWriteLock()
    defer { worldLock.unlock() }
    world = newWorld
  }

  /// Adds a system to the tick loop. Systems are run in the order they are added.
  public func addSystem(_ system: System) {
    systems.append(system)
  }

  /// Cancels the scheduler at the start of the next tick.
  public func cancel() {
    shouldCancel.store(true, ordering: .relaxed)
  }

  /// Should only be called once on a given tick scheduler.
  public func startTickLoop() {
    Thread.detachNewThread {
      autoreleasepool {
        self.configureThread()

        self.mostRecentTick = CFAbsoluteTimeGetCurrent()
        let nanosecondsPerTick = UInt64(1 / self.ticksPerSecond * Double(NSEC_PER_SEC))

        #if canImport(Darwin)
        var when = mach_absolute_time()
        self.tick()
        while !self.shouldCancel.load(ordering: .relaxed) {
          when += self.nanosToAbs(nanosecondsPerTick)
          mach_wait_until(when)
          self.mostRecentTick = CFAbsoluteTimeGetCurrent()
          self.tick()
        }
        #elseif canImport(Glibc)
        let delay = timespec(tv_sec: 0, tv_nsec: nanosecondsPerTick)
        var nextTick = timespec()
        clock_gettime(CLOCK_MONOTONIC, &nextTick)
        self.tick()
        while !self.shouldCancel.load(ordering: .relaxed) {
          nextTick = timespec_add_safe(nextTick, delay)
          var time = timespec()
          clock_gettime(CLOCK_MONOTONIC, &time)
          let sleepTime = timespec_sub(nextTick, time)
          nanosleep(sleepTime, nil)
          self.mostRecentTick = CFAbsoluteTimeGetCurrent()
          self.tick()
        }
        #endif
      }
    }
  }

  // MARK: Private methods

  /// Run all of the systems.
  private func tick() {
    nexusLock.acquireWriteLock()
    defer { nexusLock.unlock() }

    worldLock.acquireReadLock()
    let world = world
    worldLock.unlock()

    for system in systems {
      do {
        try system.update(nexus, world)
      } catch {
        log.error("Failed to run \(type(of: system)): \(error)")
        world.eventBus.dispatch(ErrorEvent(error: error, message: "Failed to run \(type(of: system))"))
      }
    }

    tickNumber += 1
  }

  /// Configures the thread's time constraint policy.
  private func configureThread() {
    mach_timebase_info(&timebaseInfo)
    let clockToAbs = Double(timebaseInfo.denom) / Double(timebaseInfo.numer) * Double(NSEC_PER_SEC)

    let period = UInt32(0.00 * clockToAbs)
    let computation = UInt32(1 / ticksPerSecond * clockToAbs)
    let constraint = UInt32(1 / ticksPerSecond * clockToAbs)

    let threadTimeConstraintPolicyCount = mach_msg_type_number_t(MemoryLayout<thread_time_constraint_policy>.size / MemoryLayout<integer_t>.size)

    var policy = thread_time_constraint_policy()
    var ret: Int32
    let thread: thread_port_t = pthread_mach_thread_np(pthread_self())

    policy.period = period
    policy.computation = computation
    policy.constraint = constraint
    policy.preemptible = 0

    ret = withUnsafeMutablePointer(to: &policy) {
      $0.withMemoryRebound(to: integer_t.self, capacity: Int(threadTimeConstraintPolicyCount)) {
        thread_policy_set(thread, UInt32(THREAD_TIME_CONSTRAINT_POLICY), $0, threadTimeConstraintPolicyCount)
      }
    }

    if ret != KERN_SUCCESS {
      mach_error("thread_policy_set:", ret)
      exit(1)
    }

    // TODO: properly handle error
  }

  #if canImport(Darwin)
  /// Converts nanoseconds to mach absolute time.
  private func nanosToAbs(_ nanos: UInt64) -> UInt64 {
    return nanos * UInt64(timebaseInfo.denom) / UInt64(timebaseInfo.numer)
  }
  #endif
}
