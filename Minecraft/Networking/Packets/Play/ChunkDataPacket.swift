//
//  ChunkData.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/1/21.
//

import Foundation

struct ChunkDataPacket: Packet {
  typealias PacketType = ChunkDataPacket
  var id: Int = 0x20
  
  var chunk: Chunk
  
  static func from(_ packetReader: PacketReader) throws -> ChunkDataPacket? {
    let start = CFAbsoluteTimeGetCurrent()
    var mutableReader = packetReader
    let chunkX = mutableReader.readInt()
    let chunkZ = mutableReader.readInt()
    let fullChunk = mutableReader.readBool()
    let primaryBitMask = mutableReader.readVarInt()
    _ = try mutableReader.readNBTTag() // height map, dunno what it's used for yet
    if fullChunk {
      // TODO: parse biome data
      let biomesLength = mutableReader.readVarInt()
      for _ in 0..<biomesLength {
        let biome = mutableReader.readVarInt()
        _ = biome
      }
    }
    _ = Int(mutableReader.readVarInt()) // this reads the data size, it's not necessary to use it to read the data though

    var chunkSections: [ChunkSection] = []
    var numSections = 0
    for i in 0..<16 {
      numSections += Int(primaryBitMask >> i) & 0x01
    }
    for _ in 0..<numSections {
      // read chunk section:
      let blockCount = mutableReader.readShort() // used for lighting purposes apparently
      _ = blockCount
      var bitsPerBlock = Int(mutableReader.readByte())

      if bitsPerBlock < 4 {
        bitsPerBlock = 4
      }

      // reading palette:
      var palette: [Int32]? = nil
      if bitsPerBlock <= 8 {
        palette = []
        let paletteLength = mutableReader.readVarInt()
        for _ in 0..<paletteLength {
          palette!.append(mutableReader.readVarInt())
        }
      }

      // reading data array:
      let dataArrayLength = mutableReader.readVarInt()
      var dataArray: [Int64] = []
      for _ in 0..<dataArrayLength {
        dataArray.append(mutableReader.readLong())
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
    let numBlockEntities = mutableReader.readVarInt()
    var blockEntities: [BlockEntity] = []
    for _ in 0..<numBlockEntities {
      let blockEntityNBT = try mutableReader.readNBTTag()
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
    let elapsed = CFAbsoluteTimeGetCurrent() - start
    print("chunked parsed in \(elapsed) seconds")
    let chunk = Chunk(chunkX: chunkX, chunkZ: chunkZ, sections: chunkSections, blockEntities: blockEntities, bitMask: primaryBitMask)
    return ChunkDataPacket(chunk: chunk)
  }
}
