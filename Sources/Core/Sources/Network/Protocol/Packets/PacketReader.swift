import Foundation

public enum PacketReaderError: LocalizedError {
  case invalidNBT
  case failedToReadSlotNBT
  case invalidJSON
  case invalidBooleanByte
  case invalidIdentifier
  case chatStringTooLong
  case identifierTooLong
  case invalidUUIDString
}

public struct PacketReader {
  public var packetId: Int
  public var buffer: Buffer
  public var locale: MinecraftLocale
  
  public var remaining: Int {
    get {
      return buffer.remaining
    }
  }
  
  // Init
  
  public init(bytes: [UInt8]) {
    self.init(bytes: bytes, locale: MinecraftLocale())
  }
  
  public init(bytes: [UInt8], locale: MinecraftLocale) {
    self.buffer = Buffer(bytes)
    self.packetId = buffer.readVarInt()
    self.locale = locale
  }
  
  public init(buffer: Buffer) {
    self.init(buffer: buffer, locale: MinecraftLocale())
  }
  
  public init(buffer: Buffer, locale: MinecraftLocale) {
    self.buffer = buffer
    self.locale = locale
    self.packetId = self.buffer.readVarInt()
  }
  
  // Basic datatypes
  
  public mutating func readBool() -> Bool {
    let byte = buffer.readByte()
    let bool = byte == 1
    return bool
  }
  
  public mutating func readByte() -> Int8 {
    return buffer.readSignedByte()
  }
  
  public mutating func readUnsignedByte() -> UInt8 {
    return buffer.readByte()
  }
  
  public mutating func readShort() -> Int16 {
    return buffer.readSignedShort(endian: .big)
  }
  
  public mutating func readUnsignedShort() -> UInt16 {
    return buffer.readShort(endian: .big)
  }
  
  public mutating func readInt() -> Int {
    return buffer.readSignedInt(endian: .big)
  }
  
  public mutating func readLong() -> Int {
    return buffer.readSignedLong(endian: .big)
  }
  
  public mutating func readFloat() -> Float {
    return buffer.readFloat(endian: .big)
  }
  
  public mutating func readDouble() -> Double {
    return buffer.readDouble(endian: .big)
  }
  
  public mutating func readString() throws -> String {
    let length = Int(buffer.readVarInt())
    let string = try buffer.readString(length: length)
    return string
  }
  
  public mutating func readVarInt() -> Int {
    return buffer.readVarInt()
  }
  
  public mutating func readVarLong() -> Int {
    return buffer.readVarLong()
  }
  
  // Complex datatypes
  
  public mutating func readChat() throws -> ChatComponent {
    let string = try readString()
    if string.count > 32767 {
      log.warning("chat string of length \(string.count) is longer than max of 32767")
    }
    do {
      let json = try JSON.fromString(string)
      let chat = try ChatComponentUtil.parseJSON(json, locale: locale)
      return chat
    } catch {
      return ChatStringComponent(fromString: "invalid json in chat component")
    }
  }
  
  public mutating func readIdentifier() throws -> Identifier {
    let string = try readString()
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
  
  public mutating func readItemStack() throws -> ItemStack {
    let present = readBool()
    let itemStack: ItemStack
    switch present {
      case true:
        let itemId = Int(readVarInt())
        let itemCount = Int(readByte())
        do {
          let nbt = try readNBTCompound()
          itemStack = ItemStack(itemId: itemId, itemCount: itemCount, nbt: nbt)
        } catch {
          throw PacketReaderError.failedToReadSlotNBT
        }
      case false:
        itemStack = ItemStack()
    }
    return itemStack
  }
  
  public mutating func readNBTCompound() throws -> NBT.Compound {
    do {
      let compound = try NBT.Compound(fromBuffer: buffer)
      buffer.skip(nBytes: compound.numBytes)
      return compound
    } catch {
      throw PacketReaderError.invalidNBT
    }
  }
  
  /// Reads an angle from the packet and returns it in radians.
  public mutating func readAngle() -> Float {
    let angle = readUnsignedByte()
    return Float(angle) / 128 * .pi
  }
  
  public mutating func readUUID() throws -> UUID {
    let bytes = buffer.readBytes(n: 16)
    var string = ""
    for byte in bytes {
      string += String(format: "%02X", byte)
    }
    guard let uuid = UUID.fromString(string) else {
      throw PacketReaderError.invalidUUIDString
    }
    return uuid
  }
  
  public mutating func readByteArray(length: Int) -> [UInt8] {
    return buffer.readBytes(n: length)
  }
  
  public mutating func readJSON() throws -> JSON {
    let jsonString = try readString()
    guard let json = try? JSON.fromString(jsonString) else {
      throw PacketReaderError.invalidJSON
    }
    return json
  }
  
  // reads x, y and z from a packed integer (each is signed)
  public mutating func readPosition() -> Position {
    let val = buffer.readLong(endian: .big)
    
    // extract the bit patterns (it goes x, then z, then y)
    var x = UInt32(val >> 38) // x is 26 bit
    var z = UInt32((val << 26) >> 38) // z is 26 bit
    var y = UInt32(val & 0xfff) // y is 12 bit
    
    // x and z are 26-bit signed integers, y is a 12-bit signed integer
    let xSignBit = (x & (1 << 25)) >> 25
    let ySignBit = (y & (1 << 11)) >> 11
    let zSignBit = (z & (1 << 25)) >> 25
    
    // convert to 32 bit signed bit patterns
    if xSignBit == 1 {
      x |= 0b111111 << 26
    }
    if ySignBit == 1 {
      y |= 0b11111111111111111111 << 12
    }
    if zSignBit == 1 {
      z |= 0b111111 << 26
    }
    
    // read and return the bit patterns
    return Position(
      x: Int(Int32(bitPattern: x)),
      y: Int(Int32(bitPattern: y)),
      z: Int(Int32(bitPattern: z))
    )
  }
  
  public mutating func readEntityRotation(pitchFirst: Bool = false) -> (pitch: Float, yaw: Float) {
    var pitch: Float = 0
    if pitchFirst {
      pitch = readAngle()
    }
    let yaw = readAngle()
    if !pitchFirst {
      pitch = readAngle()
    }
    return (pitch: pitch, yaw: yaw)
  }
  
  public mutating func readEntityPosition() -> SIMD3<Double> {
    let x = readDouble()
    let y = readDouble()
    let z = readDouble()
    return SIMD3<Double>(x, y, z)
  }
  
  public mutating func readEntityVelocity() -> SIMD3<Double> {
    let x = Double(readShort()) / 8000
    let y = Double(readShort()) / 8000
    let z = Double(readShort()) / 8000
    return SIMD3<Double>(x, y, z)
  }
}
