import Foundation

public enum PixlyzerItemError: LocalizedError {
  case missingRequiredPropertiesForEquipment(id: Int)
  case missingRequiredPropertiesForTool(id: Int)
  case unhandledToolClass(String)
  case axeMissingStrippableBlocks(id: Int)
  case hoeMissingTillableBlocks(id: Int)
  case shovelMissingFlattenableBlocks(id: Int)
  case invalidBlockIdInteger(String)

  public var errorDescription: String? {
    switch self {
      case let .missingRequiredPropertiesForEquipment(id):
        return "Missing required properties for equipment item with id: \(id)."
      case let .missingRequiredPropertiesForTool(id):
        return "Missing required properties for tool item with id: \(id)."
      case let .unhandledToolClass(className):
        return "Encountered unhandled tool class '\(className)'."
      case let .axeMissingStrippableBlocks(id):
        return "Axe with id '\(id)' missing strippable blocks."
      case let .hoeMissingTillableBlocks(id):
        return "Hoe with id '\(id)' missing tillable blocks."
      case let .shovelMissingFlattenableBlocks(id):
        return "Shovel with id '\(id)' missing flattenable blocks."
      case let .invalidBlockIdInteger(id):
        return "Invalid block id '\(id)' (expected an integer)."
    }
  }
}

public struct PixlyzerItem: Decodable {
  public var id: Int
  public var category: Int?
  public var rarity: ItemRarity
  public var maximumStackSize: Int
  public var maximumDamage: Int
  public var isFireResistant: Bool
  public var isComplex: Bool
  public var translationKey: String
  public var equipmentSlot: Item.ArmorProperties.EquipmentSlot?
  public var defense: Int?
  public var toughness: Double?
  public var armorMaterial: Identifier?
  public var knockbackResistance: Double?
  public var uses: Int?
  public var speed: Double?
  public var attackDamage: Double?
  public var attackDamageBonus: Double?
  public var level: Int?
  public var enchantmentValue: Int?
  public var diggableBlocks: [Int]?
  public var strippableBlocks: [String: Int]?
  public var tillableBlocks: [String: Int]?
  public var flattenableBlocks: [String: Int]?
  public var effectiveMaterials: [Identifier]?
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
    case equipmentSlot = "equipment_slot"
    case defense
    case toughness
    case armorMaterial = "armor_material"
    case knockbackResistance = "knockback_resistance"
    case uses
    case speed
    case attackDamage = "attack_damage"
    case attackDamageBonus = "attack_damage_bonus"
    case level
    case enchantmentValue = "enchantment_value"
    case diggableBlocks = "diggable_blocks"
    case strippableBlocks = "strippables_blocks"
    case tillableBlocks = "tillables_block_states"
    case flattenableBlocks = "flattenables_block_states"
    case effectiveMaterials = "effective_materials"
    case block
    case className = "class"
  }
}

extension Item {
  public init(from pixlyzerItem: PixlyzerItem, identifier: Identifier) throws {
    id = pixlyzerItem.id
    self.identifier = identifier
    rarity = pixlyzerItem.rarity
    maximumStackSize = pixlyzerItem.maximumStackSize
    maximumDamage = pixlyzerItem.maximumDamage
    isFireResistant = pixlyzerItem.isFireResistant
    translationKey = pixlyzerItem.translationKey
    blockId = pixlyzerItem.block

    if let equipmentSlot = pixlyzerItem.equipmentSlot {
      guard
        let defense = pixlyzerItem.defense,
        let toughness = pixlyzerItem.toughness,
        let armorMaterial = pixlyzerItem.armorMaterial,
        let knockbackResistance = pixlyzerItem.knockbackResistance
      else {
        throw PixlyzerItemError.missingRequiredPropertiesForEquipment(id: pixlyzerItem.id)
      }

      properties = .armor(Item.ArmorProperties(
        equipmentSlot: equipmentSlot,
        defense: defense,
        toughness: toughness,
        material: armorMaterial,
        knockbackResistance: knockbackResistance
      ))
    } else if let uses = pixlyzerItem.uses {
      guard
        let speed = pixlyzerItem.speed,
        let attackDamage = pixlyzerItem.attackDamage,
        let attackDamageBonus = pixlyzerItem.attackDamageBonus,
        let level = pixlyzerItem.level,
        let enchantmentValue = pixlyzerItem.enchantmentValue
      else {
        throw PixlyzerItemError.missingRequiredPropertiesForTool(id: pixlyzerItem.id)
      }

      let interactions: [String: Int]
      let kind: Item.ToolProperties.ToolKind
      switch pixlyzerItem.className {
        case "SwordItem":
          interactions = [:]
          kind = .sword
        case "PickaxeItem":
          interactions = [:]
          kind = .pickaxe
        case "AxeItem":
          guard let strippableBlocks = pixlyzerItem.strippableBlocks else {
            throw PixlyzerItemError.axeMissingStrippableBlocks(id: pixlyzerItem.id)
          }
          interactions = strippableBlocks
          kind = .axe
        case "ShovelItem":
          guard let flattenableBlocks = pixlyzerItem.flattenableBlocks else {
            throw PixlyzerItemError.shovelMissingFlattenableBlocks(id: pixlyzerItem.id)
          }
          interactions = flattenableBlocks
          kind = .shovel
        case "HoeItem":
          guard let tillableBlocks = pixlyzerItem.tillableBlocks else {
            throw PixlyzerItemError.hoeMissingTillableBlocks(id: pixlyzerItem.id)
          }
          interactions = tillableBlocks
          kind = .hoe
        default:
          throw PixlyzerItemError.unhandledToolClass(pixlyzerItem.className)
      }

      var parsedInteractions: [Int: Int] = [:]
      for (key, value) in interactions {
        guard let parsedKey = Int(key) else {
          throw PixlyzerItemError.invalidBlockIdInteger(key)
        }
        parsedInteractions[parsedKey] = value
      }

      properties = .tool(Item.ToolProperties(
        uses: uses,
        level: level,
        speed: speed,
        attackDamage: attackDamage,
        attackDamageBonus: attackDamageBonus,
        enchantmentValue: enchantmentValue,
        mineableBlocks: pixlyzerItem.diggableBlocks ?? [],
        blockInteractions: parsedInteractions,
        kind: kind,
        effectiveMaterials: pixlyzerItem.effectiveMaterials ?? []
      ))
    }
  }
}
