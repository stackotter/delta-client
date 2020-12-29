//
//  PacketReader.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/12/20.
//

import Foundation

struct PacketReader {
  var packetId: Int = -1
  var buf: Buffer
  
  // TODO: is this used anywhere?
  var remaining: Int {
    get {
      return buf.remaining
    }
  }
  
  init (bytes: [UInt8]) {
    self.buf = Buffer(bytes)
    self.packetId = Int(buf.readVarInt())
  }
  
  mutating func readBool() -> Bool {
    let byte = buf.readByte()
    if byte != 0 && byte != 1 {
      // TODO: start doing proper error handling
      fatalError("bool byte was not 1 or 0")
    }
    let bool = byte == 1
    return bool
  }
  
  mutating func readByte() -> Int8 {
    return buf.readSignedByte()
  }
  
  mutating func readUnsignedByte() -> UInt8 {
    return buf.readByte()
  }
  
  mutating func readShort() -> Int16 {
    return buf.readSignedShort(endian: .big)
  }
  
  mutating func readUnsignedShort() -> UInt16 {
    return buf.readShort(endian: .big)
  }
  
  mutating func readInt() -> Int32 {
    return buf.readSignedInt(endian: .big)
  }
  
  mutating func readLong() -> Int64 {
    return buf.readSignedLong(endian: .big)
  }
  
  mutating func readFloat() -> Float {
    return buf.readFloat(endian: .big)
  }
  
  mutating func readDouble() -> Double {
    return buf.readDouble(endian: .big)
  }
  
  mutating func readString() -> String {
    let length = Int(buf.readVarInt())
    let string = buf.readString(length: length)
    return string
  }
  
  // TODO_LATER: make a Chat datatype to use instead of String
  mutating func readChat() -> String {
    let string = readString()
    if string.count > 32767 {
      fatalError("chat string too large")
    }
    return string
  }
  
  // TODO_LATER: make an Identifier datatype to use instead of String
  mutating func readIdentifier() -> String {
    let string = readString()
    if string.count > 32767 {
      fatalError("identifier string too large")
    }
    return string
  }
  
  mutating func readVarInt() -> Int32 {
    return buf.readVarInt()
  }
  
  mutating func readVarLong() -> Int64 {
    return buf.readVarLong()
  }
  
  // TODO_LATER: implement readEntityMetadata
  
  mutating func readSlot() -> Slot {
    let present = readBool()
    let slot: Slot
    switch present {
      case true:
        let itemId = Int(readVarInt())
        let itemCount = Int(readByte())
        let nbt = readNBTTag()
        slot = Slot(present: present, itemId: itemId, itemCount: itemCount, nbt: nbt)
      case false:
        slot = Slot(present: present, itemId: nil, itemCount: nil, nbt: nil)
    }
    return slot
  }
  
  // in java edition nbt always contains a root compound
  mutating func readNBTTag() -> NBTCompound {
    let compound = NBTCompound(fromBuffer: buf)
    buf.skip(nBytes: compound.numBytes)
    return compound
  }
  
  // TODO_LATER: implement readPosition when have test data
  
  // TODO_LATER: figure out the best return type for readAngle
  mutating func readAngle() -> UInt8 {
    let angle = readUnsignedByte()
    return angle
  }
  
  mutating func readUUID() -> UUID {
    let bytes = buf.readBytes(n: 2)
    var string = ""
    for byte in bytes {
      string += String(format: "%016X", byte)
    }
    return UUID.fromString(string)!
  }
  
  mutating func readByteArray(length: Int) -> [UInt8] {
    return buf.readBytes(n: length)
  }
  
  mutating func readJSON() -> JSON {
    let jsonString = readString()
    let json = JSON.fromString(jsonString)
    return json
  }
}
