import Foundation

public struct PlayerFlags: OptionSet {
  public let rawValue: UInt8
  
  public init(rawValue: UInt8) {
    self.rawValue = rawValue
  }
  
  public static let invulnerable = PlayerFlags(rawValue: 0x01)
  public static let flying = PlayerFlags(rawValue: 0x02)
  public static let canFly = PlayerFlags(rawValue: 0x04)
  public static let instantBreak = PlayerFlags(rawValue: 0x08)
}
