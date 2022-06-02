import Foundation
import Parsing

/// An identifier consists of a namespace and a name, they are used by Mojang a lot.
public struct Identifier: Hashable, Equatable, Codable, CustomStringConvertible {
  // MARK: Public properties
  
  /// The namespace of the identifier.
  public var namespace: String
  /// The name of the identifier.
  public var name: String
  
  /// The string representation of this identifier.
  public var description: String {
    return "\(namespace):\(name)"
  }
  
  // MARK: Private properties
  
  /// The set of characters allowed in an identifier namespace.
  private static let namespaceAllowedCharacters = Set("0123456789abcdefghijklmnopqrstuvwxyz-_")
  /// The set of characters allowed in an identifier name.
  private static let nameAllowedCharacters = Set("0123456789abcdefghijklmnopqrstuvwxyz-_./")
  
  /// The parser used to parse identifiers from strings.
  private static let identifierParser = OneOf {
    Parse {
      Prefix(1...) { namespaceAllowedCharacters.contains($0) }
      
      Optionally {
        ":"
        Prefix(1...) { nameAllowedCharacters.contains($0) }
      }
      
      End()
    }.map { tuple -> Identifier in
      if let name = tuple.1 {
        return Identifier(namespace: String(tuple.0), name: String(name))
      } else {
        return Identifier(name: String(tuple.0))
      }
    }
    
    // Required for the case where an identifier has no namespace and the name contains characters not allowed in a namespace
    Parse {
      Prefix { nameAllowedCharacters.contains($0) }
      End()
    }.map { name -> Identifier in
      return Identifier(name: String(name))
    }
  }
  
  // MARK: Init
  
  /// Creates an identifier with the given name (and namespace if specified). The namespace defaults to 'minecraft'.
  /// - Parameters:
  ///   - namespace: The namespace for the identifier. Defaults to `"minecraft"`.
  ///   - name: The name for the identifier.
  public init(namespace: String = "minecraft", name: String) {
    self.namespace = namespace
    self.name = name
  }
  
  /// Creates an identifier from the given string. Throws if the string is not a valid identifier.
  /// - Parameter string: String of the form `"namespace:name"` or `"name"`.
  public init(_ string: String) throws {
    do {
      let identifier = try Self.identifierParser.parse(string)
      name = identifier.name
      namespace = identifier.namespace
    } catch {
      throw IdentifierError.invalidIdentifier(string, error)
    }
  }
  
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
  
  // MARK: Public methods
  
  /// Hashes the identifier.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(namespace)
    hasher.combine(name)
  }
  
  public static func == (lhs: Identifier, rhs: Identifier) -> Bool {
    return lhs.namespace == rhs.namespace && lhs.name == rhs.name
  }
  
  /// Encodes the identifier in the form `["namespace", "name"]` (because it's the most efficient way).
  public func encode(to encoder: Encoder) throws {
    var container = encoder.unkeyedContainer()
    try container.encode(namespace)
    try container.encode(name)
  }
}
