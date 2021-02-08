//
//  ChunkData.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 15/1/21.
//

import Foundation

// stores the raw bytes the chunk was sent as to be decoded later
// this is because chunks aren't sent in a nice order and take a while to decode
// so they're stored as chunk data until we can start unpacking them (in order of distance from player)
struct ChunkData {
  var position: ChunkPosition
  
  // this packet reader contains a packet as described by https://wiki.vg/Protocol#Chunk_Data
  // chunkX and chunkZ have already been read
  var data: Buffer
  
  func unpack() throws -> Chunk {
    var reader = PacketReader(buffer: data)
    let fullChunk = reader.readBool()
    let ignoreOldData = reader.readBool()
    _ = ignoreOldData
    let primaryBitMask = reader.readVarInt()
    let heightMaps = try reader.readNBTTag() // height map, dunno what it's used for yet
    
    // Decoding biomes
    var biomes: [Int32] = []
    if fullChunk {
      // TODO: parse biome data
      for _ in 0..<1024 {
        let biome = reader.readInt()
        biomes.append(biome)
      }
    }
    
    // Decoding data section
    _ = reader.readVarInt() // this reads the data size, it's not necessary to use it to read the data though
    var chunkSections: [ChunkSection] = []
    var numSections = 0
    for i in 0..<16 {
      numSections += Int(primaryBitMask >> i) & 0x01
    }
    for _ in 0..<numSections {
      // read chunk section:
      let blockCount = reader.readShort() // used for lighting purposes apparently
      _ = blockCount
      var bitsPerBlock = Int(reader.readByte())
      
      if bitsPerBlock < 4 {
        bitsPerBlock = 4
      }
      
      // reading palette:
      var palette: [Int32]? = nil
      if bitsPerBlock <= 8 {
        palette = []
        let paletteLength = reader.readVarInt()
        for _ in 0..<paletteLength {
          palette!.append(reader.readVarInt())
        }
      }
      
      // reading data array:
      let dataArrayLength = reader.readVarInt()
      var dataArray: [Int64] = []
      for _ in 0..<dataArrayLength {
        dataArray.append(reader.readLong())
      }
      let ids = CompactedLongArray(dataArray, bitsPerEntry: bitsPerBlock, numEntries: 4096).decompact()
      var blockIds: [Int32] = []
      if palette != nil {
        for id in ids {
          blockIds.append(palette![Int(id)])
        }
      } else {
        blockIds = ids
      }
      let section = ChunkSection(blockIds: ids)
      chunkSections.append(section)
    }
    
    // Decoding block entities
    let numBlockEntities = reader.readVarInt()
    var blockEntities: [BlockEntity] = []
    for _ in 0..<numBlockEntities {
      let blockEntityNBT = try reader.readNBTTag()
      do {
        let x: Int32 = try blockEntityNBT.get("x")
        let y: Int32 = try blockEntityNBT.get("y")
        let z: Int32 = try blockEntityNBT.get("z")
        let position = BlockPosition(x: x, y: y, z: z)
        let identifierString: String = try! blockEntityNBT.get("id")
        let identifier = try! Identifier(identifierString)
        let blockEntity = BlockEntity(position: position, identifier: identifier, nbt: blockEntityNBT)
        blockEntities.append(blockEntity)
      } catch {
        print(error)
      }
    }
    
    let chunk = Chunk(position: position, heightMaps: heightMaps, sections: chunkSections, blockEntities: blockEntities, bitMask: primaryBitMask)
    return chunk
  }
}
