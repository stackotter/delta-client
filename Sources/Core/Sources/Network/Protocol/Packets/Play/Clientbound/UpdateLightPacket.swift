import Foundation

public struct UpdateLightPacket: ClientboundPacket {
  public static let id: Int = 0x24
  
  public var chunkPosition: ChunkPosition
  public var trustEdges: Bool
  public var skyLightMask: Int
  public var blockLightMask: Int
  public var emptySkyLightMask: Int
  public var emptyBlockLightMask: Int
  public var skyLightArrays: [[UInt8]]
  public var blockLightArrays: [[UInt8]]
  
  public init(from packetReader: inout PacketReader) throws {
    let chunkX = packetReader.readVarInt()
    let chunkZ = packetReader.readVarInt()
    chunkPosition = ChunkPosition(chunkX: chunkX, chunkZ: chunkZ)
    trustEdges = packetReader.readBool()
    skyLightMask = packetReader.readVarInt()
    blockLightMask = packetReader.readVarInt()
    emptySkyLightMask = packetReader.readVarInt()
    emptyBlockLightMask = packetReader.readVarInt()
    
    skyLightArrays = []
    var numArrays = BinaryUtil.setBits(of: skyLightMask, n: Chunk.numSections + 2).count
    for _ in 0..<numArrays {
      let length = packetReader.readVarInt()
      let bytes = packetReader.readByteArray(length: length)
      skyLightArrays.append(bytes)
    }
    
    blockLightArrays = []
    numArrays = BinaryUtil.setBits(of: blockLightMask, n: Chunk.numSections + 2).count
    for _ in 0..<numArrays {
      let length = packetReader.readVarInt()
      let bytes = packetReader.readByteArray(length: length)
      blockLightArrays.append(bytes)
    }
  }
  
  private static func unpackLightingArray(_ packed: [UInt8]) -> [UInt8] {
    var unpacked: [UInt8] = []
    for packedLight in packed {
      unpacked.append(packedLight & 0x0f)
      unpacked.append(packedLight >> 4)
    }
    return unpacked
  }
  
  /// Gets a list of sections present based on a bitmask.
  private static func sectionsPresent(in bitmask: Int) -> [Int] {
    var present = BinaryUtil.setBits(of: bitmask, n: Chunk.numSections + 2)
    present = present.map { $0 - 1 }
    return present
  }
  
  public func handle(for client: Client) throws {
    let skyLightIndices = Self.sectionsPresent(in: skyLightMask)
    let blockLightIndices = Self.sectionsPresent(in: blockLightMask)
    
    var unpackedSkyLightArrays: [Int: [UInt8]] = [:]
    for (index, array) in zip(skyLightIndices, skyLightArrays) {
      unpackedSkyLightArrays[index] = Self.unpackLightingArray(array)
    }
    
    var unpackedBlockLightArrays: [Int: [UInt8]] = [:]
    for (index, array) in zip(blockLightIndices, blockLightArrays) {
      unpackedBlockLightArrays[index] = Self.unpackLightingArray(array)
    }
    
    let data = ChunkLightingUpdateData(
      trustEdges: trustEdges,
      emptySkyLightSections: Self.sectionsPresent(in: emptySkyLightMask),
      emptyBlockLightSections: Self.sectionsPresent(in: emptyBlockLightMask),
      skyLightArrays: unpackedSkyLightArrays,
      blockLightArrays: unpackedBlockLightArrays)
    client.game.world.updateChunkLighting(at: chunkPosition, with: data)
  }
}
