import FirebladeMath
import Foundation

/// A wrapper around ``Buffer`` that is specialized for reading Minecraft packets.
public struct PacketReader {
  /// The packet's id.
  public let packetId: Int
  /// The packet's bytes as a buffer.
  public var buffer: Buffer

  /// The number of bytes remaining in the packet's buffer.
  public var remaining: Int {
    return buffer.remaining
  }

  // MARK: Init

  /// Creates a new packet reader.
  ///
  /// Expects the start of the bytes to be a variable length integer encoding the packet's id.
  /// - Parameter bytes: The packet's bytes.
  /// - Throws: A ``BufferError`` if the packet's id cannot be read.
  public init(bytes: [UInt8]) throws {
    self.buffer = Buffer(bytes)
    self.packetId = Int(try buffer.readVariableLengthInteger())
  }

  /// Creates a new packet reader.
  ///
  /// Expects the start of the buffer to be a variable length integer encoding the packet's id.
  /// - Parameter bytes: The packet's bytes as a buffer. Reading starts from the buffer's current index.
  /// - Throws: A ``BufferError`` if the packet's id cannot be read.
  public init(buffer: Buffer) throws {
    self.buffer = buffer
    self.packetId = Int(try self.buffer.readVariableLengthInteger())
  }

  // MARK: Public methods

  /// Reads a boolean (1 byte).
  /// - Returns: A boolean.
  /// - Throws: A ``BufferError`` if out of bounds.
  public mutating func readBool() throws -> Bool {
    let byte = try buffer.readByte()
    let bool = byte == 1
    return bool
  }

  /// Optionally reads a value (assuming that the value's presence is indicated by a boolean
  /// field directly preceding it).
  public mutating func readOptional<T>(_ inner: (inout Self) throws -> T) throws -> T? {
    if try readBool() {
      return try inner(&self)
    } else {
      return nil
    }
  }

  /// Reads a direction (represented as a VarInt).
  public mutating func readDirection() throws -> Direction {
    let rawValue = try readVarInt()
    guard let direction = Direction(rawValue: rawValue) else {
      throw PacketReaderError.invalidDirection(rawValue)
    }
    return direction
  }

  /// Reads a signed byte.
  /// - Returns: A signed byte.
  /// - Throws: A ``BufferError`` if out of bounds.
  public mutating func readByte() throws -> Int8 {
    return try buffer.readSignedByte()
  }

  /// Reads an unsigned byte.
  /// - Returns: An unsigned byte.
  /// - Throws: A ``BufferError`` if out of bounds.
  public mutating func readUnsignedByte() throws -> UInt8 {
    return try buffer.readByte()
  }

  /// Reads a signed short (2 bytes).
  /// - Returns: A signed short.
  /// - Throws: A ``BufferError`` if out of bounds.
  public mutating func readShort() throws -> Int16 {
    return try buffer.readSignedShort(endianness: .big)
  }

  /// Reads an unsigned short (2 bytes).
  /// - Returns: An unsigned short.
  /// - Throws: A ``BufferError`` if out of bounds.
  public mutating func readUnsignedShort() throws -> UInt16 {
    return try buffer.readShort(endianness: .big)
  }

  /// Reads a signed integer (4 bytes).
  /// - Returns: A signed integer.
  /// - Throws: A ``BufferError`` if out of bounds.
  public mutating func readInt() throws -> Int {
    return Int(try buffer.readSignedInteger(endianness: .big))
  }

  /// Reads a signed long (8 bytes).
  /// - Returns: A signed long.
  /// - Throws: A ``BufferError`` if out of bounds.
  public mutating func readLong() throws -> Int {
    return Int(try buffer.readSignedLong(endianness: .big))
  }

  /// Reads a float (4 bytes).
  /// - Returns: A float.
  /// - Throws: A ``BufferError`` if out of bounds.
  public mutating func readFloat() throws -> Float {
    return try buffer.readFloat(endianness: .big)
  }

  /// Reads a double (8 bytes).
  /// - Returns: A double.
  /// - Throws: A ``BufferError`` if out of bounds.
  public mutating func readDouble() throws -> Double {
    return try buffer.readDouble(endianness: .big)
  }

  /// Reads a length prefixed string (length must be encoded as a variable length integer).
  /// - Returns: A string.
  /// - Throws: A ``BufferError`` if any reads go out of bounds. ``PacketReaderError/stringTooLong`` if the string is longer than 32767 (Minecraft's maximum string length).
  public mutating func readString() throws -> String {
    let length = Int(try buffer.readVariableLengthInteger())

    guard length <= 32767 else {
      throw PacketReaderError.stringTooLong(length: length)
    }

    let string = try buffer.readString(length: length)
    return string
  }

  /// Reads a variable length integer (4 bytes, encoded as up to 5 bytes).
  /// - Returns: A signed integer.
  /// - Throws: A ``BufferError`` if any reads go out of bounds or the integer is encoded as more than 5 bytes.
  public mutating func readVarInt() throws -> Int {
    return Int(try buffer.readVariableLengthInteger())
  }

  /// Reads a variable length long (8 bytes, encoded as up to 10 bytes).
  /// - Returns: A signed long.
  /// - Throws: A ``BufferError`` if any reads go out of bounds or the long is encoded as more than 10 bytes.
  public mutating func readVarLong() throws -> Int {
    return Int(try buffer.readVariableLengthLong())
  }

  /// Reads and parses a JSON-encoded chat component.
  /// - Returns: A chat component.
  /// - Throws: A ``BufferError`` if any reads go out of bounds. A ``ChatComponentError`` if the component is invalid.
  public mutating func readChat() throws -> ChatComponent {
    let string = try readString()
    do {
      let data = Data(string.utf8)
      let chat = try JSONDecoder().decode(ChatComponent.self, from: data)
      return chat
    } catch {
      log.warning("Failed to decode chat message: '\(string)' with error '\(error)'")

      // TODO: Remove fallback once all chat components are handled
      return ChatComponent(style: .init(), content: .string("<invalid chat message>"), children: [])
    }
  }

  /// Reads and parses an identifier (e.g. `minecraft:block/dirt`).
  /// - Returns: An identifier.
  /// - Throws: A ``BufferError`` if any reads go out of bounds. ``PacketReaderError/invalidIdentifier`` if the identifier is invalid.
  public mutating func readIdentifier() throws -> Identifier {
    let string = try readString()
    do {
      let identifier = try Identifier(string)
      return identifier
    } catch {
      throw PacketReaderError.invalidIdentifier(string)
    }
  }

  /// Reads an item stack.
  /// - Returns: An item stack, or `nil` if the item stack is not present (in-game).
  /// - Throws: A ``BufferError`` if any reads go out of bounds. ``PacketReaderError/invalidNBT`` if the slot has invalid NBT data.
  public mutating func readSlot() throws -> Slot {
    let isPresent = try readBool()
    if isPresent {
      let itemId = try readVarInt()
      let itemCount = Int(try readByte())
      let nbt = try readNBTCompound()
      return Slot(ItemStack(itemId: itemId, itemCount: itemCount, nbt: nbt))
    } else {
      return Slot()
    }
  }

  /// Reads an NBT compound.
  /// - Returns: An NBT compound.
  /// - Throws: A ``BufferError`` if any reads go out of bounds. ``PacketReaderError/invalidNBT`` if the NBT is invalid.
  public mutating func readNBTCompound() throws -> NBT.Compound {
    do {
      let compound = try NBT.Compound(fromBuffer: buffer)
      try buffer.skip(compound.numBytes)
      return compound
    } catch {
      throw PacketReaderError.invalidNBT(error)
    }
  }

  /// Reads an angle (1 byte) and returns it as radians.
  /// - Returns: An angle in radians.
  /// - Throws: A ``BufferError`` if any reads go out of bounds.
  public mutating func readAngle() throws -> Float {
    let angle = try readUnsignedByte()
    return Float(angle) / 128 * .pi
  }

  /// Reads a UUID (16 bytes).
  /// - Returns: A UUID.
  /// - Throws: A ``BufferError`` if any reads go out of bounds.
  public mutating func readUUID() throws -> UUID {
    var bytes = try buffer.readBytes(16)
    let uuid = Data(bytes: &bytes, count: bytes.count).withUnsafeBytes { pointer in
      pointer.load(as: UUID.self)
    }
    return uuid
  }

  /// Reads a byte array.
  /// - Parameter length: The length of byte array to read.
  /// - Returns: A byte array.
  /// - Throws: A ``BufferError`` if any reads go out of bounds.
  public mutating func readByteArray(length: Int) throws -> [UInt8] {
    return try buffer.readBytes(length)
  }

  /// Reads a packed block position (8 bytes).
  ///
  /// The x and z coordinates take up 26 bits each and the y coordinate takes up 12 bits.
  /// - Returns: A block position.
  /// - Throws: A ``BufferError`` if any reads go out of bounds.
  public mutating func readBlockPosition() throws -> BlockPosition {
    let val = try buffer.readLong(endianness: .big)

    // Extract the bit patterns (in the order x, then z, then y)
    var x = UInt32(val >> 38)  // x is 26 bit
    var z = UInt32((val << 26) >> 38)  // z is 26 bit
    var y = UInt32(val & 0xfff)  // y is 12 bit

    // x and z are 26-bit signed integers, y is a 12-bit signed integer
    let xSignBit = (x & (1 << 25)) >> 25
    let ySignBit = (y & (1 << 11)) >> 11
    let zSignBit = (z & (1 << 25)) >> 25

    // Convert to 32 bit signed bit patterns
    if xSignBit == 1 {
      x |= 0b111111 << 26
    }
    if ySignBit == 1 {
      y |= 0b1111_11111111_11111111 << 12
    }
    if zSignBit == 1 {
      z |= 0b111111 << 26
    }

    return BlockPosition(
      x: Int(Int32(bitPattern: x)),
      y: Int(Int32(bitPattern: y)),
      z: Int(Int32(bitPattern: z))
    )
  }

  /// Reads an entity rotation (2 bytes) and returns it in radians.
  ///
  /// Expects yaw to be before pitch unless `pitchFirst` is `true`. Every packet except one has yaw first, thanks Mojang.
  /// - Parameter pitchFirst: If `true`, pitch is read before yaw.
  /// - Returns: An entity rotation in radians.
  /// - Throws: A ``BufferError`` if any reads go out of bounds.
  public mutating func readEntityRotation(pitchFirst: Bool = false) throws -> (
    pitch: Float, yaw: Float
  ) {
    var pitch: Float = 0
    if pitchFirst {
      pitch = try readAngle()
    }
    let yaw = try readAngle()
    if !pitchFirst {
      pitch = try readAngle()
    }
    return (pitch: pitch, yaw: yaw)
  }

  /// Reads an entity position (24 bytes).
  /// - Returns: An entity position.
  /// - Throws: A ``BufferError`` if any reads go out of bounds.
  public mutating func readEntityPosition() throws -> Vec3d {
    let x = try readDouble()
    let y = try readDouble()
    let z = try readDouble()
    return Vec3d(x, y, z)
  }

  /// Reads an entity velocity (6 bytes).
  /// - Returns: An entity velocity.
  /// - Throws: A ``BufferError`` if any reads go out of bounds.
  public mutating func readEntityVelocity() throws -> Vec3d {
    let x = try Double(readShort()) / 8000
    let y = try Double(readShort()) / 8000
    let z = try Double(readShort()) / 8000
    return Vec3d(x, y, z)
  }
}
