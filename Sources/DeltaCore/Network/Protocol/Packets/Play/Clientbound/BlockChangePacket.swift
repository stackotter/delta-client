//
//  BlockChangePacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

public struct BlockChangePacket: ClientboundPacket {
  public static let id: Int = 0x0b
  
  public var location: Position
  public var blockId: Int // the new block state id
  
  public init(from packetReader: inout PacketReader) throws {
    location = packetReader.readPosition()
    blockId = packetReader.readVarInt()
  }
  
  public func handle(for client: Client) throws {
    client.server?.world.setBlockStateId(at: location, to: UInt16(blockId))
  }
}
