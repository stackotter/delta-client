import FirebladeECS
import Foundation

/// A component storing an entity's rotation in radians.
public class EntityRotation: Component {
  /// The amount of time taken (in seconds) for ``smoothVector`` to transition from one position to the next.
  public var smoothingAmount: Float
  
  /// Pitch in radians.
  public var pitch: Float
  
  /// Yaw in radians.
  public var yaw: Float
  
  /// The previous pitch.
  public var previousPitch: Float
  
  /// The previous yaw.
  public var previousYaw: Float
  
  /// The smoothly interpolated pitch.
  public var smoothPitch: Float {
    let delta = Float(CFAbsoluteTimeGetCurrent() - lastUpdated)
    let progress = MathUtil.clamp(delta / smoothingAmount, 0, 1)
    return MathUtil.lerpAngle(from: previousPitch, to: pitch, progress: progress)
  }
  
  /// The smoothly interpolated yaw.
  public var smoothYaw: Float {
    let delta = Float(CFAbsoluteTimeGetCurrent() - lastUpdated)
    let progress = MathUtil.clamp(delta / smoothingAmount, 0, 1)
    return MathUtil.lerpAngle(from: previousYaw, to: yaw, progress: progress)
  }
  
  // MARK: Private properties
  
  /// The time that the rotation was last updated. Used for smoothing. Set by ``save()``.
  private var lastUpdated: CFAbsoluteTime
  
  // MARK: Init
  
  /// Creates an entity's rotation.
  /// - Parameters:
  ///   - pitch: The pitch in radians. -pi/2 is straight up, 0 is straight ahead, and pi/2 is straight down.
  ///   - yaw: The yaw in radians. Measured counterclockwise from the positive z axis.
  ///   - smoothingAmount: The amount of time (in seconds) for ``smoothYaw`` and ``smoothPitch`` to transition from one position to the next. Defaults to 0 seconds.
  public init(pitch: Float, yaw: Float, smoothingAmount: Float = 0) {
    self.pitch = pitch
    self.yaw = yaw
    self.previousPitch = pitch
    self.previousYaw = yaw
    self.smoothingAmount = smoothingAmount
    lastUpdated = CFAbsoluteTimeGetCurrent()
  }
  
  // MARK: Public methods
  
  /// Saves the current pitch and yaw as the values to smooth from.
  public func save() {
    previousPitch = pitch
    previousYaw = yaw
    lastUpdated = CFAbsoluteTimeGetCurrent()
  }
}
