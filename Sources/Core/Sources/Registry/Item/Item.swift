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
  /// The properties of the item specific to the type of item. `nil` if the item
  /// a just a plain old item (e.g. a stick) rather than a tool or an armor piece
  /// etc.
  public var properties: Properties?

  public enum Properties: Codable {
    case armor(ArmorProperties)
    case tool(ToolProperties)

    public var armorProperties: ArmorProperties? {
      guard case let .armor(properties) = self else {
        return nil
      }
      return properties
    }

    public var toolProperties: ToolProperties? {
      guard case let .tool(properties) = self else {
        return nil
      }
      return properties
    }
  }

  public struct ArmorProperties: Codable {
    public var equipmentSlot: EquipmentSlot
    public var defense: Int
    public var toughness: Double
    public var material: Identifier
    public var knockbackResistance: Double

    public init(
      equipmentSlot: Item.ArmorProperties.EquipmentSlot,
      defense: Int,
      toughness: Double,
      material: Identifier,
      knockbackResistance: Double
    ) {
      self.equipmentSlot = equipmentSlot
      self.defense = defense
      self.toughness = toughness
      self.material = material
      self.knockbackResistance = knockbackResistance
    }

    public enum EquipmentSlot: String, Codable {
      case head
      case chest
      case legs
      case feet

      /// The index of the slot corresponding
      public var index: Int {
        switch self {
          case .head:
            return 0
          case .chest:
            return 1
          case .legs:
            return 2
          case .feet:
            return 3
        }
      }
    }
  }

  public struct ToolProperties: Codable {
    public var uses: Int
    public var level: Level
    public var speed: Double
    public var attackDamage: Double
    public var attackDamageBonus: Double
    public var enchantmentValue: Int
    /// Blocks that can be mined faster using this tool. Doesn't include
    /// blocks covered by ``ToolProperties/effectiveMaterials``.
    public var mineableBlocks: [Int]
    /// When tools are used to right click blocks, they can cause the block
    /// to change state, e.g. a log gets stripped if you right click it with
    /// an axe. This mapping doesn't include blocks which are always right
    /// clickable.
    public var blockInteractions: [Int: Int]
    public var kind: ToolKind
    /// Materials which this tool is effective on. Used to minimise the length
    /// of ``BlockInteractions/mineableBlocks`` by covering large categories of
    /// blocks at a time.
    public var effectiveMaterials: [Identifier]

    public enum Level: Int, Codable, Equatable, Comparable {
      case woodOrGold = 0
      case stone = 1
      case iron = 2
      case diamond = 3
      case netherite = 4

      public static func < (lhs: Level, rhs: Level) -> Bool {
        lhs.rawValue < rhs.rawValue
      }
    }

    public init(
      uses: Int,
      level: Level,
      speed: Double,
      attackDamage: Double,
      attackDamageBonus: Double,
      enchantmentValue: Int,
      mineableBlocks: [Int],
      blockInteractions: [Int: Int],
      kind: Item.ToolProperties.ToolKind,
      effectiveMaterials: [Identifier]
    ) {
      self.uses = uses
      self.level = level
      self.speed = speed
      self.attackDamage = attackDamage
      self.attackDamageBonus = attackDamageBonus
      self.enchantmentValue = enchantmentValue
      self.mineableBlocks = mineableBlocks
      self.blockInteractions = blockInteractions
      self.kind = kind
      self.effectiveMaterials = effectiveMaterials
    }

    public func destroySpeedMultiplier(for block: Block) -> Double {
      switch kind {
        case .sword:
          let swordSemiEffectiveMaterials = ["plant", "replaceable_plant"].map(
            Identifier.init(name:))
          if block.className == "CobwebBlock" {
            return 0.15
          } else if swordSemiEffectiveMaterials.contains(block.vanillaMaterialIdentifier) {
            return 0.015
          } else {
            return 0.01
          }
        case .pickaxe, .shovel, .hoe, .axe:
          let isCorrectTool =
            effectiveMaterials.contains(block.vanillaMaterialIdentifier)
            || mineableBlocks.contains(block.vanillaParentBlockId)
          if isCorrectTool {
            return speed * (1 / 30)
          } else {
            return block.physicalMaterial.requiresTool ? 0.01 : (1 / 30)
          }
      }
    }

    public enum ToolKind: String, Codable {
      case sword
      case pickaxe
      case shovel
      case hoe
      case axe
    }
  }

  public init(
    id: Int,
    identifier: Identifier,
    rarity: ItemRarity,
    maximumStackSize: Int,
    maximumDamage: Int,
    isFireResistant: Bool,
    translationKey: String,
    blockId: Int? = nil,
    properties: Item.Properties? = nil
  ) {
    self.id = id
    self.identifier = identifier
    self.rarity = rarity
    self.maximumStackSize = maximumStackSize
    self.maximumDamage = maximumDamage
    self.isFireResistant = isFireResistant
    self.translationKey = translationKey
    self.blockId = blockId
    self.properties = properties
  }
}
