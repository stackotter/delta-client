//
//  UpdateHealthPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 14/2/21.
//

import Foundation

struct UpdateHealthPacket: ClientboundPacket {
  static let id: Int = 0x49
  
  var health: Float
  var food: Int32
  var foodSaturation: Float

  init(from packetReader: inout PacketReader) throws {
    health = packetReader.readFloat()
    food = packetReader.readVarInt() 
    foodSaturation = packetReader.readFloat()
  }
}
