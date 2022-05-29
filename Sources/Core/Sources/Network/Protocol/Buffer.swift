import Foundation

/// A byte buffer.
///
/// All methods read unsigned values unless otherwise specified in their name.
public struct Buffer {
  /// The buffer's underlying byte array.
  public private(set) var bytes: [UInt8]
  /// The current index of the read/write head.
  public var index = 0
  
  /// The buffer's current length.
  public var length: Int {
    return self.bytes.count
  }
  
  /// The number of bytes remaining in the buffer.
  public var remaining: Int {
    return length - index
  }
  
  // MARK: Init
  
  /// Creates an empty buffer.
  public init() {
    self.bytes = []
  }
  
  /// Creates a buffer with the given bytes.
  /// - Parameter bytes: The buffer's initial bytes.
  public init(_ bytes: [UInt8]) {
    self.bytes = bytes
  }

  // MARK: Reading

  /// Skips forward or backward over the specified number of bytes.
  /// - Parameter count: Number of bytes to skip (a negative number goes backwards).
  /// - Throws: ``BufferError/skippedOutOfBounds`` if the new index is out of bounds.
  public mutating func skip(_ count: Int) throws {
    index += count
    if remaining < 0 || index < 0 {
      throw BufferError.skippedOutOfBounds(length: length, index: index)
    }
  }

  /// Reads an unsigned integer with the specified number of bytes and the given endianness.
  /// - Parameters:
  ///   - size: The size of the integer in bytes (must be at most 8).
  ///   - endianness: The endianness of the integer.
  /// - Returns: The integer stored as a 64 bit unsigned integer.
  /// - Throws: ``BufferError/rangeOutOfBounds`` if the requested number of bytes can't be read.
  public mutating func readInteger(size: Int, endianness: Endianness) throws -> UInt64 {
    assert(size <= 8)

    var patternBytes = try readBytes(size)
    if patternBytes.count < 8 {
      let padLength = 8 - patternBytes.count
      patternBytes = [UInt8](repeating: 0, count: padLength) + patternBytes
    }

    var bitPattern: UInt64 = 0
    patternBytes.withUnsafeBytes {
      bitPattern = $0.load(as: UInt64.self)
    }
    
    switch endianness {
      case .big:
        return bitPattern.bigEndian
      case .little:
        return bitPattern.littleEndian
    }
  }
  
  /// Reads the byte at ``index``.
  /// - Returns: The byte.
  /// - Throws: ``BufferError/outOfBounds`` if ``remaining`` is not positive.
  public mutating func readByte() throws -> UInt8 {
    guard remaining > 0 else {
      throw BufferError.outOfBounds(length: length, index: index)
    }

    let byte = bytes[index]
    index += 1
    return byte
  }
  
  /// Reads the signed byte at ``index``.
  /// - Returns: The signed byte.
  /// - Throws: ``BufferError/outOfBounds`` if ``remaining`` is not positive.
  public mutating func readSignedByte() throws -> Int8 {
    let byte = Int8(bitPattern: try readByte())
    return byte
  }
  
  /// Reads a specified number of bytes (starting from ``index``).
  /// - Returns: The bytes.
  /// - Throws: ``BufferError/rangeOutOfBounds`` if the requested number of bytes can't be read.
  public mutating func readBytes(_ count: Int) throws -> [UInt8] {
    guard remaining >= count else {
      throw BufferError.rangeOutOfBounds(length: length, start: index, end: count + index)
    }

    let byteArray = Array(bytes[index..<(index + count)])
    index += count
    return byteArray
  }
  
  /// Reads a specified number of signed bytes (starting from ``index``).
  /// - Returns: The bytes.
  /// - Throws: ``BufferError/rangeOutOfBounds`` if the requested number of bytes can't be read.
  public mutating func readSignedBytes(_ count: Int) throws -> [Int8] {
    guard remaining >= count else {
      throw BufferError.rangeOutOfBounds(length: length, start: index, end: count + index)
    }

    let unsignedBytes = try readBytes(count)
    var signedBytes: [Int8] = []
    for i in 0..<unsignedBytes.count {
      signedBytes[i] = Int8(bitPattern: unsignedBytes[i])
    }
    return signedBytes
  }
  
  /// Reads all bytes remaining in the buffer.
  /// - Returns: The remaining bytes (empty if ``index`` is out of bounds).
  public mutating func readRemainingBytes() -> [UInt8] {
    let remainingBytes = (try? readBytes(remaining)) ?? []
    index = length
    return remainingBytes
  }
  
  /// Reads an unsigned short (2 byte integer).
  /// - Parameter endianness: The endianness of the integer.
  /// - Returns: The unsigned short.
  /// - Throws: ``BufferError/outOfBounds`` if ``index`` is out of bounds.
  public mutating func readShort(endianness: Endianness) throws -> UInt16 {
    return UInt16(try readInteger(size: 2, endianness: endianness))
  }
  
  /// Reads a signed short (2 byte integer).
  /// - Parameter endianness: The endianness of the integer.
  /// - Returns: The signed short.
  /// - Throws: ``BufferError/outOfBounds`` if ``index`` is out of bounds.
  public mutating func readSignedShort(endianness: Endianness) throws -> Int16 {
    return Int16(bitPattern: try readShort(endianness: endianness))
  }
  
  /// Reads an unsigned integer (4 bytes).
  /// - Parameter endianness: The endianness of the integer.
  /// - Returns: The unsigned integer.
  /// - Throws: ``BufferError/outOfBounds`` if ``index`` is out of bounds.
  public mutating func readInteger(endianness: Endianness) throws -> UInt32 {
    return UInt32(try readInteger(size: 4, endianness: endianness))
  }

  /// Reads a signed integer (4 bytes).
  /// - Parameter endianness: The endianness of the integer.
  /// - Returns: The signed integer.
  /// - Throws: ``BufferError/outOfBounds`` if ``index`` is out of bounds.
  public mutating func readSignedInteger(endianness: Endianness) throws -> Int32 {
    return Int32(bitPattern: try readInteger(endianness: endianness))
  }
  
  /// Reads an unsigned long (8 bytes).
  /// - Parameter endianness: The endianness of the integer.
  /// - Returns: The unsigned long.
  /// - Throws: ``BufferError/outOfBounds`` if ``index`` is out of bounds.
  public mutating func readLong(endianness: Endianness) throws -> UInt64 {
    return try readInteger(size: 8, endianness: endianness)
  }
  
  /// Reads a signed long (8 bytes).
  /// - Parameter endianness: The endianness of the integer.
  /// - Returns: The signed long.
  /// - Throws: ``BufferError/outOfBounds`` if ``index`` is out of bounds.
  public mutating func readSignedLong(endianness: Endianness) throws -> Int64 {
    return Int64(bitPattern: try readLong(endianness: endianness))
  }
  
  /// Reads a float (4 bytes).
  /// - Parameter endianness: The endianness of the float.
  /// - Returns: The float.
  /// - Throws: ``BufferError/outOfBounds`` if ``index`` is out of bounds.
  public mutating func readFloat(endianness: Endianness) throws -> Float {
    return Float(bitPattern: try readInteger(endianness: endianness))
  }
  
  /// Reads a double (4 bytes).
  /// - Parameter endianness: The endianness of the double.
  /// - Returns: The double.
  /// - Throws: ``BufferError/outOfBounds`` if ``index`` is out of bounds.
  public mutating func readDouble(endianness: Endianness) throws -> Double {
    return Double(bitPattern: try readLong(endianness: endianness))
  }
  
  /// Reads a variable length integer.
  /// - Parameter maximumSize: The maximum number of bytes that the integer should be.
  /// - Returns: The integer stored as a 64 bit integer.
  /// - Throws: ``BufferError/outOfBounds`` if ``index`` is out of bounds. ``BufferError/variableIntegerTooLarge`` if the integer is larger than `maximumSize`.
  public mutating func readVariableLengthInteger(maximumSize: Int) throws -> UInt64 {
    var count = 0
    var bitPattern: UInt64 = 0

    while true {
      guard count < maximumSize else {
        throw BufferError.variableIntegerTooLarge(maximum: maximumSize)
      }

      let byte = try readByte()
      bitPattern += UInt64(byte & 0x7f) << (count * 7)
      count += 1

      if byte & 0x80 == 0x80 {
        break
      }
    }

    return bitPattern
  }
  
  /// Reads a variable length integer (4 bytes, stored as up to 5 bytes).
  /// - Returns: The integer stored as a 64 bit integer.
  /// - Throws: ``BufferError/outOfBounds`` if ``index`` is out of bounds. ``BufferError/variableIntegerTooLarge`` if the integer is encoded as more than 5 bytes.
  public mutating func readVariableLengthInteger() throws -> Int32 {
    let bitPattern = UInt32(try readVariableLengthInteger(maximumSize: 5))
    return Int32(bitPattern: bitPattern)
  }
  
  /// Reads a variable length long (8 bytes, stored as up to 10 bytes).
  /// - Returns: The integer stored as a 64 bit integer.
  /// - Throws: ``BufferError/outOfBounds`` if ``index`` is out of bounds. ``BufferError/variableIntegerTooLarge`` if the long is encoded as more than 10 bytes.
  public mutating func readVariableLengthLong() throws -> Int64 {
    let bitPattern = try readVariableLengthInteger(maximumSize: 10)
    return Int64(bitPattern: bitPattern)
  }
  
  /// Reads a string.
  /// - Parameter length: The length of the string in bytes.
  /// - Returns: The string.
  /// - Throws: ``BufferError/outOfBounds`` if ``index`` is out of bounds. ``BufferError/invalidByteInUTF8String`` if the bytes cannot be converted to a strig.
  public mutating func readString(length: Int) throws -> String {
    let stringBytes = try readBytes(length)
    guard let string = String(bytes: stringBytes, encoding: .utf8) else {
      throw BufferError.invalidByteInUTF8String
    }
    return string
  }
  
  // MARK: Writing
  
  public mutating func writeByte(_ byte: UInt8) {
    bytes.append(byte)
  }
  
  public mutating func writeSignedByte(_ signedByte: Int8) {
    writeByte(UInt8(bitPattern: signedByte))
  }
  
  public mutating func writeBytes(_ byteArray: [UInt8]) {
    bytes.append(contentsOf: byteArray)
  }
  
  public mutating func writeSignedBytes(_ signedBytes: [Int8]) {
    for signedByte in signedBytes {
      bytes.append(UInt8(bitPattern: signedByte))
    }
  }
  
  public mutating func writeBitPattern(_ bitPattern: UInt64, numBytes: Int, endianness: Endianness) {
    switch endianness {
      case .big:
        for i in 1...numBytes {
          let byte = UInt8((bitPattern >> ((numBytes - i) * 8)) & 0xff)
          writeByte(byte)
        }
      case .little:
        for i in 1...numBytes {
          let byte = UInt8((bitPattern >> ((numBytes - (numBytes - i)) * 8)) & 0xff)
          writeByte(byte)
        }
    }
  }
  
  public mutating func writeShort(_ short: UInt16, endianness: Endianness) {
    writeBitPattern(UInt64(short), numBytes: 2, endianness: endianness)
  }
  
  public mutating func writeSignedShort(_ signedShort: Int16, endianness: Endianness) {
    writeShort(UInt16(bitPattern: signedShort), endianness: endianness)
  }
  
  public mutating func writeInt(_ int: UInt32, endianness: Endianness) {
    writeBitPattern(UInt64(int), numBytes: 4, endianness: endianness)
  }
  
  public mutating func writeSignedInt(_ signedInt: Int32, endianness: Endianness) {
    writeInt(UInt32(bitPattern: signedInt), endianness: endianness)
  }
  
  public mutating func writeLong(_ long: UInt64, endianness: Endianness) {
    writeBitPattern(long, numBytes: 8, endianness: endianness)
  }
  
  public mutating func writeSignedLong(_ signedLong: Int64, endianness: Endianness) {
    writeLong(UInt64(bitPattern: signedLong), endianness: endianness)
  }
  
  public mutating func writeFloat(_ float: Float, endianness: Endianness) {
    writeBitPattern(UInt64(float.bitPattern), numBytes: 4, endianness: endianness)
  }
  
  public mutating func writeDouble(_ double: Double, endianness: Endianness) {
    writeBitPattern(double.bitPattern, numBytes: 8, endianness: endianness)
  }
  
  public mutating func writeVarBitPattern(_ varBitPattern: UInt64) {
    var bitPattern = varBitPattern
    repeat {
      var toWrite = bitPattern & 0x7f
      bitPattern >>= 7
      if bitPattern != 0 {
        toWrite |= 0x80
      }
      writeByte(UInt8(toWrite))
    } while bitPattern != 0
  }
  
  public mutating func writeVarInt(_ varInt: Int32) {
    let bitPattern = UInt32(bitPattern: varInt)
    writeVarBitPattern(UInt64(bitPattern))
  }
  
  public mutating func writeVarLong(_ varLong: Int64) {
    let bitPattern = UInt64(bitPattern: varLong)
    writeVarBitPattern(bitPattern)
  }
  
  public mutating func writeString(_ string: String) {
    let stringBytes = [UInt8](string.utf8)
    writeBytes(stringBytes)
  }
}
