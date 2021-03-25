//
//  SetPassengersPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 14/2/21.
//

import Foundation

struct SetPassengersPacket: ClientboundPacket {
  static let id: Int = 0x4b
  
  var entityId: Int
  var passengers: [Int]

  init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    
    passengers = []
    let count = packetReader.readVarInt()
    for _ in 0..<count {
      let passenger = packetReader.readVarInt()
      passengers.append(passenger)
    }
  }
}
