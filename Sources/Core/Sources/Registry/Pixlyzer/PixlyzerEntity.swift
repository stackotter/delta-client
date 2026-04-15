import Foundation

/// Entity data from Pixlyzer.
public struct PixlyzerEntity: Decodable {
  public var id: Int?
  public var serializable: Bool?
  public var summonable: Bool?
  public var isFireImmune: Bool?
  public var lootTable: Identifier?
  public var width: Float?
  public var height: Float?
  public var sizeFixed: Bool?
  public var `class`: String?
  public var attributes: [String: Float]?
  public var meta: [String: Int]?
  public var parent: String?
}

extension EntityKind {
  /// Returns nil if the pixlyzer entity doesn't correspond to a Vanilla minecraft entity kind.
  /// Throws on unknown entity attributes.
  public init?(
    from pixlyzerEntity: PixlyzerEntity, inheritanceChain: [String], identifier: Identifier
  ) throws {
    guard let id = pixlyzerEntity.id else {
      return nil
    }

    self.id = id
    self.identifier = identifier
    self.isLiving = inheritanceChain.contains("LivingEntity")
    self.inheritanceChain = inheritanceChain

    width = pixlyzerEntity.width ?? 0
    height = pixlyzerEntity.height ?? 0

    attributes = [:]
    for (attribute, value) in pixlyzerEntity.attributes ?? [:] {
      guard let attribute = EntityAttributeKey(rawValue: attribute) else {
        throw PixlyzerError.unknownEntityAttribute(attribute)
      }

      attributes[attribute] = value
    }
  }
}
