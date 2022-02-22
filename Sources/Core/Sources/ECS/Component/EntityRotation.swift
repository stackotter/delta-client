import FirebladeECS
import Foundation

/// A component storing an entity's rotation in radians.
public class EntityRotation: Component {
  /// The amount of time taken (in seconds) for ``smoothVector`` to transition from one position to the next.
  public var smoothingAmount: Float
  
  /// Pitch in radians.
  public var pitch: Float {
    get {
      _pitch
    }
    set(newValue) {
      previousPitch = _pitch
      _pitch = newValue
      pitchLastUpdated = CFAbsoluteTimeGetCurrent()
    }
  }
  
  /// Yaw in radians.
  public var yaw: Float {
    get {
      _yaw
    }
    set(newValue) {
      previousYaw = _yaw
      _yaw = newValue
      yawLastUpdated = CFAbsoluteTimeGetCurrent()
    }
  }
  
  /// The smoothly interpolated pitch.
  public var smoothPitch: Float {
    let delta = Float(CFAbsoluteTimeGetCurrent() - pitchLastUpdated)
    let progress = MathUtil.clamp(delta / smoothingAmount, 0, 1)
    return MathUtil.lerpAngle(from: previousPitch, to: _pitch, progress: progress)
  }
  
  /// The smoothly interpolated yaw.
  public var smoothYaw: Float {
    let delta = Float(CFAbsoluteTimeGetCurrent() - yawLastUpdated)
    let progress = MathUtil.clamp(delta / smoothingAmount, 0, 1)
    return MathUtil.lerpAngle(from: previousYaw, to: _yaw, progress: progress)
  }
  
  // MARK: Private properties
  
  /// The current pitch.
  private var _pitch: Float
  /// The previous pitch.
  private var previousPitch: Float
  /// The time pitch was last updated. Used for smoothing.
  private var pitchLastUpdated: CFAbsoluteTime
  
  /// The current yaw.
  private var _yaw: Float
  /// The previous yaw.
  private var previousYaw: Float
  /// The time yaw was last updated. Used for smoothing.
  private var yawLastUpdated: CFAbsoluteTime
  
  /// Creates an entity's rotation.
  /// - Parameters:
  ///   - pitch: The pitch in radians. -pi/2 is straight up, 0 is straight ahead, and pi/2 is straight down.
  ///   - yaw: The yaw in radians. Measured counterclockwise from the positive z axis.
  ///   - smoothingAmount: The amount of time (in seconds) for ``smoothYaw`` and ``smoothPitch`` to transition from one position to the next. Defaults to 0 seconds.
  public init(pitch: Float, yaw: Float, smoothingAmount: Float = 0) {
    self._pitch = pitch
    self._yaw = yaw
    self.previousPitch = pitch
    self.previousYaw = yaw
    self.pitchLastUpdated = CFAbsoluteTimeGetCurrent()
    self.yawLastUpdated = CFAbsoluteTimeGetCurrent()
    self.smoothingAmount = smoothingAmount
  }
}
