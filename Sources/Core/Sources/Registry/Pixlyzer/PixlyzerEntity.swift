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

public extension EntityKind {
  init?(_ pixlyzerEntity: PixlyzerEntity, identifier: Identifier) {
    guard let id = pixlyzerEntity.id else {
      return nil
    }
    
    self.id = id
    self.identifier = identifier
    
    width = pixlyzerEntity.width ?? 0
    height = pixlyzerEntity.height ?? 0
    
    attributes = [:]
    for (attribute, value) in pixlyzerEntity.attributes ?? [:] {
      if let attribute = EntityAttribute(rawValue: attribute) {
        attributes[attribute] = value
      } else {
        log.warning("Unknown entity attribute in pixlyzer registry: '\(attribute)'")
      }
    }
  }
}
