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
  
  init(fromReader packetReader: inout PacketReader) {
    flags = PlayerFlags(rawValue: packetReader.readUnsignedByte())
    flyingSpeed = packetReader.readFloat()
    fovModifier = packetReader.readFloat()
  }
}
