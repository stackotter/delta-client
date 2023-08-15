import Atomics
import Foundation
import FirebladeECS
import CoreFoundation

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#else
#error("Unsupported platform for TickScheduler")
#endif

/// A highly accurate timer used to implement the ticking mechanism. Completely threadsafe.
public final class TickScheduler: @unchecked Sendable {
  // MARK: Static properties

  public static let defaultTicksPerSecond: Double = 20
  
  // MARK: Public properties

  /// The number of ticks to perform per second.
  public let ticksPerSecond: Double
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
  private var systems: [System] = []
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
  ///   - world: The world to pass to systems (usually used for things such as collisions).
  ///   - ticksPerSecond: The number of ticks per second to run the scheduler at.
  public init(
    _ nexus: Nexus,
    nexusLock: ReadWriteLock,
    _ world: World,
    ticksPerSecond: Double = defaultTicksPerSecond
  ) {
    self.nexus = nexus
    self.nexusLock = nexusLock
    self.world = world
    self.ticksPerSecond = ticksPerSecond
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
    // Acquiring the nexus lock ensures that a tick is not currently in progress
    nexusLock.acquireWriteLock()
    defer { nexusLock.unlock() }
    systems.append(system)
  }

  /// Cancels the scheduler at the start of the next tick.
  public func cancel() {
    shouldCancel.store(true, ordering: .relaxed)
  }

  /// Should only be called once on a given tick scheduler.
  public func startTickLoop() {
    Thread.detachNewThread {
      self.mostRecentTick = CFAbsoluteTimeGetCurrent()
      let nanosecondsPerTick = UInt64(1 / self.ticksPerSecond * 1_000_000_000)

      #if canImport(Darwin)
      autoreleasepool {
        self.configureThread()

        var when = mach_absolute_time()
        self.tick()
        while !self.shouldCancel.load(ordering: .relaxed) {
          when += self.nanosToAbs(nanosecondsPerTick)
          mach_wait_until(when)
          self.mostRecentTick = CFAbsoluteTimeGetCurrent()
          self.tick()
        }
      }

      #elseif canImport(Glibc)
      let delay = timespec(tv_sec: 0, tv_nsec: Int(nanosecondsPerTick))
      var nextTick = timespec()
      clock_gettime(CLOCK_MONOTONIC, &nextTick)
      self.tick()
      while !self.shouldCancel.load(ordering: .relaxed) {
        // Basically just `nextTick += delay`
        nextTick.tv_sec += delay.tv_sec
        nextTick.tv_nsec += delay.tv_nsec
        nextTick.tv_sec += nextTick.tv_nsec / 1_000_000_000
        nextTick.tv_nsec = nextTick.tv_nsec % 1_000_000_000

        var time = timespec()
        clock_gettime(CLOCK_MONOTONIC, &time)

        // Basically just `let sleepTime = nextTick - time`
        var sleepTime = timespec()
        sleepTime.tv_sec = time.tv_sec - nextTick.tv_sec
        sleepTime.tv_nsec = time.tv_nsec - nextTick.tv_nsec
        if sleepTime.tv_nsec < 0 {
          sleepTime.tv_nsec += 1_000_000_000
          sleepTime.tv_sec -= 1
        }

        nanosleep(&sleepTime, nil)
        self.mostRecentTick = CFAbsoluteTimeGetCurrent()
        self.tick()
      }
      #endif
    }
  }

  // MARK: Private methods

  /// Run all of the systems.
  private func tick() {
    // The nexus lock must be held for the duration of the tick because it is used elsewhere as a
    // lock to prevent thread safety issue related to modifying dependencies of the tick method.
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

  #if canImport(Darwin)
  /// Configures the thread's time constraint policy.
  private func configureThread() {
    // TODO: Implement for Linux
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
  #endif

  #if canImport(Darwin)
  /// Converts nanoseconds to mach absolute time.
  private func nanosToAbs(_ nanos: UInt64) -> UInt64 {
    return nanos * UInt64(timebaseInfo.denom) / UInt64(timebaseInfo.numer)
  }
  #endif
}
