/// Statistics related to a renderer's performance.
public struct RenderStatistics {
  // MARK: Public properties
  
  /// The average CPU time including waiting for vsync. Measured as the time between starting two consecutive frames.
  public var averageFrameTime: Double {
    frameTimes.average()
  }
  
  /// The average CPU time excluding waiting for vsync.
  public var averageCPUTime: Double {
    cpuTimes.average()
  }
  
  /// The average GPU time.
  public var averageGPUTime: Double? {
    gpuCountersEnabled ? gpuTimes.average() : nil
  }
  
  /// The average FPS.
  public var averageFPS: Double {
    return averageFrameTime == 0 ? 0 : 1 / averageFrameTime
  }
  
  /// The theoretical FPS if vsync was disabled.
  public var averageTheoreticalFPS: Double? {
    if let averageGPUTime = averageGPUTime {
      let bottleneck = max(averageCPUTime, averageGPUTime)
      return bottleneck == 0 ? 0 : 1 / bottleneck
    } else {
      return nil
    }
  }
  
  public var gpuCountersEnabled: Bool
  
  // MARK: Private properties
  
  /// The most recent cpu times including waiting for vsync. Measured in seconds.
  private var frameTimes: [Double] = []
  /// The most recent cpu times excluding waiting for vsync. Measured in seconds.
  private var cpuTimes: [Double] = []
  /// The most recent gpu times. Measured in seconds.
  private var gpuTimes: [Double] = []
  
  /// The number of samples for the rolling average.
  public let sampleSize = 20
  
  // MARK: Init
  
  /// Creates a new group of render statistics.
  public init(gpuCountersEnabled: Bool) {
    self.gpuCountersEnabled = gpuCountersEnabled
  }
  
  // MARK: Public methods
  
  /// Updates the statistics with the measurements taken for a frame.
  /// - Parameters:
  ///   - frameTime: The CPU time taken for the frame measured in seconds including waiting for vsync.
  ///   - cpuTime: The CPU time taken for the frame measured in seconds excluding waiting for vsync.
  ///   - gpuTime: The GPU time taken for the frame measured in seconds.
  public mutating func addMeasurement(frameTime: Double, cpuTime: Double, gpuTime: Double?) {
    frameTimes.append(frameTime)
    cpuTimes.append(cpuTime)
    if let gpuTime = gpuTime {
      gpuTimes.append(gpuTime)
    }
    
    if frameTimes.count > sampleSize {
      frameTimes.removeFirst()
      cpuTimes.removeFirst()
      if gpuTime != nil {
        gpuTimes.removeFirst()
      }
    }
  }
}
