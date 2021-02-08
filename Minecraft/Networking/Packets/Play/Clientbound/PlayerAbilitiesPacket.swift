//
//  PlayerAbilities.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 3/1/21.
//

import Foundation

struct PlayerAbilitiesPacket: Packet {
  typealias PacketType = PlayerAbilitiesPacket
  static let id: Int = 0x31
  
  var flags: PlayerFlags
  var flyingSpeed: Float
  var fovModifier: Float
  
  static func from(_ packetReader: inout PacketReader) -> PlayerAbilitiesPacket {
    let flags = PlayerFlags(rawValue: packetReader.readUnsignedByte())
    let flyingSpeed = packetReader.readFloat()
    let fovModifier = packetReader.readFloat()
    
    return PlayerAbilitiesPacket(flags: flags, flyingSpeed: flyingSpeed, fovModifier: fovModifier)
  }
}
