import Foundation

public enum NBTError: LocalizedError {
  case emptyList
  case invalidListType
  case invalidTagType
  case rootTagNotCompound
  case failedToGetList(String)
  case failedToGetTag(String)
  case failedToOpenURL
}

// all tags are assumed to be big endian and signed unless otherwise specified
// TODO: Clean up NBT decoder

extension NBT {
  /// An container for NBT tags. A bit like an object in JSON.
  public struct Compound: CustomStringConvertible {
    public var buffer: Buffer
    public var tags: [String: Tag] = [:]
    public var name: String = ""
    public var numBytes = -1
    public var isRoot: Bool
    
    public var description: String {
      return "\(tags)"
    }
    
    // MARK: Init
    
    public init(name: String = "", isRoot: Bool = false) {
      self.buffer = Buffer()
      self.isRoot = isRoot
      self.name = name
    }
    
    public init(fromBytes bytes: [UInt8], isRoot: Bool = true) throws {
      try self.init(fromBuffer: Buffer(bytes), isRoot: isRoot)
    }
    
    public init(fromBuffer buffer: Buffer, withName name: String = "", isRoot: Bool = true) throws {
      let initialBufferIndex = buffer.index
      
      self.buffer = buffer
      self.isRoot = isRoot
      self.name = name
      
      try unpack()
      
      if isRoot && !tags.isEmpty {
        let root: Compound = try get("")
        tags = root.tags
        self.name = root.name
      }
      
      let numBytesRead = self.buffer.index - initialBufferIndex
      numBytes = numBytesRead
    }
    
    public init(fromURL url: URL) throws {
      let data: Data
      do {
        data = try Data(contentsOf: url)
      } catch {
        throw NBTError.failedToOpenURL
      }
      let bytes = [UInt8](data)
      try self.init(fromBytes: bytes)
    }
    
    // MARK: Getters
    
    public func get<T>(_ key: String) throws -> T {
      guard let tag = tags[key]?.value as? T else {
        throw NBTError.failedToGetTag(key)
      }
      return tag
    }
    
    public func getList<T>(_ key: String) throws -> T {
      guard let nbtList = tags[key]!.value as? List else {
        throw NBTError.failedToGetList(key)
      }
      guard let list = nbtList.list as? T else {
        throw NBTError.failedToGetList(key)
      }
      return list
    }
    
    // MARK: Unpacking
    
    public mutating func unpack() throws {
      var n = 0
      while true {
        let typeId = try buffer.readByte()
        if let type = TagType(rawValue: typeId) {
          if type == .end {
            break
          }
          let nameLength = Int(try buffer.readShort(endianness: .big))
          let name = try buffer.readString(length: nameLength)
          
          tags[name] = try readTag(ofType: type, withId: n, andName: name)
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
    
    private mutating func readTag(ofType type: TagType, withId id: Int = 0, andName name: String = "") throws -> Tag {
      var value: Any?
      switch type {
        case .end:
          break
        case .byte:
          value = try buffer.readByte()
        case .short:
          value = try buffer.readSignedShort(endianness: .big)
        case .int:
          value = try buffer.readSignedInteger(endianness: .big)
        case .long:
          value = try buffer.readLong(endianness: .big)
        case .float:
          value = try buffer.readFloat(endianness: .big)
        case .double:
          value = try buffer.readDouble(endianness: .big)
        case .byteArray:
          let length = Int(try buffer.readSignedInteger(endianness: .big))
          value = try buffer.readSignedBytes(length)
        case .string:
          let length = Int(try buffer.readShort(endianness: .big))
          value = try buffer.readString(length: length)
        case .list:
          let typeId = try buffer.readByte()
          if let listType = TagType(rawValue: typeId) {
            let length = try buffer.readSignedInteger(endianness: .big)
            if length < 0 {
              throw NBTError.emptyList
            }
            
            var list = List(type: listType)
            if length != 0 {
              for _ in 0..<length {
                let elem = try readTag(ofType: listType)
                list.append(elem.value!)
              }
            }
            value = list
          } else {
            throw NBTError.invalidListType
          }
        case .compound:
          let compound = try Compound(fromBuffer: buffer, withName: name, isRoot: false)
          try buffer.skip(compound.numBytes)
          value = compound
        case .intArray:
          let count = try buffer.readSignedInteger(endianness: .big)
          var array: [Int] = []
          for _ in 0..<count {
            let integer = Int(try buffer.readSignedInteger(endianness: .big))
            array.append(integer)
          }
          value = array
        case .longArray:
          let count = try buffer.readSignedInteger(endianness: .big)
          var array: [Int] = []
          for _ in 0..<count {
            let long = Int(try buffer.readSignedLong(endianness: .big))
            array.append(long)
          }
          value = array
      }
      return Tag(id: id, name: name, type: type, value: value!)
    }
    
    // MARK: Packing
    
    public mutating func pack() -> [UInt8] {
      buffer = Buffer()
      let tags = self.tags.values
      
      if isRoot {
        buffer.writeByte(TagType.compound.rawValue)
        writeName(self.name)
      }
      for tag in tags {
        buffer.writeByte(tag.type.rawValue)
        writeName(tag.name!)
        writeTag(tag)
      }
      writeTag(Tag(id: 0, type: .end, value: nil))
      
      return buffer.bytes
    }
    
    private mutating func writeName(_ name: String) {
      buffer.writeShort(UInt16(name.utf8.count), endianness: .big)
      buffer.writeString(name)
    }
    
    // TODO: Remove force casts
    // swiftlint:disable force_cast
    private mutating func writeTag(_ tag: Tag) {
      switch tag.type {
        case .end:
          buffer.writeByte(0)
        case .byte:
          buffer.writeSignedByte(tag.value as! Int8)
        case .short:
          buffer.writeSignedShort(tag.value as! Int16, endianness: .big)
        case .int:
          buffer.writeSignedInt(tag.value as! Int32, endianness: .big)
        case .long:
          buffer.writeSignedLong(tag.value as! Int64, endianness: .big)
        case .float:
          buffer.writeFloat(tag.value as! Float, endianness: .big)
        case .double:
          buffer.writeDouble(tag.value as! Double, endianness: .big)
        case .byteArray:
          buffer.writeBytes(tag.value as! [UInt8])
        case .string:
          let string = tag.value as! String
          buffer.writeShort(UInt16(string.utf8.count), endianness: .big)
          buffer.writeString(string)
        case .list:
          let list = tag.value as! List
          let listType = list.type
          let listLength = list.count
          
          buffer.writeByte(listType.rawValue)
          buffer.writeSignedInt(Int32(listLength), endianness: .big)
          
          for elem in list.list {
            let value = Tag(id: 0, type: listType, value: elem)
            writeTag(value)
          }
        case .compound:
          var compound = tag.value as! Compound
          buffer.writeBytes(compound.pack())
        case .intArray:
          let array = tag.value as! [Int32]
          let length = Int32(array.count)
          buffer.writeSignedInt(length, endianness: .big)
          for int in array {
            buffer.writeSignedInt(int, endianness: .big)
          }
        case .longArray:
          let array = tag.value as! [Int64]
          let length = Int32(array.count)
          buffer.writeSignedInt(length, endianness: .big)
          for int in array {
            buffer.writeSignedLong(int, endianness: .big)
          }
      }
    }
    // swiftlint:enable force_cast
  }
}
