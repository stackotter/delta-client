import Foundation

/// An event triggered to update the player's FOV.
public struct ChangeFOVEvent: Event {
  /// The new vertical fov
  public var fovDegrees: Int
  
  public init(fovDegrees: Int) {
    self.fovDegrees = fovDegrees
  }
}
