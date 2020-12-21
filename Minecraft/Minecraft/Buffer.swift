//
//  Buffer.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 15/12/20.
//

import Foundation

struct Buffer {
  // all functions read big endian and unsigned unless otherwise specified
  var buf: [UInt8]
  var index = 0
  
  init(_ bytes: [UInt8]) {
    self.buf = bytes
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
  
  mutating func readBitPattern(n: Int) -> UInt64{
    let bytes: [UInt8] = readBytes(n: n)
    var bitPattern: UInt64 = 0
    for byte in bytes {
      bitPattern <<= 8
      bitPattern |= UInt64(byte)
    }
    return bitPattern
  }
  
  mutating func readShort() -> UInt16 {
    let short = UInt16(readBitPattern(n: 2))
    return short
  }
  
  mutating func readSignedShort() -> Int16 {
    let signedShort = Int16(bitPattern: readShort())
    return signedShort
  }
  
  mutating func readInt() -> UInt32 {
    let int = UInt32(readBitPattern(n: 4))
    return int
  }
  
  mutating func readSignedInt() -> Int32 {
    let signedInt = Int32(bitPattern: readInt())
    return signedInt
  }
  
  mutating func readLong() -> UInt64 {
    let long = readBitPattern(n: 8)
    return long
  }
  
  mutating func readSignedLong() -> Int64 {
    let signedLong = Int64(bitPattern: readLong())
    return signedLong
  }
  
  
  // TODO: check if these two actually work
  mutating func readFloat() -> Float {
    let float = Float(bitPattern: readInt())
    return float
  }
  
  mutating func readDouble() -> Double {
    let double = Double(bitPattern: readLong())
    return double
  }
}
