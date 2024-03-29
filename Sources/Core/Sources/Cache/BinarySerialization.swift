import Foundation

/// An error thrown during serialization implemented via ``BinarySerializable``.
public enum BinarySerializationError: LocalizedError {
  case invalidSerializationFormatVersion(Int, expectedVersion: Int)
  case invalidCaseId(Int, type: String)

  public var errorDescription: String? {
    switch self {
      case .invalidSerializationFormatVersion(let version, expectedVersion: let expectedVersion):
        return """
        Invalid serialization format version.
        Expected: \(expectedVersion)
        Received: \(version)
        """
      case .invalidCaseId(let id, let type):
        return """
        Invalid enum case id.
        Id: \(id)
        Enum: \(type)
        """
    }
  }
}

/// An error thrown during deserialization implemented via ``BinarySerializable``.
public enum DeserializationError: LocalizedError {
  case invalidRawValue

  public var errorDescription: String? {
    switch self {
      case .invalidRawValue:
        return "Encountered an invalid raw value while deserializing a RawRepresentable value."
    }
  }
}

/// A conforming type is able to be serialized and deserialized using Delta Client's custom binary
/// caching mechanism.
public protocol BinarySerializable {
  /// Serializes the value into a byte buffer.
  func serialize(into buffer: inout Buffer)
  /// Deserializes a value from a byte buffer.
  static func deserialize(from buffer: inout Buffer) throws -> Self
}

public extension BinarySerializable {
  /// Serializes the value into a byte buffer.
  func serialize() -> Buffer {
    var buffer = Buffer()
    serialize(into: &buffer)
    return buffer
  }

  /// Deserializes a value from a byte buffer.
  static func deserialize(from buffer: Buffer) throws -> Self {
    var buffer = buffer
    return try deserialize(from: &buffer)
  }
}

/// A conforming type is intended to be the root type of a binary cache and includes a validated
/// format version that should be bumped after each change that would effect the format of the cache.
public protocol RootBinarySerializable: BinarySerializable {
  static var serializationFormatVersion: Int { get }
}

public extension RootBinarySerializable {
  /// Serializes the value into a byte buffer prefixed by its format version.
  func serialize() -> Buffer {
    var buffer = Buffer()
    Self.serializationFormatVersion.serialize(into: &buffer)
    serialize(into: &buffer)
    return buffer
  }

  /// Deserializes a value from a byte buffer and verifies that it has the correct format version
  /// before continuing.
  static func deserialize(from buffer: Buffer) throws -> Self {
    var buffer = buffer
    let incomingVersion = try Int.deserialize(from: &buffer)
    guard incomingVersion == serializationFormatVersion else {
      throw BinarySerializationError.invalidSerializationFormatVersion(incomingVersion, expectedVersion: serializationFormatVersion)
    }
    return try deserialize(from: &buffer)
  }

  /// Serializes this value into a file.
  func serialize(toFile file: URL) throws {
    let buffer = serialize()
    try Data(buffer.bytes).write(to: file)
  }

  /// Deserializes a value from a file.
  static func deserialize(fromFile file: URL) throws -> Self {
    let data = try Data(contentsOf: file)
    return try deserialize(from: Buffer([UInt8](data)))
  }
}

/// A bitwise copyable type is one that is a value type that takes up contiguous memory with no
/// indirection (i.e. doesn't include properties that are arrays, strings, etc.). For your safety, a
/// runtime check is performed that ensures that conforming types are actually bitwise copyable
/// types (a.k.a. a plain ol' datatypes, see [_isPOD](https://github.com/apple/swift/blob/5a7b8c7922348179cc6dbc7281108e59d94ccecb/stdlib/public/core/Builtin.swift#L709))
///
/// The ``BinarySerializable`` implementation provided by conforming to this marker protocol essentially
/// just copies the raw bytes of a type into the output for serialization, and reverses the process
/// extremely efficiently when deserializing using unsafe pointers. Bitwise copyable types are the
/// fastest types to serialize and deserialize.
public protocol BitwiseCopyable: BinarySerializable {}

public extension BitwiseCopyable {
  @inline(__always)
  func serialize(into buffer: inout Buffer) {
    precondition(_isPOD(Self.self), "\(type(of: self)) must be a bitwise copyable datatype to conform to BitwiseCopyable")
    var value = self
    withUnsafeBytes(of: &value) { bufferPointer in
      let pointer = bufferPointer.assumingMemoryBound(to: UInt8.self).baseAddress!
      for i in 0..<MemoryLayout<Self>.size {
        buffer.writeByte(pointer.advanced(by: i).pointee)
      }

      if MemoryLayout<Self>.size == MemoryLayout<Self>.stride {
        return
      }

      // Padding with zeroes is required to avoid segfaults that would occur if the last type
      // serialized into a buffer was a type that had mismatching size and stride and the length of
      // the buffer happened to be aligned with the end of a page. Using a for loop seems to be the
      // fastest way to do this with Swift's array API. There would definitely be faster ways in C.
      for _ in MemoryLayout<Self>.size..<MemoryLayout<Self>.stride {
        buffer.writeByte(0)
      }
    }
  }

  @inline(__always)
  static func deserialize(from buffer: inout Buffer) throws -> Self {
    precondition(_isPOD(Self.self), "\(type(of: self)) must be a bitwise copyable datatype to conform to BitwiseCopyable")
    let index = buffer.index
    buffer.index += MemoryLayout<Self>.stride
    return buffer.bytes.withUnsafeBytes { pointer in
      return pointer.loadUnaligned(fromByteOffset: index, as: Self.self)
    }
  }
}

extension Bool: BitwiseCopyable {}

extension Int: BitwiseCopyable {}
extension UInt: BitwiseCopyable {}
extension Int64: BitwiseCopyable {}
extension UInt64: BitwiseCopyable {}
extension Int32: BitwiseCopyable {}
extension UInt32: BitwiseCopyable {}
extension Int16: BitwiseCopyable {}
extension UInt16: BitwiseCopyable {}
extension Int8: BitwiseCopyable {}
extension UInt8: BitwiseCopyable {}

extension Float: BitwiseCopyable {}
extension Double: BitwiseCopyable {}

extension Matrix2x2: BitwiseCopyable, BinarySerializable {}
extension Matrix3x3: BitwiseCopyable, BinarySerializable {}
extension Matrix4x4: BitwiseCopyable, BinarySerializable {}

extension SIMD2: BitwiseCopyable, BinarySerializable {}
extension SIMD3: BitwiseCopyable, BinarySerializable {}
extension SIMD4: BitwiseCopyable, BinarySerializable {}
extension SIMD8: BitwiseCopyable, BinarySerializable {}
extension SIMD16: BitwiseCopyable, BinarySerializable {}
extension SIMD32: BitwiseCopyable, BinarySerializable {}
extension SIMD64: BitwiseCopyable, BinarySerializable {}

extension String: BinarySerializable {
  public func serialize(into buffer: inout Buffer) {
    count.serialize(into: &buffer)
    buffer.writeString(self)
  }

  public static func deserialize(from buffer: inout Buffer) throws -> Self {
    let count = try Int.deserialize(from: &buffer)
    return try buffer.readString(length: count)
  }
}

extension Character: BinarySerializable {
  public func serialize(into buffer: inout Buffer) {
    self.utf8.count.serialize(into: &buffer)
    buffer.writeBytes([UInt8](self.utf8))
  }

  public static func deserialize(from buffer: inout Buffer) throws -> Self {
    let count = try Int.deserialize(from: &buffer)
    let bytes = try buffer.readBytes(count)
    guard let string = String(bytes: bytes, encoding: .utf8) else {
      throw BufferError.invalidByteInUTF8String
    }
    return Character(string)
  }
}

public extension BinarySerializable where Self: RawRepresentable, RawValue: BinarySerializable {
  func serialize(into buffer: inout Buffer) {
    rawValue.serialize(into: &buffer)
  }

  static func deserialize(from buffer: inout Buffer) throws -> Self {
    guard let value = Self(rawValue: try .deserialize(from: &buffer)) else {
      throw DeserializationError.invalidRawValue
    }

    return value
  }
}

extension Array: BinarySerializable where Element: BinarySerializable {
  public func serialize(into buffer: inout Buffer) {
    count.serialize(into: &buffer)
    for element in self {
      element.serialize(into: &buffer)
    }
  }

  public static func deserialize(from buffer: inout Buffer) throws -> [Element] {
    let count = try Int.deserialize(from: &buffer)
    var array: [Element] = []
    array.reserveCapacity(count)

    for _ in 0..<count {
      array.append(try .deserialize(from: &buffer))
    }

    return array
  }
}

extension Set: BinarySerializable where Element: BinarySerializable {
  public func serialize(into buffer: inout Buffer) {
    count.serialize(into: &buffer)
    for element in self {
      element.serialize(into: &buffer)
    }
  }

  public static func deserialize(from buffer: inout Buffer) throws -> Set<Element> {
    let count = try Int.deserialize(from: &buffer)
    var set: Set<Element> = []
    set.reserveCapacity(count)

    for _ in 0..<count {
      set.insert(try .deserialize(from: &buffer))
    }

    return set
  }
}

extension Optional: BinarySerializable where Wrapped: BinarySerializable {
  public func serialize(into buffer: inout Buffer) {
    if let value = self {
      true.serialize(into: &buffer)
      value.serialize(into: &buffer)
    } else {
      false.serialize(into: &buffer)
    }
  }

  public static func deserialize(from buffer: inout Buffer) throws -> Wrapped? {
    let isPresent = try Bool.deserialize(from: &buffer)
    if isPresent {
      return try Wrapped.deserialize(from: &buffer)
    } else {
      return nil
    }
  }
}

extension Dictionary: BinarySerializable where Key: BinarySerializable, Value: BinarySerializable {
  public func serialize(into buffer: inout Buffer) {
    count.serialize(into: &buffer)
    for (key, value) in self {
      key.serialize(into: &buffer)
      value.serialize(into: &buffer)
    }
  }

  public static func deserialize(from buffer: inout Buffer) throws -> Dictionary<Key, Value> {
    let count = try Int.deserialize(from: &buffer)
    var dictionary: [Key: Value] = [:]
    dictionary.reserveCapacity(count)
    for _ in 0..<count {
      let key = try Key.deserialize(from: &buffer)
      let value = try Value.deserialize(from: &buffer)
      dictionary[key] = value
    }
    return dictionary
  }
}
