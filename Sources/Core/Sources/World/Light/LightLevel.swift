import Foundation

/// A light level. Includes both the block light and sky light level.
public struct LightLevel {
  /// The sky light level used for unloaded chunks.
  public static var defaultSkyLightLevel = 0
  /// The block light level used for unloaded chunks.
  public static var defaultBlockLightLevel = 0
  /// The maximum light level.
  public static var maximumLightLevel = 15
  /// The number of light levels.
  public static var levelCount = maximumLightLevel + 1
  
  /// The sky light level.
  public var sky: Int
  /// The block light level.
  public var block: Int
  
  /// Creates a new light level value.
  /// - Parameters:
  ///   - sky: The sky light level.
  ///   - block: The block light level.
  public init(sky: Int, block: Int) {
    self.sky = sky
    self.block = block
  }
  
  /// Creates the default light level.
  public init() {
    sky = Self.defaultSkyLightLevel
    block = Self.defaultBlockLightLevel
  }
  
  /// Gets the highest sky light level and block light level from two light levels.
  /// - Parameters:
  ///   - a: The first light level.
  ///   - b: The second light level.
  /// - Returns: A light level with the maximum of both sky light levels and the maximum of both block light levels.
  public static func max(_ a: LightLevel, _ b: LightLevel) -> LightLevel {
    return LightLevel(sky: Swift.max(a.sky, b.sky), block: Swift.max(a.block, b.block))
  }
}
