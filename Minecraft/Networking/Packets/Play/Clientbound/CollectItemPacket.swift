//
//  CollectItemPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 20/2/21.
//

import Foundation

struct CollectItemPacket: ClientboundPacket {
  static let id: Int = 0x55
  
  var collectedEntityId: Int
  var collectorEntityId: Int
  var pickupItemCount: Int

  init(from packetReader: inout PacketReader) throws {
    collectedEntityId = packetReader.readVarInt()
    collectorEntityId = packetReader.readVarInt()
    pickupItemCount = packetReader.readVarInt()
  }
}
