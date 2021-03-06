//
//  Buffer.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 15/12/20.
//

import Foundation

struct Buffer {
  // all functions read unsigned unless otherwise specified
  var byteBuf: [UInt8]
  var index = 0
  
  var length: Int {
    get {
      return self.byteBuf.count
    }
  }
  
  var remaining: Int {
    get {
      return length - index
    }
  }
  
  enum Endian {
    case little
    case big
  }
  
  init() {
    self.byteBuf = []
  }
  
  init(_ bytes: [UInt8]) {
    self.byteBuf = bytes
  }
  
  // [ Read Functions ]
  
  mutating func skip(nBytes n: Int) {
    index += n
  }
  
  mutating func readBitPattern(n: Int, endian: Endian) -> UInt64 {
    var bytes = readBytes(n: n)
    if bytes.count < 8 {
      let padLength = 8 - bytes.count
      bytes = [UInt8](repeating: 0, count: padLength) + bytes
    }
    var bitPattern: UInt64 = 0
    bytes.withUnsafeBytes {
      bitPattern = $0.load(as: UInt64.self)
    }
    
    if endian == .big {
      return bitPattern.bigEndian
    }
    return bitPattern.littleEndian
  }
  
  mutating func readByte() -> UInt8 {
    let byte = byteBuf[index]
    index += 1
    return byte
  }
  
  mutating func readSignedByte() -> Int8 {
    let byte = Int8(bitPattern: readByte())
    return byte
  }
  
  mutating func readBytes(n: Int) -> [UInt8] {
    let bytes = Array(byteBuf[index..<index+n])
    index += n
    return bytes
  }
  
  mutating func readSignedBytes(n: Int) -> [Int8] {
    let bytes = readBytes(n: n)
    var signedBytes: [Int8] = []
    for i in 0..<bytes.count {
      signedBytes[i] = Int8(bitPattern: bytes[0])
    }
    return signedBytes
  }
  
  mutating func readShort(endian: Endian) -> UInt16 {
    let short = UInt16(readBitPattern(n: 2, endian: endian))
    return short
  }
  
  mutating func readSignedShort(endian: Endian) -> Int16 {
    let signedShort = Int16(bitPattern: readShort(endian: endian))
    return signedShort
  }
  
  mutating func readInt(endian: Endian) -> UInt32 {
    let int = UInt32(readBitPattern(n: 4, endian: endian))
    return int
  }
  
  mutating func readSignedInt(endian: Endian) -> Int32 {
    let signedInt = Int32(bitPattern: readInt(endian: endian))
    return signedInt
  }
  
  mutating func readLong(endian: Endian) -> UInt64 {
    let long = readBitPattern(n: 8, endian: endian)
    return long
  }
  
  mutating func readSignedLong(endian: Endian) -> Int64 {
    let signedLong = Int64(bitPattern: readLong(endian: endian))
    return signedLong
  }
  
  mutating func readFloat(endian: Endian) -> Float {
    let float = Float(bitPattern: readInt(endian: endian))
    return float
  }
  
  mutating func readDouble(endian: Endian) -> Double {
    let double = Double(bitPattern: readLong(endian: endian))
    return double
  }
  
  mutating func readVarBitPattern(maxBytes: Int) -> UInt64 {
    var bitPattern: UInt64 = 0
    var i = 0
    var byte: UInt8
    if maxBytes > 10 || maxBytes < 1 {
      fatalError("var num invalid value for maxBytes")
    }
    
    repeat {
      if i == maxBytes {
        fatalError("var num too long")
      }
      byte = readByte()
      bitPattern += UInt64(byte & 0x7f) << (i * 7)
      i += 1
    } while (byte & 0x80) == 0x80
    
    return bitPattern
  }
  
  mutating func readVarInt() -> Int32 {
    let bitPattern = UInt32(readVarBitPattern(maxBytes: 5))
    return Int32(bitPattern: bitPattern)
  }
  
  mutating func readVarLong() -> Int64 {
    let bitPattern = readVarBitPattern(maxBytes: 10)
    return Int64(bitPattern: bitPattern)
  }
  
  mutating func readString(length: Int) -> String {
    let bytes = readBytes(n: length)
    let string = String(bytes: bytes, encoding: .utf8)!
    return string
  }
  
  
  // [ Write Functions ]
  mutating func writeByte(_ byte: UInt8) {
    byteBuf.append(byte)
  }
  
  mutating func writeSignedByte(_ signedByte: Int8) {
    writeByte(UInt8(bitPattern: signedByte))
  }
  
  mutating func writeBytes(_ bytes: [UInt8]) {
    byteBuf.append(contentsOf: bytes)
  }
  
  mutating func writeSignedBytes(_ signedBytes: [Int8]) {
    for signedByte in signedBytes {
      byteBuf.append(UInt8(bitPattern: signedByte))
    }
  }
  
  mutating func writeBitPattern(_ bitPattern: UInt64, numBytes: Int, endian: Endian) {
    switch endian {
      case .big:
        for i in 1...numBytes {
          let byte = UInt8((bitPattern >> ((numBytes - i) * 8)) & 0xff)
          writeByte(byte)
        }
      case .little:
        for i in 1...numBytes {
          let byte = UInt8((bitPattern >> ((numBytes - (numBytes - i)) * 8)) & 0xff)
          writeByte(byte)
        }
    }
  }
  
  mutating func writeShort(_ short: UInt16, endian: Endian) {
    writeBitPattern(UInt64(short), numBytes: 2, endian: endian)
  }
  
  mutating func writeSignedShort(_ signedShort: Int16, endian: Endian) {
    writeShort(UInt16(bitPattern: signedShort), endian: endian)
  }
  
  mutating func writeInt(_ int: UInt32, endian: Endian) {
    writeBitPattern(UInt64(int), numBytes: 4, endian: endian)
  }
  
  mutating func writeSignedInt(_ signedInt: Int32, endian: Endian) {
    writeInt(UInt32(bitPattern: signedInt), endian: endian)
  }
  
  mutating func writeLong(_ long: UInt64, endian: Endian) {
    writeBitPattern(long, numBytes: 8, endian: endian)
  }
  
  mutating func writeSignedLong(_ signedLong: Int64, endian: Endian) {
    writeLong(UInt64(bitPattern: signedLong), endian: endian)
  }
  
  mutating func writeFloat(_ float: Float, endian: Endian) {
    writeBitPattern(UInt64(float.bitPattern), numBytes: 4, endian: endian)
  }
  
  mutating func writeDouble(_ double: Double, endian: Endian) {
    writeBitPattern(double.bitPattern, numBytes: 8, endian: endian)
  }
  
  mutating func writeVarBitPattern(_ varBitPattern: UInt64) {
    var bitPattern = varBitPattern
    repeat {
      var toWrite = bitPattern & 0x7f
      bitPattern >>= 7
      if (bitPattern != 0) {
        toWrite |= 0x80
      }
      writeByte(UInt8(toWrite))
    } while bitPattern != 0
  }
  
  mutating func writeVarInt(_ varInt: Int32) {
    let bitPattern = UInt32(bitPattern: varInt)
    writeVarBitPattern(UInt64(bitPattern))
  }
  
  mutating func writeVarLong(_ varLong: Int64) {
    let bitPattern = UInt64(bitPattern: varLong)
    writeVarBitPattern(bitPattern)
  }
  
  mutating func writeString(_ string: String) {
    let bytes = [UInt8](string.utf8)
    writeBytes(bytes)
  }
}

