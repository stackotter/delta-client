import Foundation

public struct PixlyzerItem: Decodable {
  public var id: Int
  public var category: Int?
  public var rarity: ItemRarity
  public var maximumStackSize: Int
  public var maximumDamage: Int
  public var isFireResistant: Bool
  public var isComplex: Bool
  public var translationKey: String
  public var block: Int?
  public var className: String

  private enum CodingKeys: String, CodingKey {
    case id
    case category
    case rarity
    case maximumStackSize = "max_stack_size"
    case maximumDamage = "max_damage"
    case isFireResistant = "is_fire_resistant"
    case isComplex = "is_complex"
    case translationKey = "translation_key"
    case block
    case className = "class"
  }
}

extension Item {
  public init(from pixlyzerItem: PixlyzerItem, identifier: Identifier) {
    id = pixlyzerItem.id
    self.identifier = identifier
    rarity = pixlyzerItem.rarity
    maximumStackSize = pixlyzerItem.maximumStackSize
    maximumDamage = pixlyzerItem.maximumDamage
    isFireResistant = pixlyzerItem.isFireResistant
    translationKey = "" // pixlyzerItem.translationKey
    blockId = pixlyzerItem.block
  }
}
