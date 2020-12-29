//
//  NBTCompound.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 15/12/20.
//

import Foundation

// all tags are assumed to be big endian and signed unless otherwise specified
// TODO_LATER: clean up this spaghetti
struct NBTCompound {
  var buffer: Buffer
  var nbtTags: [String: NBTTag] = [:]
  var name: String = ""
  var numBytes = -1
  var isRoot: Bool
  
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
  
  typealias NBTTag = (type: NBTTagType, value: Any)
  
  init(fromBytes bytes: [UInt8], isRoot: Bool = true) {
    self.init(fromBuffer: Buffer(bytes), isRoot: isRoot)
  }
  
  init(fromBuffer buffer: Buffer, isRoot: Bool = true) {
    self.buffer = buffer
    self.isRoot = isRoot
    if self.isRoot {
      let typeId = self.buffer.readByte()
      if let type = NBTTagType.init(rawValue: typeId) {
        if type != .compound {
          fatalError("NBT root tag is not compound (root tag is always compound tag in java edition")
        }
        let nameLen = Int(self.buffer.readShort(endian: .big))
        self.name = self.buffer.readString(length: nameLen)
      } else {
        fatalError("invalid type id for root tag")
      }
    }
    self.unpack()
  }
  
  init(fromUrl url: URL) {
    let data: Data
    do {
      data = try Data(contentsOf: url)
    } catch {
      fatalError("couldn't open url to read nbt data")
    }
    let bytes = [UInt8](data)
    self.init(fromBytes: bytes)
  }
  
  // [ Getter Function ]
  
  func get<T>(_ key: String) -> T {
    return nbtTags[key]!.value as! T
  }
  
  // [ Read functions ]
  
  mutating func unpack() {
    let initialBufferIndex = buffer.index
    
    while true {
      let typeId = buffer.readByte()
      print(typeId)
      if let type = NBTTagType.init(rawValue: typeId) {
        if type == .end {
          break
        }
        let nameLength = Int(buffer.readShort(endian: .big))
        let name = buffer.readString(length: nameLength)
        
        nbtTags[name] = readTag(ofType: type, name: name)
      } else { // type not valid
        fatalError("invalid nbt type id: \(typeId)")
      }
      
      // the root tag should only contain one command
      if isRoot {
        break
      }
    }
    let numBytesRead = buffer.index - initialBufferIndex
    numBytes = numBytesRead
  }
  
  mutating func readTag(ofType type: NBTTagType, name: String = "") -> NBTTag {
    var value: Any?
    switch type {
      case .end:
        break
      case .byte:
        value = buffer.readByte()
      case .short:
        value = buffer.readSignedShort(endian: .big)
      case .int:
        value = buffer.readSignedInt(endian: .big)
      case .long:
        value = buffer.readLong(endian: .big)
      case .float:
        value = buffer.readFloat(endian: .big)
      case .double:
        value = buffer.readDouble(endian: .big)
      case .byteArray:
        let length = Int(buffer.readSignedInt(endian: .big))
        value = buffer.readSignedBytes(n: length)
      case .string:
        let length = Int(buffer.readShort(endian: .big))
        value = buffer.readString(length: length)
      case .list:
        let typeId = buffer.readByte()
        if let listType = NBTTagType.init(rawValue: typeId) {
          let length = buffer.readSignedInt(endian: .big)
          if length < 0 {
            // TODO: error handling
            fatalError("list of length less than 0 in nbt")
          }
          var list: [Any] = []
          if length != 0 {
            for _ in 1...length {
              list.append(readTag(ofType: listType).value)
            }
          }
          value = list
        } else {
          // TODO: error handling
          fatalError("invalid list type")
        }
      case .compound:
        let compound = NBTCompound(fromBuffer: buffer, isRoot: false)
        buffer.skip(nBytes: compound.numBytes)
        value = compound
      case .intArray:
        // TODO: implement NBT int array
        break
      case .longArray:
        // TODO: implement NBT long array
        break
    }
    return (type: type, value: value!)
  }
  
  // [ Write functions ]
  
  mutating func pack() -> [UInt8] {
    return []
  }
}
