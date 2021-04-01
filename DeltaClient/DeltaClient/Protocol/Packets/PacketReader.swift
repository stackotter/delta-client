//
//  PacketReader.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 13/12/20.
//

import Foundation
import os

struct PacketReader {
  var packetId: Int
  var buffer: Buffer
  var locale: MinecraftLocale
  
  enum PacketReaderError: LocalizedError {
    case invalidNBT
    case failedToReadSlotNBT
    case invalidJSON
    case invalidBooleanByte
    case invalidIdentifier
    case chatStringTooLong
    case identifierTooLong
  }
  
  var remaining: Int {
    get {
      return buffer.remaining
    }
  }
  
  // Init
  
  init(bytes: [UInt8]) {
    self.init(bytes: bytes, locale: MinecraftLocale())
  }
  
  init(bytes: [UInt8], locale: MinecraftLocale) {
    self.buffer = Buffer(bytes)
    self.packetId = buffer.readVarInt()
    self.locale = locale
  }
  
  init(buffer: Buffer) {
    self.init(buffer: buffer, locale: MinecraftLocale())
  }
  
  init(buffer: Buffer, locale: MinecraftLocale) {
    self.buffer = buffer
    self.locale = locale
    self.packetId = self.buffer.readVarInt()
  }
  
  // Basic datatypes
  
  mutating func readBool() -> Bool {
    let byte = buffer.readByte()
    let bool = byte == 1
    return bool
  }
  
  mutating func readByte() -> Int8 {
    return buffer.readSignedByte()
  }
  
  mutating func readUnsignedByte() -> UInt8 {
    return buffer.readByte()
  }
  
  mutating func readShort() -> Int16 {
    return buffer.readSignedShort(endian: .big)
  }
  
  mutating func readUnsignedShort() -> UInt16 {
    return buffer.readShort(endian: .big)
  }
  
  mutating func readInt() -> Int {
    return buffer.readSignedInt(endian: .big)
  }
  
  mutating func readLong() -> Int {
    return buffer.readSignedLong(endian: .big)
  }
  
  mutating func readFloat() -> Float {
    return buffer.readFloat(endian: .big)
  }
  
  mutating func readDouble() -> Double {
    return buffer.readDouble(endian: .big)
  }
  
  mutating func readString() -> String {
    let length = Int(buffer.readVarInt())
    let string = buffer.readString(length: length)
    return string
  }
  
  // TODO_LATER: make a Chat datatype to use instead of String
  mutating func readChat() -> ChatComponent {
    let string = readString()
    if string.count > 32767 {
      Logger.debug("chat string of length \(string.count) is longer than max of 32767")
    }
    do {
      let json = try JSON.fromString(string)
      let chat = ChatComponentUtil.parseJSON(json, locale: locale)
      return chat ?? ChatStringComponent(fromString: "failed to parse chat component")
    } catch {
      return ChatStringComponent(fromString: "invalid json in chat component")
    }
  }
  
  mutating func readIdentifier() throws -> Identifier {
    let string = readString()
    if string.count > 32767 {
      throw PacketReaderError.identifierTooLong
    }
    do {
      let identifier = try Identifier(string)
      return identifier
    } catch {
      throw PacketReaderError.invalidIdentifier
    }
  }
  
  mutating func readVarInt() -> Int {
    return buffer.readVarInt()
  }
  
  mutating func readVarLong() -> Int {
    return buffer.readVarLong()
  }
  
  mutating func readItemStack() throws -> ItemStack {
    let present = readBool()
    let itemStack: ItemStack
    switch present {
      case true:
        let itemId = Int(readVarInt())
        let itemCount = Int(readByte())
        do {
          let nbt = try readNBTTag()
          itemStack = ItemStack(itemId: itemId, itemCount: itemCount, nbt: nbt)
        } catch {
          throw PacketReaderError.failedToReadSlotNBT
        }
      case false:
        itemStack = ItemStack()
    }
    return itemStack
  }
  
  mutating func readNBTTag() throws -> NBTCompound {
    do {
      let compound = try NBTCompound(fromBuffer: buffer)
      buffer.skip(nBytes: compound.numBytes)
      return compound
    } catch {
      throw PacketReaderError.invalidNBT
    }
  }
  
  // TODO_LATER: figure out the best return type for readAngle
  mutating func readAngle() -> UInt8 {
    let angle = readUnsignedByte()
    return angle
  }
  
  mutating func readUUID() -> UUID {
    let bytes = buffer.readBytes(n: 16)
    var string = ""
    for byte in bytes {
      string += String(format: "%02X", byte)
    }
    return UUID.fromString(string)!
  }
  
  mutating func readByteArray(length: Int) -> [UInt8] {
    return buffer.readBytes(n: length)
  }
  
  mutating func readJSON() throws -> JSON {
    let jsonString = readString()
    guard let json = try? JSON.fromString(jsonString) else {
      throw PacketReaderError.invalidJSON
    }
    return json
  }
  
  mutating func readPosition() -> Position {
    let val = buffer.readLong(endian: .big)
    let x = Int(val >> 38)
    let y = Int(val & 0xfff)
    let z = Int((val << 26) >> 38)
    return Position(x: x, y: y, z: z)
  }
  
  mutating func readEntityRotation(pitchFirst: Bool = false) -> EntityRotation {
    var pitch: UInt8 = 0
    if pitchFirst {
      pitch = readAngle()
    }
    let yaw = readAngle()
    if !pitchFirst {
      pitch = readAngle()
    }
    return EntityRotation(pitch: pitch, yaw: yaw)
  }
  
  mutating func readEntityPosition() -> EntityPosition {
    let x = readDouble()
    let y = readDouble()
    let z = readDouble()
    return EntityPosition(x: x, y: y, z: z)
  }
  
  mutating func readEntityVelocity() -> EntityVelocity {
    let x = readShort()
    let y = readShort()
    let z = readShort()
    return EntityVelocity(x: x, y: y, z: z)
  }
  
  // TODO_LATER: implement readEntityMetadata
}
