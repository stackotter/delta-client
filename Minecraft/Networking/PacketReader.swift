//
//  PacketReader.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/12/20.
//

import Foundation

struct PacketReader {
  var buf: [UInt8]
  var length: Int
  
  var packetId: Int = -1
  var index: Int = 0
  
  var remaining: Int {
    get {
      return length - index
    }
  }
  
  init (bytes: [UInt8]) {
    self.buf = bytes
    self.length = self.buf.count
  }
  
  mutating func readByte() -> UInt8 {
    let byte = buf[index]
    index += 1
    return byte
  }
  
  // TODO: this function might be a little sus
  mutating func readBytes(n: Int) -> [UInt8] {
    let bytes = Array(buf[index..<(index+n)])
    index += n
    return bytes
  }
  
  mutating func readVarInt() -> Int {
    var int = 0
    var i = 0
    var byte: UInt8
    repeat {
      byte = readByte()
      int += Int(byte & 0x7f) << (i * 7)
      i += 1
    } while (byte & 0x80) == 0x80
    return int
  }
  
  mutating func readPacketId() -> Int {
    packetId = readVarInt()
    return packetId
  }
  
  mutating func readString() -> String {
    let length = readVarInt()
    let string = String(bytes: readBytes(n: length), encoding: .utf8)
    return string!
  }
  
  mutating func readJSON() -> JSON {
    let jsonString = readString()
    let json = JSON.fromString(jsonString)
    return json
  }
}
