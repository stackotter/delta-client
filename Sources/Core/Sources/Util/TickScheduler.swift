import Concurrency
import Foundation
import Darwin
import FirebladeECS

/// A highly accurate timer used to implement the ticking mechanism.
public final class TickScheduler {
  /// The ECS nexus to perform operations on.
  public var nexus: Nexus
  /// The systems to run each tick. In execution order.
  public var systems: [System] = []
  
  /// The number of ticks to perform per second.
  public var ticksPerSecond: Double = 20
  /// Incremented each tick.
  public var tickNumber = 0
  /// The time that the most recent tick began, in unix epoch seconds.
  public var mostRecentTick: Double = CFAbsoluteTimeGetCurrent()
  
  private var nexusLock: ReadWriteLock
  private var shouldCancel: AtomicBool = AtomicBool(initialValue: false)
  private var timebaseInfo = mach_timebase_info_data_t()
  
  /// Creates a new tick scheduler.
  /// - Parameters:
  ///   - nexus: The nexus to run updates on.
  ///   - lock: The lock to acquire for each tick to keep the nexus threadsafe.
  public init(_ nexus: Nexus, lock: ReadWriteLock) {
    self.nexus = nexus
    nexusLock = lock
  }
  
  /// Adds a system to the tick loop. Systems are run in the order they are added.
  public func addSystem(_ system: System) {
    systems.append(system)
  }
  
  /// Cancels the scheduler at the start of the next tick.
  public func cancel() {
    shouldCancel.value = true
  }
  
  /// Should only be called once on a given tick scheduler.
  public func startTickLoop() {
    Thread.detachNewThread {
      autoreleasepool {
        self.configureThread()
        
        self.mostRecentTick = CFAbsoluteTimeGetCurrent()
        let nanosecondsPerTick = UInt64(1 / self.ticksPerSecond * Double(NSEC_PER_SEC))
        var when = mach_absolute_time()
        while !self.shouldCancel.value {
          when += self.nanosToAbs(nanosecondsPerTick)
          mach_wait_until(when)
          self.mostRecentTick = CFAbsoluteTimeGetCurrent()
          self.tick()
        }
      }
    }
  }
  
  /// Run all of the systems.
  private func tick() {
    nexusLock.acquireWriteLock()
    nexusLock.unlock()
    for system in systems {
      system.update(nexus)
    }
    tickNumber += 1
  }
  
  // MARK: Thread setup
  
  private func configureThread() {
    mach_timebase_info(&timebaseInfo)
    let clock2abs = Double(timebaseInfo.denom) / Double(timebaseInfo.numer) * Double(NSEC_PER_SEC)
    
    let period      = UInt32(0.00 * clock2abs) // TODO: figure out what these three parameters do so that they can be optimised
    let computation = UInt32(1 / ticksPerSecond * clock2abs) // TODO: adjust according to how strenuous ticks end up being
    let constraint  = UInt32(1 / ticksPerSecond * clock2abs)
    
    let THREAD_TIME_CONSTRAINT_POLICY_COUNT = mach_msg_type_number_t(MemoryLayout<thread_time_constraint_policy>.size / MemoryLayout<integer_t>.size)
    
    var policy = thread_time_constraint_policy()
    var ret: Int32
    let thread: thread_port_t = pthread_mach_thread_np(pthread_self())
    
    policy.period = period
    policy.computation = computation
    policy.constraint = constraint
    policy.preemptible = 0
    
    ret = withUnsafeMutablePointer(to: &policy) {
      $0.withMemoryRebound(to: integer_t.self, capacity: Int(THREAD_TIME_CONSTRAINT_POLICY_COUNT)) {
        thread_policy_set(thread, UInt32(THREAD_TIME_CONSTRAINT_POLICY), $0, THREAD_TIME_CONSTRAINT_POLICY_COUNT)
      }
    }
    
    if ret != KERN_SUCCESS {
      mach_error("thread_policy_set:", ret)
      exit(1)
    }
  }
  
  private func nanosToAbs(_ nanos: UInt64) -> UInt64 {
    return nanos * UInt64(timebaseInfo.denom) / UInt64(timebaseInfo.numer)
  }
}
