//
//  ParticlePacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

struct ParticlePacket: ClientboundPacket {
  static let id: Int = 0x23
  
  var particleId: Int
  var isLongDistance: Bool
  var position: EntityPosition
  var offsetX: Float
  var offsetY: Float
  var offsetZ: Float
  var particleData: Float
  var particleCount: Int

  init(from packetReader: inout PacketReader) throws {
    particleId = packetReader.readInt()
    isLongDistance = packetReader.readBool()
    position = packetReader.readEntityPosition()
    offsetX = packetReader.readFloat()
    offsetY = packetReader.readFloat()
    offsetZ = packetReader.readFloat()
    particleData = packetReader.readFloat()
    particleCount = packetReader.readInt()
    
    // IMPLEMENT: there is also a data field but i really don't feel like decoding it rn
  }
}
