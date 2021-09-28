//
//  CollectItemPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 20/2/21.
//

import Foundation

public struct CollectItemPacket: ClientboundPacket {
  public static let id: Int = 0x55
  
  public var collectedEntityId: Int
  public var collectorEntityId: Int
  public var pickupItemCount: Int

  public init(from packetReader: inout PacketReader) throws {
    collectedEntityId = packetReader.readVarInt()
    collectorEntityId = packetReader.readVarInt()
    pickupItemCount = packetReader.readVarInt()
  }
}
