import Foundation

/// An error thrown during serialization implemented via ``Serializable``.
public enum SerializationError: LocalizedError {
  case invalidSerializationFormatVersion(Int, expectedVersion: Int)

  public var errorDescription: String? {
    switch self {
      case .invalidSerializationFormatVersion(let version, expectedVersion: let expectedVersion):
        return """
        Invalid serialization format version.
        Expected: \(expectedVersion)
        Received: \(version)
        """
    }
  }
}

/// An error thrown during deserialization implemented via ``Serializable``.
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
public protocol Serializable {
  /// Serializes the value into a byte buffer.
  func serialize(into buffer: inout Buffer)
  /// Deserializes a value from a byte buffer.
  static func deserialize(from buffer: inout Buffer) throws -> Self
}

public extension Serializable {
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
public protocol RootSerializable: Serializable {
  static var serializationFormatVersion: Int { get }
}

public extension RootSerializable {
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
      throw SerializationError.invalidSerializationFormatVersion(incomingVersion, expectedVersion: serializationFormatVersion)
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
/// The ``Serializable`` implementation provided by conforming to this marker protocol essentially
/// just copies the raw bytes of a type into the output for serialization, and reverses the process
/// extremely efficiently when deserializing using unsafe pointers. Bitwise copyable types are the
/// fastest types to serialize and deserialize.
public protocol BitwiseCopyable: Serializable {}

public extension BitwiseCopyable {
  @inline(__always)
  func serialize(into writer: inout Buffer) {
    precondition(_isPOD(Self.self), "\(type(of: self)) must be a bitwise copyable datatype to conform to BitwiseCopyable")
    var value = self
    withUnsafeBytes(of: &value) { buffer in
      let pointer = buffer.assumingMemoryBound(to: UInt8.self).baseAddress!
      for i in 0..<MemoryLayout<Self>.size {
        writer.writeByte(pointer.advanced(by: i).pointee)
      }

      if MemoryLayout<Self>.size == MemoryLayout<Self>.stride {
        return
      }

      // Padding with zeroes is required to avoid segfaults that would occur if the last type
      // serialized into a buffer was a type that had mismatching size and stride and the length of
      // the buffer happened to be aligned with the end of a page. Using a for loop seems to be the
      // fastest way to do this with Swift's array API. There would definitely be faster ways in C.
      for _ in MemoryLayout<Self>.size..<MemoryLayout<Self>.stride {
        writer.writeByte(0)
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

extension Matrix2x2: BitwiseCopyable, Serializable {}
extension Matrix3x3: BitwiseCopyable, Serializable {}
extension Matrix4x4: BitwiseCopyable, Serializable {}

extension SIMD2: BitwiseCopyable, Serializable {}
extension SIMD3: BitwiseCopyable, Serializable {}
extension SIMD4: BitwiseCopyable, Serializable {}
extension SIMD8: BitwiseCopyable, Serializable {}
extension SIMD16: BitwiseCopyable, Serializable {}
extension SIMD32: BitwiseCopyable, Serializable {}
extension SIMD64: BitwiseCopyable, Serializable {}

extension String: Serializable {
  public func serialize(into buffer: inout Buffer) {
    count.serialize(into: &buffer)
    buffer.writeString(self)
  }

  public static func deserialize(from buffer: inout Buffer) throws -> Self {
    let count = try Int.deserialize(from: &buffer)
    return try buffer.readString(length: count)
  }
}

public extension Serializable where Self: RawRepresentable, RawValue: Serializable {
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

extension Array: Serializable where Element: Serializable {
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

extension Set: Serializable where Element: Serializable {
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

extension Optional: Serializable where Wrapped: Serializable {
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

extension Dictionary: Serializable where Key: Serializable, Value: Serializable {
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
