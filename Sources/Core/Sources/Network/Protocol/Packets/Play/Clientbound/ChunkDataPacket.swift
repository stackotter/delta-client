import Foundation

public enum ChunkDataError: LocalizedError {
  case incompleteHeightMap(length: Int)
}

public struct ChunkDataPacket: ClientboundPacket {
  public static let id: Int = 0x21
  
  public var position: ChunkPosition
  public var fullChunk: Bool
  public var primaryBitMask: Int
  public var heightMap: HeightMap
  public var ignoreOldData: Bool
  public var biomeIds: [UInt8]
  public var sections: [Chunk.Section]
  public var blockEntities: [BlockEntity]
  
  public var presentSections: [Int] {
    return BinaryUtil.setBits(of: primaryBitMask, n: Chunk.numSections)
  }
  
  public init(from packetReader: inout PacketReader) throws {
    let chunkX = Int(packetReader.readInt())
    let chunkZ = Int(packetReader.readInt())
    position = ChunkPosition(chunkX: chunkX, chunkZ: chunkZ)
    
    fullChunk = packetReader.readBool()
    ignoreOldData = packetReader.readBool()
    primaryBitMask = packetReader.readVarInt()
    
    let heightMaps = try packetReader.readNBTCompound()
    let heightMapCompact: [Int] = try heightMaps.get("MOTION_BLOCKING")
    heightMap = try Self.unpackHeightMap(heightMapCompact)
    
    biomeIds = []
    if fullChunk {
      biomeIds.reserveCapacity(1024)
      
      // Biomes are stored as big endian ints but biome ids are never bigger than a UInt8, so it's easy to
      let packedBiomes = packetReader.readByteArray(length: 1024 * 4)
      for i in 0..<1024 {
        biomeIds.append(packedBiomes[i * 4 + 3])
      }
    }
    
    _ = packetReader.readVarInt() // Data length (not used)
    
    sections = Self.readChunkSections(&packetReader, primaryBitMask: primaryBitMask)
    
    // Read block entities
    let numBlockEntities = packetReader.readVarInt()
    blockEntities = []
    blockEntities.reserveCapacity(numBlockEntities)
    for _ in 0..<numBlockEntities {
      do {
        let blockEntityNBT = try packetReader.readNBTCompound()
        
        let x: Int = try blockEntityNBT.get("x")
        let y: Int = try blockEntityNBT.get("y")
        let z: Int = try blockEntityNBT.get("z")
        let position = Position(x: x, y: y, z: z)
        
        let identifierString: String = try blockEntityNBT.get("id")
        let identifier = try Identifier(identifierString)
        
        let blockEntity = BlockEntity(position: position, identifier: identifier, nbt: blockEntityNBT)
        
        blockEntities.append(blockEntity)
      } catch {
        log.warning("Error decoding block entity: \(error)")
      }
    }
  }
  
  public func handle(for client: Client) throws {
    if let existingChunk = client.game.world.chunk(at: position) {
      existingChunk.update(with: self)
      client.eventBus.dispatch(World.Event.UpdateChunk(position: position, updatedSections: presentSections))
    } else {
      let chunk = Chunk(self)
      client.game.world.addChunk(chunk, at: position)
    }
  }
  
  /// Unpacks a heightmap in the format at https://wiki.vg/Chunk_Format. There are 256 values that are each 9 bits, compacted into longs.
  private static func unpackHeightMap(_ compact: [Int]) throws -> HeightMap {
    var output: [Int] = []
    output.reserveCapacity(Chunk.blocksPerLayer)
    let mask = 1 << 9 - 1
    for long in compact {
      for i in 0..<7 {
        let height = long >> (i * 9) & mask
        output.append(height - 1)
        
        if output.count == Chunk.blocksPerLayer {
          return HeightMap(heightMap: output)
        }
      }
    }
    
    throw ChunkDataError.incompleteHeightMap(length: output.count)
  }
  
  /// Reads the chunk section data from the given packet. The bitmask contains which chunk sections are present.
  ///
  /// Some C code is used to quickly unpack the compacted long arrays which contain the block data. This
  /// is because Swift was too slow for the tight loop and c was so many times faster.
  private static func readChunkSections(_ packetReader: inout PacketReader, primaryBitMask: Int) -> [Chunk.Section] {
    var sections: [Chunk.Section] = []
    let presentSections = BinaryUtil.setBits(of: primaryBitMask, n: Chunk.numSections)
    sections.reserveCapacity(presentSections.count)
    
    for sectionIndex in 0..<Chunk.numSections {
      if presentSections.contains(sectionIndex) {
        let blockCount = packetReader.readShort()
        let bitsPerBlock = packetReader.readUnsignedByte()
        
        // Read palette if present
        var palette: [UInt16] = []
        if bitsPerBlock <= 8 {
          let paletteLength = packetReader.readVarInt()
          palette.reserveCapacity(paletteLength)
          for _ in 0..<paletteLength {
            palette.append(UInt16(packetReader.readVarInt()))
          }
        }
        
        // Read block states
        let dataArrayLength = packetReader.readVarInt()
        var dataArray: [UInt64] = []
        dataArray.reserveCapacity(dataArrayLength)
        for _ in 0..<dataArrayLength {
          dataArray.append(UInt64(packetReader.buffer.readLong(endian: .big)))
        }
        
//        var blocks: [UInt16] = [UInt16](repeating: 0, count: 4096)
//        unpack_long_array(&dataArray, Int32(dataArray.count), Int32(bitsPerBlock), &blocks)
        let blocks = unpackLongArray(bitsPerBlock: Int(bitsPerBlock), longArray: dataArray)
        
        let section = Chunk.Section(blockIds: blocks, palette: palette, blockCount: Int(blockCount))
        sections.append(section)
      } else {
        // TODO: don't initialise empty sections until they are needed
        // Section is empty
        let section = Chunk.Section()
        sections.append(section)
      }
    }
    return sections
  }
  
  private static func unpackLongArray(bitsPerBlock: Int, longArray: [UInt64]) -> [UInt16] {
    let mask = UInt16((1 << bitsPerBlock) - 1)
    let blocksPerLong = 64 / bitsPerBlock
    
    var blocks: [UInt16] = []
    blocks.reserveCapacity(Chunk.Section.numBlocks)
    
    if 4096 / blocksPerLong >= longArray.count {
      // TODO: throw an error
    }
    
    longArray.withUnsafeBufferPointer { pointer in
      for blockNumber in 0..<Chunk.Section.numBlocks {
        let index = blockNumber / blocksPerLong
        let offset = (blockNumber % blocksPerLong) &* bitsPerBlock
        
        let block = UInt16(truncatingIfNeeded: pointer[index] &>> offset) & mask
        blocks.append(block)
      }
    }
    
    return blocks
  }
}
