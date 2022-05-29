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
    let chunkX = try packetReader.readInt()
    let chunkZ = try packetReader.readInt()
    chunkPosition = ChunkPosition(chunkX: chunkX, chunkZ: chunkZ)
    
    records = []
    
    let recordCount = try packetReader.readVarInt()
    for _ in 0..<recordCount {
      let value = try packetReader.readUnsignedByte()
      let x = value >> 4 & 0x0f
      let z = value & 0x0f
      let y = try packetReader.readUnsignedByte()
      let blockId = try packetReader.readVarInt()
      let record = BlockChangeRecord(x: x, y: y, z: z, blockId: blockId)
      records.append(record)
    }
  }
  
  public func handle(for client: Client) throws {
    for record in records {
      var absolutePosition = BlockPosition(
        x: Int(record.x),
        y: Int(record.y),
        z: Int(record.z)
      )
      absolutePosition.x += chunkPosition.chunkX * Chunk.width
      absolutePosition.z += chunkPosition.chunkZ * Chunk.depth
      
      // TODO: Group multiblock changes
      client.game.world.setBlockId(
        at: absolutePosition,
        to: record.blockId
      )
    }
  }
}
