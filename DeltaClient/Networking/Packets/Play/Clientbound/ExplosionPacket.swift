//
//  ExplosionPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

struct ExplosionPacket: ClientboundPacket {
  static let id: Int = 0x1c
  
  var x: Float
  var y: Float
  var z: Float
  var strength: Float
  var records: [(Int8, Int8, Int8)]
  var playerMotionX: Float
  var playerMotionY: Float
  var playerMotionZ: Float
  
  init(from packetReader: inout PacketReader) throws {
    x = packetReader.readFloat()
    y = packetReader.readFloat()
    z = packetReader.readFloat()
    strength = packetReader.readFloat()
    
    records = []
    let recordCount = packetReader.readInt()
    for _ in 0..<recordCount {
      let record = (
        packetReader.readByte(),
        packetReader.readByte(),
        packetReader.readByte()
      )
      records.append(record)
    }
    
    playerMotionX = packetReader.readFloat()
    playerMotionY = packetReader.readFloat()
    playerMotionZ = packetReader.readFloat()
  }
}
