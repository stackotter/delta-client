//
//  SetPassengersPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 14/2/21.
//

import Foundation

public struct SetPassengersPacket: ClientboundPacket {
  public static let id: Int = 0x4b
  
  public var entityId: Int
  public var passengers: [Int]

  public init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    
    passengers = []
    let count = packetReader.readVarInt()
    for _ in 0..<count {
      let passenger = packetReader.readVarInt()
      passengers.append(passenger)
    }
  }
}
