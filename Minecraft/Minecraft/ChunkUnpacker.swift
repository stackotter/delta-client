//
//  ChunkUnpacker.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 27/2/21.
//

import Foundation
import os

struct ChunkUnpacker {
  var start: CFAbsoluteTime = 0
  var lastLog: CFAbsoluteTime = 0
  
  init() {}
  
  mutating func unpack(_ bytes: [UInt8]) {
    do {
      start = CFAbsoluteTimeGetCurrent()
      lastLog = CFAbsoluteTimeGetCurrent()
      Logger.log("-- BEGIN UNPACK --")
      
      var packetReader = PacketReader(bytes: bytes, locale: MinecraftLocale.empty())
      logTimestamp(with: "loaded packet reader")
      
      let chunkX = packetReader.readInt()
      let chunkZ = packetReader.readInt()
      
      let fullChunk = packetReader.readBool()
      let ignoreOldData = packetReader.readBool()
      let primaryBitMask = packetReader.readVarInt()
      logTimestamp(with: "read base")
      
      let heightMaps = try packetReader.readNBTTag()
      logTimestamp(with: "read heightmaps (nbt)")
      
      if fullChunk {
        // HACK: this could cause issues down the line because it assumes no biome id is greater than 256
        var biomes = packetReader.readByteArray(length: 1024*4) // every fourth byte is a biome id (biome ids are stored as big endian ints but are actually never bigger than an int
        logTimestamp(with: "read biomes")
      }
      
      let _ = packetReader.readVarInt() // data length
      var numSections = 0
      for i in 0..<32 {
        numSections += Int((primaryBitMask >> i) & 0x1)
      }
      unpackChunkData(&packetReader, numSections: numSections)
      
      resetTimer()
      let numBlockEntities = packetReader.readVarInt()
      var blockEntities: [NBTCompound] = []
      for _ in 0..<numBlockEntities {
        let blockEntity = try packetReader.readNBTTag()
        blockEntities.append(blockEntity)
      }
      logTimestamp(with: "read \(numBlockEntities) block entities")
      
      Logger.log("-- END UNPACK --")
      Logger.log(String(format: "unpack completed in %.2fms", (CFAbsoluteTimeGetCurrent() - start)*1000))
    } catch {
      logTimestamp(with: "\(error)")
      Logger.log("-- FAILED UNPACK --")
    }
  }
  
  mutating func resetTimer() {
    lastLog = CFAbsoluteTimeGetCurrent()
  }
  
  mutating func logTimestamp(with message: String) {
    let current = CFAbsoluteTimeGetCurrent()
    let elapsed = current - lastLog
    lastLog = current
    Logger.log(message + String(format: ": took %.5fms", elapsed*1000))
  }
  
  mutating func unpackChunkData(_ packetReader: inout PacketReader, numSections: Int) {
    Logger.log("")
    Logger.log("start chunk data unpack")
    for i in 0..<numSections {
      Logger.log("unpacking section \(i+1)/\(numSections)")
      let blockCount = packetReader.readShort()
      let bitsPerBlock = packetReader.readUnsignedByte()
      
      var palette: [Int32] = []
      if bitsPerBlock <= 8 {
        Logger.log("using indirect palette")
        resetTimer()
        let paletteLength = packetReader.readVarInt()
        for _ in 0..<paletteLength {
          palette.append(packetReader.readVarInt())
        }
        logTimestamp(with: "read indirect palette of length \(paletteLength)")
      } else {
        Logger.log("using direct palette")
      }
      
      let dataArrayLength = packetReader.readVarInt()
      var dataArray: [Int64] = []
      for _ in 0..<dataArrayLength {
        dataArray.append(packetReader.readLong())
      }
      logTimestamp(with: "read long array")
      
      Logger.log("uncompacting long array")
      let blocks = CompactedLongArray(dataArray, bitsPerEntry: Int(bitsPerBlock), numEntries: 4096).decompact()
      logTimestamp(with: "uncompacted long array")
      
      Logger.log("")
    }
  }
}
