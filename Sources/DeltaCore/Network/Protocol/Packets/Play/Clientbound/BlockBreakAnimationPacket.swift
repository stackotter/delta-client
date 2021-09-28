//
//  BlockBreakAnimationPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

public struct BlockBreakAnimationPacket: ClientboundPacket {
  public static let id: Int = 0x08
  
  public var entityId: Int
  public var location: Position
  public var destroyStage: Int8
  
  public init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    location = packetReader.readPosition()
    destroyStage = packetReader.readByte()
  }
}
