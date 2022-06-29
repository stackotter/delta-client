import Foundation

// Information about an item.
public struct Item: Codable {
  /// The item's id.
  public var id: Int
  /// The identifier.
  public var identifier: Identifier
  /// The item's rarity.
  public var rarity: ItemRarity
  /// The maximum size of a stack of this item.
  public var maximumStackSize: Int
  /// The maximum damage this item can deal.
  public var maximumDamage: Int
  /// Whether the item is fire resistant as an entity.
  public var isFireResistant: Bool
  /// The locale translation key to use as the name of this item.
  public var translationKey: String
  /// The id of the block corresponding to this item.
  public var blockId: Int?
}
