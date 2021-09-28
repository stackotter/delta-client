import Foundation

/// An identifier consists of a namespace and a name, they are used by Mojang a lot.
public struct Identifier {
  /// The namespace of the identifier.
  public var namespace: String
  /// The name of the identifier.
  public var name: String
  
  /// Creates an identifier with the given name (and namespace if specified). The namespace defaults to 'minecraft'.
  public init(namespace: String = "minecraft", name: String) {
    self.namespace = namespace
    self.name = name
  }
  
  /// Creates an identifier from the given string. Throws if the string is not a valid identifier.
  public init(_ string: String) throws {
    // A nice regex just for you, good luck
    let pattern = "^(([0-9a-z\\-_]+):)?([0-9a-z\\-_/\\.]+)$"
    guard let regex = try? NSRegularExpression(pattern: pattern) else {
      log.critical("Failed to compile a static regex (that really shouldn't happen)")
      fatalError("Failed to compile a static regex (hmmmm, that really shouldn't happen)")
    }
    
    let result = regex.matches(in: string, range: NSRange(location: 0, length: string.utf8.count))
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
  }
}

extension Identifier: Equatable {
  public static func == (lhs: Identifier, rhs: Identifier) -> Bool {
    return lhs.namespace == rhs.namespace && lhs.name == rhs.name
  }
}

extension Identifier: Codable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let string = try container.decode(String.self)
    try self.init(string)
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(description)
  }
}
