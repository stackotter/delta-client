import Foundation

/// Holds information about kinds of entities.
public struct EntityRegistry: Codable {
  /// All entity kinds. Indexed by entity id.
  public var entities: [EntityKind] = []
  /// Maps biome identifier to an index in ``entities``.
  private var identifierToEntityId: [Identifier: Int] = [:]
  
  // MARK: Init
  
  /// Creates an empty entity registry.
  public init() {}
  
  /// Creates a populated entity registry.
  public init(entities: [EntityKind]) {
    self.entities = entities
    for entity in entities {
      identifierToEntityId[entity.identifier] = entity.id
    }
  }
  
  // MARK: Access
  
  /// Get information about the entity specified.
  /// - Parameter identifier: Entity identifier.
  /// - Returns: Entity information. `nil` if entity doesn't exist.
  public func entity(for identifier: Identifier) -> EntityKind? {
    if let index = identifierToEntityId[identifier] {
      return entities[index]
    } else {
      return nil
    }
  }
  
  /// Get information about the entity specified.
  /// - Parameter id: A entity id.
  /// - Returns: Entity information. `nil` if entity id is out of range.
  ///
  /// Will fatally crash if the entity id doesn't exist. Use wisely.
  public func entity(withId id: Int) -> EntityKind {
    return entities[id]
  }
}
