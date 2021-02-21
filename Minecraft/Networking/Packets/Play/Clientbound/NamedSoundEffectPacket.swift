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
  var soundCategory: Int32
  var effectPositionX: Int32
  var effectPositionY: Int32
  var effectPositionZ: Int32
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
