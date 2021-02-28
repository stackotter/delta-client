//
//  ChunkData.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 15/1/21.
//

import Foundation
import os

// stores the raw bytes the chunk was sent as to be decoded later
// this is because chunks aren't sent in a nice order and take a while to decode
// so they're stored as chunk data until we can start unpacking them (in order of distance from player)
struct ChunkData {
  var position: ChunkPosition
  
  // this packet reader contains a packet as described by https://wiki.vg/Protocol#Chunk_Data
  // chunkX and chunkZ have already been read
  var buf: Buffer
  
  func unpack() throws -> Chunk {
    do {
      let start = CFAbsoluteTimeGetCurrent()
      var packetReader = PacketReader(buffer: buf, locale: MinecraftLocale.empty())
      
      // this first bit isn't too slow (cause it all only happens once
      let fullChunk = packetReader.readBool()
      let ignoreOldData = packetReader.readBool()
      let primaryBitMask = packetReader.readVarInt()
      let heightMaps = try packetReader.readNBTTag()
      
      var biomes: [UInt8] = []
      if fullChunk {
        // HACK: this could cause issues down the line because it assumes no biome id is greater than 256
        // every fourth byte of this is a biome id (biome ids are stored as big endian ints but are actually never bigger than an int)
        // will have to write wrapper over it to access only all the fourth bytes
        biomes = packetReader.readByteArray(length: 1024*4)
      }
      
      let _ = packetReader.readVarInt() // data length (not used)
      
      let sections = readChunkSections(&packetReader, primaryBitMask: primaryBitMask)
      
      // read block entities
      let numBlockEntities = packetReader.readVarInt()
      var blockEntities: [BlockEntity] = []
      for _ in 0..<numBlockEntities {
        let blockEntityNBT = try packetReader.readNBTTag()
        do {
          let x: Int32 = try blockEntityNBT.get("x")
          let y: Int32 = try blockEntityNBT.get("y")
          let z: Int32 = try blockEntityNBT.get("z")
          let position = Position(x: x, y: y, z: z)
          let identifierString: String = try! blockEntityNBT.get("id")
          let identifier = try! Identifier(identifierString)
          let blockEntity = BlockEntity(position: position, identifier: identifier, nbt: blockEntityNBT)
          blockEntities.append(blockEntity)
        } catch {
          Logger.log("error decoding block entities: \(error.localizedDescription)")
        }
      }
      let elapsed = CFAbsoluteTimeGetCurrent() - start
      Logger.log(String(format: "completed chunk in %.2fms", elapsed*1000))
      
      let chunk = Chunk(position: position, heightMaps: heightMaps, ignoreOldData: ignoreOldData, biomes: biomes, sections: sections, blockEntities: blockEntities)
      return chunk
    } catch {
      Logger.log("failed to unpack chunk: \(error.localizedDescription)")
      throw error
    }
  }
  
  func readChunkSections(_ packetReader: inout PacketReader, primaryBitMask: Int32) -> [ChunkSection] {
    var sections: [ChunkSection] = []
    for i in 0..<16 { // TODO_LATER: 16 hardcoded here could break future versions
      if primaryBitMask >> i & 0x1 == 0x1 {
        let blockCount = packetReader.readShort()
        let bitsPerBlock = packetReader.readUnsignedByte()
        
        var palette: [UInt16] = []
        if bitsPerBlock <= 8 { // use indirect packet (otherwise indirect packet)
          let paletteLength = packetReader.readVarInt()
          for _ in 0..<paletteLength {
            palette.append(UInt16(packetReader.readVarInt()))
          }
        }
        
        let dataArrayLength = packetReader.readVarInt()
        var dataArray: [UInt64] = []
        for _ in 0..<dataArrayLength {
          dataArray.append(packetReader.buf.readLong(endian: .big))
        }
        
        let blocks: [UInt16] = CompactedLongArray(dataArray, bitsPerEntry: UInt64(bitsPerBlock), numEntries: 4096).decompact().map {
          // i've decided that for now memory space is more important than the performance (storing as uint16 instead of uint16)
          // i wanna try figuring out a more efficient way to convert to uint16 from uint64 (something using pointers probably)
          return UInt16($0)
        }
        let section = ChunkSection(blockIds: blocks, palette: palette, blockCount: blockCount)
        sections.append(section)
      } else {
        let section = ChunkSection() // empty section
        sections.append(section)
      }
    }
    return sections
  }
}
