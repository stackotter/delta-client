//
//  MultiBlockChangePacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

public struct MultiBlockChangePacket: ClientboundPacket {
  public static let id: Int = 0x0f
  
  /// A block change in a multi-block change.
  public struct BlockChangeRecord {
    /// X coordinate of the block change relative to the chunk.
    public var x: UInt8
    /// Y coordinate of the block change relative to the chunk.
    public var y: UInt8
    /// Z coordinate of the block change relative to the chunk.
    public var z: UInt8
    
    /// The new block state for the block.
    public var blockId: Int
  }
  
  /// The position of the chunk the multi-block change occured in.
  public var chunkPosition: ChunkPosition
  /// The block changes.
  public var records: [BlockChangeRecord]
  
  public init(from packetReader: inout PacketReader) throws {
    let chunkX = packetReader.readInt()
    let chunkZ = packetReader.readInt()
    chunkPosition = ChunkPosition(chunkX: chunkX, chunkZ: chunkZ)
    
    records = []
    
    let recordCount = packetReader.readVarInt()
    for _ in 0..<recordCount {
      let val = packetReader.readUnsignedByte()
      let x = val >> 4 & 0x0f
      let z = val & 0x0f
      let y = packetReader.readUnsignedByte()
      let blockId = packetReader.readVarInt()
      let record = BlockChangeRecord(x: x, y: y, z: z, blockId: blockId)
      records.append(record)
    }
  }
  
  public func handle(for client: Client) throws {
    records.forEach { record in
      var absolutePosition = Position(
        x: Int(record.x),
        y: Int(record.y),
        z: Int(record.z))
      absolutePosition.x += chunkPosition.chunkX * Chunk.width
      absolutePosition.z += chunkPosition.chunkZ * Chunk.depth
      
      client.server?.world.setBlockStateId(
        at: absolutePosition,
        to: UInt16(record.blockId))
    }
  }
}
