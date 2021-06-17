//
//  UpdateHealthPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 14/2/21.
//

import Foundation

struct UpdateHealthPacket: ClientboundPacket {
  static let id: Int = 0x49
  
  var health: Float
  var food: Int
  var foodSaturation: Float

  init(from packetReader: inout PacketReader) throws {
    health = packetReader.readFloat()
    food = packetReader.readVarInt() 
    foodSaturation = packetReader.readFloat()
  }
  
  func handle(for server: Server) throws {
    server.player.health = health
    server.player.food = food
    server.player.saturation = foodSaturation
    
    if health == -1 {
      // handle death
    }
  }
}
