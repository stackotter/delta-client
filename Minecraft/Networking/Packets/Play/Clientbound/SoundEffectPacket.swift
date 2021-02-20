//
//  SoundEffectPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 20/2/21.
//

import Foundation

struct SoundEffectPacket: ClientboundPacket {
  static let id: Int = 0x51
  
  var soundId: Int32
  var soundCategory: Int32
  var effectPositionX: Int32
  var effectPositionY: Int32
  var effectPositionZ: Int32
  var volume: Float
  var pitch: Float

  init(fromReader packetReader: inout PacketReader) throws {
    soundId = packetReader.readVarInt()
    soundCategory = packetReader.readVarInt()
    effectPositionX = packetReader.readInt()
    effectPositionY = packetReader.readInt()
    effectPositionZ = packetReader.readInt()
    volume = packetReader.readFloat()
    pitch = packetReader.readFloat()
  }
}
