import Foundation
import CoreFoundation
import FirebladeECS
import FirebladeMath

/// A component storing the lerp (if any) that an entity is currently undergoing; lerp is short
/// for linear interpolation.
public class EntityLerpState: Component {
  public var currentLerp: Lerp?

  public struct Lerp {
    public var targetPosition: Vec3d
    public var targetPitch: Float
    public var targetYaw: Float
    public var ticksRemaining: Int

    public init(
      targetPosition: Vec3d,
      targetPitch: Float,
      targetYaw: Float,
      ticksRemaining: Int
    ) {
      self.targetPosition = targetPosition
      self.targetPitch = targetPitch
      self.targetYaw = targetYaw
      self.ticksRemaining = ticksRemaining
    }
  }

  public init() {}

  /// Initiate a lerp to the given position and rotation.
  /// - Parameters:
  ///   - position: Target position.
  ///   - pitch: Target pitch.
  ///   - yaw: Target yaw.
  ///   - duration: Lerp duration in ticks.
  public func lerp(to position: Vec3d, pitch: Float, yaw: Float, duration: Int) {
    currentLerp = Lerp(
      targetPosition: position,
      targetPitch: pitch,
      targetYaw: yaw,
      ticksRemaining: duration
    )
  }

  /// Ticks an entities current lerp returning the entity's new position, pitch, and yaw. If there's no current
  /// lerp, then `nil` is returned.
  public func tick(position: Vec3d, pitch: Float, yaw: Float) -> (position: Vec3d, pitch: Float, yaw: Float)? {
    guard var lerp = currentLerp else {
      return nil
    }

    let progress = 1 / Double(lerp.ticksRemaining)

    lerp.ticksRemaining -= 1
    if lerp.ticksRemaining == 0 {
      currentLerp = nil
    } else {
      currentLerp = lerp
    }

    return (
      MathUtil.lerp(from: position, to: lerp.targetPosition, progress: progress),
      MathUtil.lerp(from: pitch, to: lerp.targetPitch, progress: Float(progress)),
      MathUtil.lerp(from: yaw, to: lerp.targetYaw, progress: Float(progress))
    )
  }
}
