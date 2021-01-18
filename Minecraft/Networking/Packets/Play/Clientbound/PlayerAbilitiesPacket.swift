//
//  PlayerAbilities.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 3/1/21.
//

import Foundation

struct PlayerAbilitiesPacket: Packet {
  typealias PacketType = PlayerAbilitiesPacket
  static let id: Int = 0x30
  
  var flags: Flags
  var flyingSpeed: Float
  var fovModifier: Float
  
  struct Flags: OptionSet {
    let rawValue: UInt8
    
    static let invulnerable = Flags(rawValue: 0x01)
    static let flying = Flags(rawValue: 0x02)
    static let allowFlying = Flags(rawValue: 0x04)
    static let creativeMode = Flags(rawValue: 0x08)
  }
  
  static func from(_ packetReader: PacketReader) -> PlayerAbilitiesPacket? {
    var mutableReader = packetReader
    
    let flags = Flags(rawValue: mutableReader.readUnsignedByte())
    let flyingSpeed = mutableReader.readFloat()
    let fovModifier = mutableReader.readFloat()
    
    return PlayerAbilitiesPacket(flags: flags, flyingSpeed: flyingSpeed, fovModifier: fovModifier)
  }
}
