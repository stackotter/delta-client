//
//  PlayerFlags.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 30/1/21.
//

import Foundation

struct PlayerFlags: OptionSet {
  let rawValue: UInt8
  
  static let invulnerable = PlayerFlags(rawValue: 0x01)
  static let flying = PlayerFlags(rawValue: 0x02)
  static let allowFlying = PlayerFlags(rawValue: 0x04)
  static let creativeMode = PlayerFlags(rawValue: 0x08)
}
