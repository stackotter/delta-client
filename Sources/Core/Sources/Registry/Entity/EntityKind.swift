/// Information about a kind of entity (e.g. cows).
public struct EntityKind: Codable {
  /// The identifier for the entity.
  public var identifier: Identifier
  /// The entity's id.
  public var id: Int
  /// Width of the entity's hitbox (for both the x and z axes).
  public var width: Float
  /// Height of the entity's hitbox.
  public var height: Float
  /// Attributes that are the same for every entity of this kind (e.g. maximum health).
  public var attributes: [EntityAttribute: Float]
  
  public init(identifier: Identifier, id: Int, width: Float, height: Float, attributes: [EntityAttribute: Float]) {
    self.identifier = identifier
    self.id = id
    self.width = width
    self.height = height
    self.attributes = attributes
  }
}
