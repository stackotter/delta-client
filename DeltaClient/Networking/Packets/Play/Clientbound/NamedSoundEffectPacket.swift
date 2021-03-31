//
//  NamedSoundEffectPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

struct NamedSoundEffectPacket: ClientboundPacket {
  static let id: Int = 0x19
  
  var soundName: Identifier
  var soundCategory: Int
  var effectPositionX: Int
  var effectPositionY: Int
  var effectPositionZ: Int
  var volume: Float
  var pitch: Float
  
  init(from packetReader: inout PacketReader) throws {
    soundName = try packetReader.readIdentifier()
    soundCategory = packetReader.readVarInt()
    effectPositionX = packetReader.readInt()
    effectPositionY = packetReader.readInt()
    effectPositionZ = packetReader.readInt()
    volume = packetReader.readFloat()
    pitch = packetReader.readFloat()
  }
}
