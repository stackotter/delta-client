//
//  PlayerAbilities.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 30/1/21.
//

import Foundation

struct PlayerAbilities: OptionSet {
  let rawValue: UInt8
  
  static let invulnerable = PlayerAbilities(rawValue: 0x01)
  static let flying = PlayerAbilities(rawValue: 0x02)
  static let allowFlying = PlayerAbilities(rawValue: 0x04)
  static let creativeMode = PlayerAbilities(rawValue: 0x08) // instant break
}
