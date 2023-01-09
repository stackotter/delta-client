import Foundation

public struct MultiBlockUpdatePacket: ClientboundPacket {
  public static let id: Int = 0x0f

  /// A block change in a multi-block change.
  public struct BlockUpdateRecord {
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
  public var records: [BlockUpdateRecord]

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
      let record = BlockUpdateRecord(x: x, y: y, z: z, blockId: blockId)
      records.append(record)
    }
  }

  public func handle(for client: Client) throws {
    let updates = records.map { record in
      return World.Event.SingleBlockUpdate(
        position: BlockPosition(
          x: Int(record.x) + chunkPosition.chunkX * Chunk.width,
          y: Int(record.y),
          z: Int(record.z) + chunkPosition.chunkZ * Chunk.depth
        ),
        newState: record.blockId
      )
    }

    client.game.world.processMultiBlockUpdate(updates, inChunkAt: chunkPosition)
  }
}
