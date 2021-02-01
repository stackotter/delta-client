//
//  NBTCompound.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 15/12/20.
//

import Foundation

// all tags are assumed to be big endian and signed unless otherwise specified
// TODO_LATER: clean up this code
struct NBTCompound: CustomStringConvertible {
  var buffer: Buffer
  var nbtTags: [String: NBTTag] = [:]
  var name: String = ""
  var numBytes = -1
  var isRoot: Bool
  
  var description: String {
    return "\(nbtTags)"
  }
  
  struct NBTTag: CustomStringConvertible {
    var id: Int
    var name: String?
    var type: NBTTagType
    var value: Any?
    
    var description: String {
      if value != nil {
        if value is NBTCompound {
          return "\(value!)"
        }
        return "\"\(value!)\""
      } else {
        return "nil"
      }
    }
  }
  
  enum NBTError: LocalizedError {
    case emptyList
    case invalidListType
    case invalidTagType
    case rootTagNotCompound
    case failedToGetList
    case failedToGetTag
    case failedToOpenURL
  }
  
  // TODO_LATER: figure out how to not use Any
  struct NBTList: CustomStringConvertible {
    var type: NBTTagType
    var list: [Any] = []
    
    var description: String {
      return "\(list)"
    }
    
    var count: Int {
      get {
        return list.count
      }
    }
    
    mutating func append(_ elem: Any) {
      list.append(elem)
    }
  }
  
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
  
  // [ Initialisers ]
  
  init(name: String = "", isRoot: Bool = false) {
    self.buffer = Buffer()
    self.isRoot = isRoot
    self.name = name
  }
  
  init(fromBytes bytes: [UInt8], isRoot: Bool = true) throws {
    try self.init(fromBuffer: Buffer(bytes), isRoot: isRoot)
  }
  
  init(fromBuffer buffer: Buffer, withName name: String = "", isRoot: Bool = true) throws {
    let initialBufferIndex = buffer.index
    
    self.buffer = buffer
    self.isRoot = isRoot
    self.name = name
    
    try self.unpack()
    
    if self.isRoot && !self.nbtTags.isEmpty {
      let root: NBTCompound = try get("")
      self.nbtTags = root.nbtTags
      self.name = root.name
    }
    
    let numBytesRead = self.buffer.index - initialBufferIndex
    numBytes = numBytesRead
  }
  
  init(fromURL url: URL) throws {
    let data: Data
    do {
      data = try Data(contentsOf: url)
    } catch {
      throw NBTError.failedToOpenURL
    }
    let bytes = [UInt8](data)
    try self.init(fromBytes: bytes)
  }
  
  // [ Value Getter ]
  
  func get<T>(_ key: String) throws -> T {
    guard let tag = nbtTags[key]?.value as? T else {
      throw NBTError.failedToGetTag
    }
    return tag
  }
  
  func getList<T>(_ key: String) throws -> T {
    guard let nbtList = nbtTags[key]!.value as? NBTList else {
      throw NBTError.failedToGetList
    }
    guard let list = nbtList.list as? T else {
      throw NBTError.failedToGetList
    }
    return list
  }
  
  // [ Read functions ]
  
  mutating func unpack() throws {
    var n = 0
    while true {
      let typeId = buffer.readByte()
      if let type = NBTTagType.init(rawValue: typeId) {
        if type == .end {
          break
        }
        let nameLength = Int(buffer.readShort(endian: .big))
        let name = buffer.readString(length: nameLength)
        
        nbtTags[name] = try readTag(ofType: type, withId: n, andName: name)
      } else { // type not valid
        throw NBTError.invalidTagType
      }
      
      // the root tag should only contain one command
      if isRoot {
        break
      }
      n += 1
    }
  }
  
  mutating func readTag(ofType type: NBTTagType, withId id: Int = 0, andName name: String = "") throws -> NBTTag {
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
            throw NBTError.emptyList
          }
          
          var list = NBTList(type: listType)
          if length != 0 {
            for _ in 1...length {
              let elem = try readTag(ofType: listType)
              list.append(elem.value!)
            }
          }
          value = list
        } else {
          throw NBTError.invalidListType
        }
      case .compound:
        let compound = try NBTCompound(fromBuffer: buffer, withName: name, isRoot: false)
        buffer.skip(nBytes: compound.numBytes)
        value = compound
      case .intArray:
        let count = buffer.readSignedInt(endian: .big)
        var array: [Int32] = []
        for _ in 0..<count {
          let int = buffer.readSignedInt(endian: .big)
          array.append(int)
        }
        value = array
      case .longArray:
        let count = buffer.readSignedInt(endian: .big)
        var array: [Int64] = []
        for _ in 0..<count {
          let long = buffer.readSignedLong(endian: .big)
          array.append(long)
        }
        value = array
    }
    return NBTTag(id: id, name: name, type: type, value: value!)
  }
  
  // [ Write functions ]
  
  mutating func pack() -> [UInt8] {
    buffer = Buffer()
    let tags = nbtTags.values
    
    if isRoot {
      buffer.writeByte(NBTTagType.compound.rawValue)
      writeName(self.name)
    }
    for tag in tags {
      buffer.writeByte(tag.type.rawValue)
      writeName(tag.name!)
      writeTag(tag)
    }
    writeTag(NBTTag(id: 0, type: .end, value: nil))
    
    return buffer.byteBuf
  }
  
  mutating func writeName(_ name: String) {
    buffer.writeShort(UInt16(name.utf8.count), endian: .big)
    buffer.writeString(name)
  }
  
  mutating func writeTag(_ tag: NBTTag) {
    switch tag.type {
      case .end:
        buffer.writeByte(0)
      case .byte:
        buffer.writeSignedByte(tag.value as! Int8)
      case .short:
        buffer.writeSignedShort(tag.value as! Int16, endian: .big)
      case .int:
        buffer.writeSignedInt(tag.value as! Int32, endian: .big)
      case .long:
        buffer.writeSignedLong(tag.value as! Int64, endian: .big)
      case .float:
        buffer.writeFloat(tag.value as! Float, endian: .big)
      case .double:
        buffer.writeDouble(tag.value as! Double, endian: .big)
      case .byteArray:
        buffer.writeBytes(tag.value as! [UInt8])
      case .string:
        let string = tag.value as! String
        buffer.writeShort(UInt16(string.utf8.count), endian: .big)
        buffer.writeString(string)
      case .list:
        let list = tag.value as! NBTList
        let listType = list.type
        let listLength = list.count
        
        buffer.writeByte(listType.rawValue)
        buffer.writeSignedInt(Int32(listLength), endian: .big)
        
        for elem in list.list {
          let value = NBTTag(id: 0, type: listType, value: elem)
          writeTag(value)
        }
      case .compound:
        var compound = tag.value as! NBTCompound
        buffer.writeBytes(compound.pack())
      case .intArray:
        // TODO: implement NBT int array
        break
      case .longArray:
        // TODO: implement NBT long array
        break
    }
  }
}
