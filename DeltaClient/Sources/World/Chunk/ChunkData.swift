//
//  ChunkData.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 15/1/21.
//

import Foundation

/// A temporary storage format for chunks before they are unpacked
struct ChunkData {
  var position: ChunkPosition
  
  // this packet reader contains a packet as described by https://wiki.vg/Protocol#Chunk_Data
  // chunkX and chunkZ have already been read
  var reader: PacketReader
  
  func unpack(blockPaletteManager: BlockPaletteManager) throws -> UnpackedChunkData {
    do {
      var stopwatch = Stopwatch(mode: .summary)
      stopwatch.startMeasurement("chunk unpack")
      var packetReader = reader // mutable copy
      
      // this first bit isn't too slow (cause it all only happens once)
      let fullChunk = packetReader.readBool()
      let ignoreOldData = packetReader.readBool()
      let primaryBitMask = packetReader.readVarInt()
      let heightMaps = try packetReader.readNBTTag()
      
      var biomes: [UInt8] = []
      if fullChunk {
        // HACK: this could cause issues down the line because it assumes no biome id is greater than 256
        // every fourth byte of this is a biome id (biome ids are
        // stored as big endian ints but are actually never bigger than an int)
        // will have to write wrapper over it to access only all the fourth bytes
        biomes = packetReader.readByteArray(length: 1024 * 4)
      }
      
      _ = packetReader.readVarInt() // data length (not used)
      
      let sections = readChunkSections(&packetReader, primaryBitMask: primaryBitMask)
      
      // read block entities
      let numBlockEntities = packetReader.readVarInt()
      var blockEntities: [BlockEntity] = []
      for _ in 0..<numBlockEntities {
        let blockEntityNBT = try packetReader.readNBTTag()
        do {
          let x: Int = try blockEntityNBT.get("x")
          let y: Int = try blockEntityNBT.get("y")
          let z: Int = try blockEntityNBT.get("z")
          let position = Position(x: x, y: y, z: z)
          // TODO: make identifier not throwing, make it just return the placeholder
          let identifierString: String = (try? blockEntityNBT.get("id")) ?? "deltaclient:placeholder"
          let placeholder = Identifier(namespace: "deltaclient", name: "placeholder")
          let identifier = (try? Identifier(identifierString)) ?? placeholder
          let blockEntity = BlockEntity(position: position, identifier: identifier, nbt: blockEntityNBT)
          blockEntities.append(blockEntity)
        } catch {
          log.warning("Error decoding block entities: \(error.localizedDescription)")
        }
      }
      stopwatch.stopMeasurement("chunk unpack")
      stopwatch.summary()
      
      return UnpackedChunkData(
        chunkPosition: position,
        fullChunk: fullChunk,
        primaryBitMask: primaryBitMask,
        heightMaps: heightMaps,
        ignoreOldData: ignoreOldData,
        biomes: biomes,
        sections: sections,
        blockEntities: blockEntities)
    } catch {
      log.warning("Failed to unpack chunk: \(error.localizedDescription)")
      throw error
    }
  }
  
  func readChunkSections(_ packetReader: inout PacketReader, primaryBitMask: Int) -> [Chunk.Section] {
    var sections: [Chunk.Section] = []
    let presentSections = BinaryUtil.setBits(of: primaryBitMask, n: Chunk.numSections)
    for sectionIndex in 0..<Chunk.numSections {
      if presentSections.contains(sectionIndex) {
        let blockCount = packetReader.readShort()
        let bitsPerBlock = packetReader.readUnsignedByte()
        
        // read palette if present
        var palette: [UInt16] = []
        if bitsPerBlock <= 8 {
          let paletteLength = packetReader.readVarInt()
          for _ in 0..<paletteLength {
            palette.append(UInt16(packetReader.readVarInt()))
          }
        }
        
        // read block states
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
        // empty section
        let section = Chunk.Section()
        sections.append(section)
      }
    }
    return sections
  }
}
