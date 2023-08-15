import CoreFoundation
import FirebladeECS
import FirebladeMath

/// A component storing the player's FOV.
public class PlayerFOV: Component {
  /// The FOV multiplier from the previous tick.
  public var previousMultiplier: Float
  /// The FOV multiplier from the next tick.
  public var multiplier: Float
  /// The time at which the FOV multiplier was last calculated.
  public var lastUpdated: CFAbsoluteTime

  /// The FOV multiplier smoothed over the course of the current tick. Smooths from
  /// the latest value saved using ``PlayerFOV/save``.
  public var smoothMultiplier: Float {
    let delta = Float(CFAbsoluteTimeGetCurrent() - lastUpdated)
    let tickProgress = MathUtil.clamp(delta * Float(TickScheduler.defaultTicksPerSecond), 0, 1)
    return tickProgress * (multiplier - previousMultiplier) + previousMultiplier
  }

  /// Creates a player FOV multiplier component.
  public init(multiplier: Float = 1) {
    self.previousMultiplier = multiplier
    self.multiplier = multiplier
    lastUpdated = CFAbsoluteTimeGetCurrent()
  }

  /// Saves the current value as the value to smooth from.
  public func save() {
    previousMultiplier = multiplier
    lastUpdated = CFAbsoluteTimeGetCurrent()
  }
}
