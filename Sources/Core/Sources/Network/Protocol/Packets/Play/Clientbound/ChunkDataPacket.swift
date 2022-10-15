import Foundation

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
    let chunkX = Int(try packetReader.readInt())
    let chunkZ = Int(try packetReader.readInt())
    position = ChunkPosition(chunkX: chunkX, chunkZ: chunkZ)
    
    fullChunk = try packetReader.readBool()
    ignoreOldData = try packetReader.readBool()
    primaryBitMask = try packetReader.readVarInt()
    
    let heightMaps = try packetReader.readNBTCompound()
    let heightMapCompact: [Int] = try heightMaps.get("MOTION_BLOCKING")
    heightMap = try Self.unpackHeightMap(heightMapCompact.map { UInt64($0) })
    
    biomeIds = []
    if fullChunk {
      biomeIds.reserveCapacity(1024)
      
      // Biomes are stored as big endian ints but biome ids are never bigger than a UInt8, so it's easy to
      let packedBiomes = try packetReader.readByteArray(length: 1024 * 4)
      for i in 0..<1024 {
        biomeIds.append(packedBiomes[i * 4 + 3])
      }
    }
    
    _ = try packetReader.readVarInt() // Data length (not used)
    
    sections = try Self.readChunkSections(&packetReader, primaryBitMask: primaryBitMask)
    
    // Read block entities
    let numBlockEntities = try packetReader.readVarInt()
    blockEntities = []
    blockEntities.reserveCapacity(numBlockEntities)
    for _ in 0..<numBlockEntities {
      do {
        let blockEntityNBT = try packetReader.readNBTCompound()
        
        let x: Int = try blockEntityNBT.get("x")
        let y: Int = try blockEntityNBT.get("y")
        let z: Int = try blockEntityNBT.get("z")
        let position = BlockPosition(x: x, y: y, z: z)
        
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
  private static func unpackHeightMap(_ compact: [UInt64]) throws -> HeightMap {
    let values: [Int] = unpackLongArray(
      bitsPerValue: 9,
      longArray: compact,
      count: Chunk.blocksPerLayer)
    return HeightMap(heightMap: values)
  }
  
  /// Reads the chunk section data from the given packet. The bitmask contains which chunk sections are present.
  ///
  /// Some C code is used to quickly unpack the compacted long arrays which contain the block data. This
  /// is because Swift was too slow for the tight loop and c was so many times faster.
  private static func readChunkSections(_ packetReader: inout PacketReader, primaryBitMask: Int) throws -> [Chunk.Section] {
    var sections: [Chunk.Section] = []
    let presentSections = BinaryUtil.setBits(of: primaryBitMask, n: Chunk.numSections)
    sections.reserveCapacity(presentSections.count)
    
    for sectionIndex in 0..<Chunk.numSections {
      if presentSections.contains(sectionIndex) {
        let blockCount = try packetReader.readShort()
        let bitsPerBlock = try packetReader.readUnsignedByte()
        
        // Read palette if present
        var palette: [UInt16] = []
        if bitsPerBlock <= 8 {
          let paletteLength = try packetReader.readVarInt()
          palette.reserveCapacity(paletteLength)
          for _ in 0..<paletteLength {
            palette.append(UInt16(try packetReader.readVarInt()))
          }
        }
        
        // Read block states
        let dataArrayLength = try packetReader.readVarInt()
        var dataArray: [UInt64] = []
        dataArray.reserveCapacity(dataArrayLength)
        for _ in 0..<dataArrayLength {
          dataArray.append(UInt64(try packetReader.buffer.readLong(endianness: .big)))
        }
        
        let blocks: [UInt16] = unpackLongArray(bitsPerValue: Int(bitsPerBlock), longArray: dataArray, count: Chunk.Section.numBlocks)
        
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
  
  private static func unpackLongArray<T: FixedWidthInteger>(bitsPerValue: Int, longArray: [UInt64], count: Int) -> [T] {
    let mask = T((1 << bitsPerValue) - 1)
    let valuesPerLong = 64 / bitsPerValue
    
    if count / valuesPerLong >= longArray.count {
      // TODO: throw an error
    }
    
    let values = [T](unsafeUninitializedCapacity: Chunk.Section.numBlocks) { buffer, initializedCount in
      longArray.withUnsafeBufferPointer { longPointer in
        for i in 0..<count {
          let index = i / valuesPerLong
          let offset = (i % valuesPerLong) &* bitsPerValue
          
          let value = T(truncatingIfNeeded: longPointer[index] &>> offset) & mask
          buffer[i] = value
        }
      }
      
      initializedCount = count
    }
    
    return values
  }
}
