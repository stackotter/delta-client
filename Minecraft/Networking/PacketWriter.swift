//
//  PacketWriter.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 12/12/20.
//

import Foundation

// TODO: use Buffer for PacketWriter
struct PacketWriter {
  var packetId: Int
  var buf: [UInt8] = []
  
  init(packetId: Int) {
    self.packetId = packetId
    writeVarInt(Int32(packetId))
  }
  
  mutating func pack() -> [UInt8] {
    let temp = buf
    let length = buf.count
    buf = []
    writeVarInt(Int32(length))
    writeBytes(temp)
    return buf
  }
  
  mutating func writeBytes(_ bytes: [UInt8]) {
    buf.append(contentsOf: bytes)
  }
  
  mutating func writeByte(_ byte: UInt8) {
    buf.append(byte)
  }
  
  mutating func writeSignedByte(_ signedByte: Int8) {
    writeByte(UInt8(bitPattern: signedByte))
  }
  
  mutating func writeBitPattern(_ bitPattern: UInt64, numBytes: Int) {
    for i in 1...numBytes {
      let byte = UInt8((bitPattern >> ((numBytes - i) * 8)) & 0xff)
      writeByte(byte)
    }
  }
  
  mutating func writeBool(_ bool: Bool) {
    writeByte(bool ? 1 : 0)
  }
  
  mutating func writeShort(_ short: UInt16) {
    writeBitPattern(UInt64(short), numBytes: 2)
  }
  
  mutating func writeSignedShort(_ signedShort: Int16) {
    writeShort(UInt16(bitPattern: signedShort))
  }
  
  mutating func writeSignedInt(_ signedInt: Int32) {
    let bitPattern = UInt64(UInt32(bitPattern: signedInt))
    writeBitPattern(bitPattern, numBytes: 4)
  }
  
  mutating func writeSignedLong(_ signedLong: Int64) {
    let bitPattern = UInt64(bitPattern: signedLong)
    writeBitPattern(bitPattern, numBytes: 8)
  }
  
  mutating func writeFloat(_ float: Float) {
    let bitPattern = UInt64(float.bitPattern)
    writeBitPattern(bitPattern, numBytes: 4)
  }
  
  mutating func writeDouble(_ double: Double) {
    let bitPattern = double.bitPattern
    writeBitPattern(bitPattern, numBytes: 8)
  }
  
  mutating func writeVarInt(_ int: Int32) {
    var bitPattern = UInt32(bitPattern: int)
    repeat {
      var toWrite = bitPattern & 0x7f
      bitPattern >>= 7
      if (bitPattern != 0) {
        toWrite |= 0x80
      }
      writeByte(UInt8(toWrite))
    } while bitPattern != 0
  }
  
  mutating func writeString(_ string: String) {
    let bytes = [UInt8](string.utf8)
    let length = bytes.count
    precondition(length < 32767, "string too long to write")
    
    writeVarInt(Int32(length))
    writeBytes(bytes)
  }
  
  mutating func writeChat(_ chat: String) {
    writeString(chat)
  }
  
  mutating func writeIdentifier(_ identifier: String) {
    writeString(identifier)
  }
  
  // IMPLEMENT: Entity Metadata, Slot Data, NBT, Position, Angle, UUID, 
}
