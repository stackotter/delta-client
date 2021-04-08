//
//  SoundEffectPacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 20/2/21.
//

import Foundation

struct SoundEffectPacket: ClientboundPacket {
  static let id: Int = 0x51
  
  var soundId: Int
  var soundCategory: Int
  var effectPositionX: Int
  var effectPositionY: Int
  var effectPositionZ: Int
  var volume: Float
  var pitch: Float

  init(from packetReader: inout PacketReader) throws {
    soundId = packetReader.readVarInt()
    soundCategory = packetReader.readVarInt()
    effectPositionX = packetReader.readInt()
    effectPositionY = packetReader.readInt()
    effectPositionZ = packetReader.readInt()
    volume = packetReader.readFloat()
    pitch = packetReader.readFloat()
  }
}
