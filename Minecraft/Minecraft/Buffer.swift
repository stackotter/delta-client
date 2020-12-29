//
//  Buffer.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 15/12/20.
//

import Foundation

struct Buffer {
  // all functions read unsigned unless otherwise specified
  var buf: [UInt8]
  var length: Int
  var index = 0
  
  enum Endian {
    case little
    case big
  }
  
  var remaining: Int {
    get {
      return length - index
    }
  }
  
  init(_ bytes: [UInt8]) {
    self.buf = bytes
    self.length = self.buf.count
  }
  
  mutating func readByte() -> UInt8 {
    let byte = buf[index]
    index += 1
    return byte
  }
  
  mutating func readBytes(n: Int) -> [UInt8] {
    let bytes = Array(buf[index..<index+n])
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
  
  mutating func readString(length: Int) -> String {
    let bytes = readBytes(n: length)
    let string = String(bytes: bytes, encoding: .utf8)!
    return string
  }
  
  mutating func readBitPattern(n: Int, endian: Endian) -> UInt64{
    let bytes: [UInt8] = readBytes(n: n)
    var bitPattern: UInt64 = 0
    
    switch endian {
      case .big:
        for byte in bytes {
          bitPattern <<= 8
          bitPattern |= UInt64(byte)
        }
      case .little:
        for byte in bytes {
          bitPattern >>= 8
          bitPattern |= UInt64(byte) << ((n - 1)*8)
        }
    }
    
    return bitPattern
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
  
  
  // TODO: check if these two actually work
  mutating func readFloat(endian: Endian) -> Float {
    let float = Float(bitPattern: readInt(endian: endian))
    return float
  }
  
  mutating func readDouble(endian: Endian) -> Double {
    let double = Double(bitPattern: readLong(endian: endian))
    return double
  }
}

