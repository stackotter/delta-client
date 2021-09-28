//
//  ChunkDataPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 13/1/21.
//

import Foundation
import DeltaCoreC

public struct ChunkDataPacket: ClientboundPacket {
  public static let id: Int = 0x21
  
  public var position: ChunkPosition
  public var fullChunk: Bool
  public var primaryBitMask: Int
  public var heightMap: HeightMap
  public var ignoreOldData: Bool
  public var biomes: [UInt8]
  public var sections: [Chunk.Section]
  public var blockEntities: [BlockEntity]
  
  public var presentSections: [Int] {
    return BinaryUtil.setBits(of: primaryBitMask, n: Chunk.numSections)
  }
  
  public init(from packetReader: inout PacketReader) throws {
    var stopwatch = Stopwatch(mode: .summary)
    stopwatch.startMeasurement("chunk unpack")
    let chunkX = Int(packetReader.readInt())
    let chunkZ = Int(packetReader.readInt())
    position = ChunkPosition(chunkX: chunkX, chunkZ: chunkZ)
    do {
      fullChunk = packetReader.readBool()
      ignoreOldData = packetReader.readBool()
      primaryBitMask = packetReader.readVarInt()
      
      let heightMaps = try packetReader.readNBTCompound()
      let heightMapCompact: [Int] = try heightMaps.get("WORLD_SURFACE")
      let skyLightBlockingHeightMapCompact: [Int] = try heightMaps.get("MOTION_BLOCKING")
      let heightMap = Self.unpackHeightMap(heightMapCompact)
      let skyLightBlockingHeightMap = Self.unpackHeightMap(skyLightBlockingHeightMapCompact)
      self.heightMap = HeightMap(heightMap: heightMap, skyLightBlockingHeightMap: skyLightBlockingHeightMap)
      
      // TODO: properly unpack biomes
      biomes = []
      if fullChunk {
        // HACK: this could cause issues down the line because it assumes no biome id is greater than 256
        // every fourth byte of this is a biome id (biome ids are
        // stored as big endian ints but are actually never bigger than an int)
        // will have to write wrapper over it to access only all the fourth bytes
        biomes = packetReader.readByteArray(length: 1024 * 4)
      }
      
      _ = packetReader.readVarInt() // Data length (not used)
      
      sections = Self.readChunkSections(&packetReader, primaryBitMask: primaryBitMask)
      
      // Read block entities
      let numBlockEntities = packetReader.readVarInt()
      blockEntities = []
      for _ in 0..<numBlockEntities {
        let blockEntityNBT = try packetReader.readNBTCompound()
        do {
          let x: Int = try blockEntityNBT.get("x")
          let y: Int = try blockEntityNBT.get("y")
          let z: Int = try blockEntityNBT.get("z")
          let position = Position(x: x, y: y, z: z)
          // TODO: make identifier not throwing, make it just return the placeholder
          let identifierString: String = (try? blockEntityNBT.get("id")) ?? "deltacore:placeholder"
          let placeholder = Identifier(namespace: "deltacore", name: "placeholder")
          let identifier = (try? Identifier(identifierString)) ?? placeholder
          let blockEntity = BlockEntity(position: position, identifier: identifier, nbt: blockEntityNBT)
          blockEntities.append(blockEntity)
        } catch {
          log.warning("Error decoding block entities: \(error.localizedDescription)")
        }
      }
    } catch {
      log.warning("Failed to unpack chunk: \(error.localizedDescription)")
      throw error
    }
    
    stopwatch.stopMeasurement("chunk unpack")
    stopwatch.summary()
  }
  
  public func handle(for client: Client) throws {
    if let existingChunk = client.server?.world.chunk(at: position) {
      existingChunk.update(with: self)
      client.server?.world.eventBatch.add(World.Event.UpdateChunk(position: position))
    } else {
      let chunk = Chunk(self, blockRegistry: client.registry.blockRegistry)
      client.server?.world.addChunk(chunk, at: position)
    }
  }
  
  /// Unpacks a heightmap in the format at https://wiki.vg/Chunk_Format. There are 256 values that are each 9 bits, compacted into longs.
  ///
  /// Pads incomplete heightmaps to a length of 256 with -1s to always return an array of length 256. There are 7
  /// values in each long. Least significant bits are first. Values are in order of increasing x and then increasing z.
  /// The values are the y value of the heighest thing in the map plus 1 because otherwise an empty column would have
  /// a value of -1 which is not possible in this format. This function subtracts 1 to make the heights correspond to the actual
  /// heights of the blocks.
  private static func unpackHeightMap(_ compact: [Int]) -> [Int] {
    var output: [Int] = []
    let mask = 1 << 9 - 1
    for long in compact {
      for i in 0..<7 {
        let height = long >> (i * 9) & mask
        output.append(height - 1)
        
        if output.count == Chunk.blocksPerLayer {
          return output
        }
      }
    }
    
    log.warning("Incomplete heightmap received, only \(output.count) values")
    
    // Pad incomplete heightmap to recover
    for _ in 0..<(Chunk.blocksPerLayer - output.count) {
      output.append(-1)
    }
    return output
  }
  
  /// Reads the chunk section data from the given packet. The bitmask contains which chunk sections are present.
  ///
  /// Some C code is used to quickly unpack the compacted long arrays which contain the block data. This
  /// is because Swift was too slow for the tight loop and c was so many times faster.
  private static func readChunkSections(_ packetReader: inout PacketReader, primaryBitMask: Int) -> [Chunk.Section] {
    var sections: [Chunk.Section] = []
    let presentSections = BinaryUtil.setBits(of: primaryBitMask, n: Chunk.numSections)
    for sectionIndex in 0..<Chunk.numSections {
      if presentSections.contains(sectionIndex) {
        let blockCount = packetReader.readShort()
        let bitsPerBlock = packetReader.readUnsignedByte()
        
        // Read palette if present
        var palette: [UInt16] = []
        if bitsPerBlock <= 8 {
          let paletteLength = packetReader.readVarInt()
          for _ in 0..<paletteLength {
            palette.append(UInt16(packetReader.readVarInt()))
          }
        }
        
        // Read block states
        let dataArrayLength = packetReader.readVarInt()
        var dataArray: [UInt64] = []
        for _ in 0..<dataArrayLength {
          dataArray.append(UInt64(packetReader.buffer.readLong(endian: .big)))
        }
        var blocks: [UInt16] = [UInt16](repeating: 0, count: 4096)
        unpack_long_array(&dataArray, Int32(dataArray.count), Int32(bitsPerBlock), &blocks)
        
        let section = Chunk.Section(blockIds: blocks, palette: palette, blockCount: blockCount)
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
}
