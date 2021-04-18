//
//  Buffer.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 15/12/20.
//

import Foundation

struct Buffer {
  // all functions read unsigned unless otherwise specified
  var bytes: [UInt8]
  var index = 0
  
  var length: Int {
    get {
      return self.bytes.count
    }
  }
  
  var remaining: Int {
    get {
      return length - index
    }
  }
  
  // Init
  
  init() {
    self.bytes = []
  }
  
  init(_ bytes: [UInt8]) {
    self.bytes = bytes
  }
  
  // Read Functions
  
  mutating func skip(nBytes n: Int) {
    index += n
  }
  
  mutating func readBitPattern(n: Int, endian: Endian) -> UInt {
    var patternBytes = readBytes(n: n)
    if patternBytes.count < 8 {
      let padLength = 8 - patternBytes.count
      patternBytes = [UInt8](repeating: 0, count: padLength) + patternBytes
    }
    // using uint will cause problems on 32 bit platforms
    // apple only releases 64 bit now tho anyway
    var bitPattern: UInt = 0
    patternBytes.withUnsafeBytes {
      bitPattern = $0.load(as: UInt.self)
    }
    
    if endian == .big {
      return bitPattern.bigEndian
    }
    return bitPattern.littleEndian
  }
  
  mutating func readByte() -> UInt8 {
    let byte = bytes[index]
    index += 1
    return byte
  }
  
  mutating func readSignedByte() -> Int8 {
    let byte = Int8(bitPattern: readByte())
    return byte
  }
  
  mutating func readBytes(n: Int) -> [UInt8] {
    let byteArray = Array(bytes[index..<(index + n)])
    index += n
    return byteArray
  }
  
  mutating func readSignedBytes(n: Int) -> [Int8] {
    let unsignedBytes = readBytes(n: n)
    var signedBytes: [Int8] = []
    for i in 0..<unsignedBytes.count {
      signedBytes[i] = Int8(bitPattern: unsignedBytes[i])
    }
    return signedBytes
  }
  
  mutating func readRemainingBytes() -> [UInt8] {
    let remainingBytes = Array(bytes[index...])
    index = length
    return remainingBytes
  }
  
  mutating func readShort(endian: Endian) -> UInt16 {
    let short = UInt16(readBitPattern(n: 2, endian: endian))
    return short
  }
  
  mutating func readSignedShort(endian: Endian) -> Int16 {
    let signedShort = Int16(bitPattern: readShort(endian: endian))
    return signedShort
  }
  
  mutating func readInt(endian: Endian) -> UInt {
    let int = UInt32(readBitPattern(n: 4, endian: endian))
    return UInt(int)
  }
  
  mutating func readSignedInt(endian: Endian) -> Int {
    let signedInt = Int32(bitPattern: UInt32(readBitPattern(n: 4, endian: endian)))
    return Int(signedInt)
  }
  
  mutating func readLong(endian: Endian) -> UInt {
    let long = UInt(readBitPattern(n: 8, endian: endian))
    return long
  }
  
  mutating func readSignedLong(endian: Endian) -> Int {
    let signedLong = Int(bitPattern: readLong(endian: endian))
    return signedLong
  }
  
  mutating func readFloat(endian: Endian) -> Float {
    let float = Float(bitPattern: UInt32(readInt(endian: endian)))
    return float
  }
  
  mutating func readDouble(endian: Endian) -> Double {
    let double = Double(bitPattern: UInt64(readLong(endian: endian)))
    return double
  }
  
  mutating func readVarBitPattern(maxBytes: Int) -> UInt {
    var bitPattern: UInt = 0
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
      bitPattern += UInt(byte & 0x7f) << (i * 7)
      i += 1
    } while (byte & 0x80) == 0x80
    
    return bitPattern
  }
  
  mutating func readVarInt() -> Int {
    let bitPattern = UInt32(readVarBitPattern(maxBytes: 5))
    return Int(Int32(bitPattern: bitPattern))
  }
  
  mutating func readVarLong() -> Int {
    let bitPattern = readVarBitPattern(maxBytes: 10)
    return Int(bitPattern: bitPattern)
  }
  
  mutating func readString(length: Int) -> String {
    let stringBytes = readBytes(n: length)
    let string = String(bytes: stringBytes, encoding: .utf8)!
    return string
  }
  
  // Write Functions
  // these require specific int types for int and long still
  // as these functions aren't used much and it improves semantics
  
  mutating func writeByte(_ byte: UInt8) {
    bytes.append(byte)
  }
  
  mutating func writeSignedByte(_ signedByte: Int8) {
    writeByte(UInt8(bitPattern: signedByte))
  }
  
  mutating func writeBytes(_ byteArray: [UInt8]) {
    bytes.append(contentsOf: byteArray)
  }
  
  mutating func writeSignedBytes(_ signedBytes: [Int8]) {
    for signedByte in signedBytes {
      bytes.append(UInt8(bitPattern: signedByte))
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
      if bitPattern != 0 {
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
    let stringBytes = [UInt8](string.utf8)
    writeBytes(stringBytes)
  }
}
