//
//  NBTCompound.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 15/12/20.
//

import Foundation

// all tags are assumed to be big endian and signed unless otherwise specified
struct NBTCompound {
  var buffer: Buffer
  var nbtData: [String: Any] = [:]
  
  enum NBTTagType: UInt8 {
    case end = 0
    case byte = 1
    case short = 2
    case int = 3
    case long = 4
    case float = 5
    case double = 6
    case byteArray = 7
    case string = 8
    case list = 9
    case compound = 10
    case intArray = 11
    case longArray = 12
  }
  
  private init(name: String, buf: inout Buffer) {
    // typeId and tagName of compound already read
    self.buffer = buf
    self.unpack(buf: &buf)
  }
  
  static func fromBytes(_ bytes: [UInt8]) -> NBTCompound {
    var buf = Buffer(bytes)
    let typeId = buf.readByte()
    if let type = NBTTagType.init(rawValue: typeId) {
      if type != .compound {
        fatalError("NBT root tag is not compound (root tag is always compound tag in java edition")
      }
      let nameLen = Int(buf.readShort())
      let name = buf.readString(length: nameLen)
      return NBTCompound(name: name, buf: &buf)
    } else {
      fatalError("invalid type id for root tag")
    }
  }
  
  // TODO: think of better name for this function
  mutating func unpack(buf: inout Buffer) {
    while true {
      let typeId = buf.readByte()
      if let type = NBTTagType.init(rawValue: typeId) {
        if type == .end {
          break
        }
        let nameLength = Int(buf.readShort())
        let name = buf.readString(length: nameLength)
        
        nbtData[name] = readTag(ofType: type, buf: &buf, name: name)
      } else { // type not valid
        fatalError("invalid nbt type id: \(typeId)")
      }
    }
  }
  
  func readTag(ofType type: NBTTagType, buf: inout Buffer, name: String = "") -> Any {
    var value: Any?
    switch type {
      case .end:
        break
      case .byte:
        value = buf.readByte()
      case .short:
        value = buf.readSignedShort()
      case .int:
        value = buf.readSignedInt()
      case .long:
        value = buf.readLong()
      case .float:
        value = buf.readFloat()
      case .double:
        value = buf.readDouble()
      case .byteArray:
        let length = Int(buf.readSignedInt())
        value = buf.readSignedBytes(n: length)
      case .string:
        let length = Int(buf.readShort())
        value = buf.readString(length: length)
      case .list:
        let typeId = buf.readByte()
        if let listType = NBTTagType.init(rawValue: typeId) {
          let length = buf.readSignedInt()
          if length < 0 {
            // TODO: error handling
            fatalError("list of length less than 0 in nbt")
          }
          var list: [Any] = []
          if length != 0 {
            for _ in 1...length {
              list.append(readTag(ofType: listType, buf: &buf))
            }
          }
          value = list
        } else {
          // TODO: error handling
          fatalError("invalid list type")
        }
      case .compound:
        value = NBTCompound(name: name, buf: &buf).nbtData
      case .intArray:
        // TODO: implement
        print("")
      case .longArray:
        // TODO: implement
        print("")
    }
    return value!
  }
}
