//
//  PlayerAbilities.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 30/1/21.
//

import Foundation

public struct PlayerAbilities: OptionSet {
  public let rawValue: UInt8
  
  public init(rawValue: UInt8) {
    self.rawValue = rawValue
  }
  
  public static let invulnerable = PlayerAbilities(rawValue: 0x01)
  public static let flying = PlayerAbilities(rawValue: 0x02)
  public static let allowFlying = PlayerAbilities(rawValue: 0x04)
  public static let creativeMode = PlayerAbilities(rawValue: 0x08) // instant break
}
