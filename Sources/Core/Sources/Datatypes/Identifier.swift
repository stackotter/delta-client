import Foundation

/// An identifier consists of a namespace and a name, they are used by Mojang a lot.
public struct Identifier {
  /// The namespace of the identifier.
  public var namespace: String
  /// The name of the identifier.
  public var name: String
  /// An identifier that is null is never equal to any other identifier (even another null identifier).
  public var isNull = false
  
  /// Precompiled regex for parsing identifier strings.
  private static let regex = try! NSRegularExpression(pattern: "^(([0-9a-z\\-_]+):)?([0-9a-z\\-_/\\.]+)$")
  
  /// An identifier that is never equal to any other identifier.
  public static var null: Identifier {
    var identifier = Identifier(namespace: "", name: "")
    identifier.isNull = true
    return identifier
  }
  
  /// Creates an identifier with the given name (and namespace if specified). The namespace defaults to 'minecraft'.
  public init(namespace: String = "minecraft", name: String) {
    self.namespace = namespace
    self.name = name
  }
  
  /// Creates an identifier from the given string. Throws if the string is not a valid identifier.
  public init(_ string: String) throws {
    // TODO: This initialiser seems to be a little inefficient, feel free to optimise it a little (by creating a custom parser instead of regex)
    let result = Self.regex.matches(in: string, range: NSRange(location: 0, length: string.utf8.count))
    if result.isEmpty {
      throw IdentifierError.invalidIdentifierString(string)
    }
    
    if let nameRange = Range(result[0].range(at: 3)) {
      if let namespaceRange = Range(result[0].range(at: 2)) {
        let start = String.Index(utf16Offset: namespaceRange.lowerBound, in: string)
        let end = String.Index(utf16Offset: namespaceRange.upperBound, in: string)
        namespace = String(string[start..<end])
      } else {
        namespace = "minecraft"
      }
      
      let start = String.Index(utf16Offset: nameRange.lowerBound, in: string)
      let end = String.Index(utf16Offset: nameRange.upperBound, in: string)
      name = String(string[start..<end])
    } else {
      throw IdentifierError.invalidIdentifier
    }
  }
}

// MARK: - Conformance

extension Identifier: CustomStringConvertible {
  public var description: String {
    return "\(namespace):\(name)"
  }
}

extension Identifier: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(namespace)
    hasher.combine(name)
    hasher.combine(isNull)
  }
}

extension Identifier: Equatable {
  public static func == (lhs: Identifier, rhs: Identifier) -> Bool {
    if lhs.isNull || rhs.isNull {
      return false
    }
    
    return lhs.namespace == rhs.namespace && lhs.name == rhs.name
  }
}

extension Identifier: Codable {
  public init(from decoder: Decoder) throws {
    do {
      // Decode identifiers in the form ["namespace", "name"] (it's a lot faster than string form)
      var container = try decoder.unkeyedContainer()
      let namespace = try container.decode(String.self)
      let name = try container.decode(String.self)
      self.init(namespace: namespace, name: name)
    } catch {
      // If the previous decoding method files the value is likely stored as a single string (of the form "namespace:name")
      let container = try decoder.singleValueContainer()
      let string = try container.decode(String.self)
      try self.init(string)
    }
  }
  
  public func encode(to encoder: Encoder) throws {
    // Encode the identifier in the form ["namespace", "name"]
    var container = encoder.unkeyedContainer()
    try container.encode(namespace)
    try container.encode(name)
  }
}
