//
//  EntityMetadataPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 14/2/21.
//

import Foundation

public struct EntityMetadataPacket: ClientboundPacket {
  public static let id: Int = 0x44
  
  public var entityId: Int

  public init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    // IMPLEMENT: the rest of this packet
  }
}
