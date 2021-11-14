import Foundation

/// Holds information about kinds of entities.
public struct EntityRegistry: Codable {
  /// Maps entity kind id to information about that kind of entity.
  public var entities: [Int: EntityKind] = [:]
  /// Maps entity identifier to an entity kind id.
  public var identifierToEntityId: [Identifier: Int] = [:]
  /// The kind id of player entities.
  public var playerEntityKindId: Int
  
  // MARK: Init
  
  /// Creates an empty entity registry.
  public init() {
    playerEntityKindId = -1
  }
  
  /// Creates a populated entity registry.
  ///
  /// Throws an error if `entities` does not contain the player entity.
  public init(entities: [Int: EntityKind]) throws {
    self.entities = entities
    for (_, entity) in entities {
      identifierToEntityId[entity.identifier] = entity.id
    }
    
    guard let playerEntityKindId = identifierToEntityId[Identifier(name: "player")] else {
      throw PixlyzerError.entityRegistryMissingPlayer
    }
    
    self.playerEntityKindId = playerEntityKindId
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
  /// - Parameter id: An entity id.
  /// - Returns: Entity information. `nil` if entity id is out of range.
  public func entity(withId id: Int) -> EntityKind? {
    return entities[id]
  }
}
