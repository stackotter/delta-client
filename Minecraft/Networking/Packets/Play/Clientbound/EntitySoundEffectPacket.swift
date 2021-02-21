//
//  EntitySoundEffectPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 20/2/21.
//

import Foundation

struct EntitySoundEffectPacket: ClientboundPacket {
  static let id: Int = 0x50
  
  var soundId: Int32
  var soundCategory: Int32
  var entityId: Int32
  var volume: Float
  var pitch: Float

  init(from packetReader: inout PacketReader) throws {
    soundId = packetReader.readVarInt()
    soundCategory = packetReader.readVarInt()
    entityId = packetReader.readVarInt()
    volume = packetReader.readFloat()
    pitch = packetReader.readFloat()
  }
}
