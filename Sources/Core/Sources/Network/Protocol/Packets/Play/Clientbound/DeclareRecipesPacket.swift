import Foundation

public enum DeclareRecipesPacketError: LocalizedError {
  case unknownRecipeType(String)
  case unknownHeatRecipeType(String)
  case unknownSpecialRecipeType(String)
}

public struct DeclareRecipesPacket: ClientboundPacket {
  public static let id: Int = 0x5a
  
  public var recipeRegistry: RecipeRegistry
  
  public init(from packetReader: inout PacketReader) throws {
    recipeRegistry = RecipeRegistry()
    let numRecipes = packetReader.readVarInt()
    for _ in 0..<numRecipes {
      let type = try packetReader.readIdentifier()
      let recipeId = try packetReader.readString()
      
      if type.namespace == "minecraft" {
        switch type.name {
          case "crafting_shapeless":
            let recipe = try Self.readShapelessCraftingRecipe(from: &packetReader)
            recipeRegistry.craftingRecipes[recipeId] = recipe
          case "crafting_shaped":
            let recipe = try Self.readShapedCraftingRecipe(from: &packetReader)
            recipeRegistry.craftingRecipes[recipeId] = recipe
          case "smelting", "blasting", "smoking", "campfire_cooking":
            let recipe = try Self.readHeatRecipe(from: &packetReader, type: type)
            recipeRegistry.heatRecipes[recipeId] = recipe
          case "stonecutting":
            let recipe = try Self.readStonecuttingRecipe(from: &packetReader)
            recipeRegistry.stonecuttingRecipes[recipeId] = recipe
          case "smithing":
            let recipe = try Self.readSmithingRecipe(from: &packetReader) 
            recipeRegistry.smithingRecipes[recipeId] = recipe
          case let recipeType where recipeType.starts(with: "crafting_special_"):
            let recipe = try Self.specialRecipe(for: recipeType)
            recipeRegistry.specialRecipes[recipeId] = recipe 
          default:
            throw DeclareRecipesPacketError.unknownRecipeType(type.description)
        }
      }
    }
  }
  
  public func handle(for client: Client) throws {
    client.game.recipeRegistry = recipeRegistry
  }

  private static func readShapelessCraftingRecipe(from packetReader: inout PacketReader) throws -> CraftingShapeless {
    let group = try packetReader.readString()

    var ingredients: [Ingredient] = []
    let ingredientCount = packetReader.readVarInt()
    for _ in 0..<ingredientCount {
      let count = packetReader.readVarInt()
      var itemStacks: [ItemStack] = []
      for _ in 0..<count {
        let itemStack = try packetReader.readItemStack()
        itemStacks.append(itemStack)
      }
      let ingredient = Ingredient(ingredients: itemStacks)
      ingredients.append(ingredient)
    }

    let result = try packetReader.readItemStack()

    return CraftingShapeless(group: group, ingredients: ingredients, result: result)
  }

  private static func readShapedCraftingRecipe(from packetReader: inout PacketReader) throws -> CraftingShaped {
    let width = Int(packetReader.readVarInt())
    let height = Int(packetReader.readVarInt())
    let group = try packetReader.readString()
    
    var ingredients: [Ingredient] = []
    let ingredientCount = width * height
    for _ in 0..<ingredientCount {
      let count = packetReader.readVarInt()
      var itemStacks: [ItemStack] = []
      for _ in 0..<count {
        let itemStack = try packetReader.readItemStack()
        itemStacks.append(itemStack)
      }
      let ingredient = Ingredient(ingredients: itemStacks)
      ingredients.append(ingredient)
    }
    
    let result = try packetReader.readItemStack()

    return CraftingShaped(group: group, width: width, height: height, ingredients: ingredients, result: result)
  }

  private static func readHeatRecipe(from packetReader: inout PacketReader, type: Identifier) throws -> HeatRecipe {
    let group = try packetReader.readString()

    var itemStacks: [ItemStack] = []
    let count = packetReader.readVarInt()
    for _ in 0..<count {
      let itemStack = try packetReader.readItemStack()
      itemStacks.append(itemStack)
    }
    let ingredient = Ingredient(ingredients: itemStacks)

    let result = try packetReader.readItemStack()
    let experience = packetReader.readFloat()
    let cookingTime = Int(packetReader.readVarInt())
    
    var recipe: HeatRecipe
    switch type.name {
      case "smelting":
        recipe = SmeltingRecipe(group: group, ingredient: ingredient, result: result, experience: experience, cookingTime: cookingTime)
      case "blasting":
        recipe = BlastingRecipe(group: group, ingredient: ingredient, result: result, experience: experience, cookingTime: cookingTime)
      case "smoking":
        recipe = SmokingRecipe(group: group, ingredient: ingredient, result: result, experience: experience, cookingTime: cookingTime)
      case "campfire_cooking":
        recipe = CampfireCookingRecipe(group: group, ingredient: ingredient, result: result, experience: experience, cookingTime: cookingTime)
      default:
        throw DeclareRecipesPacketError.unknownHeatRecipeType(type.description)
    }

    return recipe
  }

  private static func readStonecuttingRecipe(from packetReader: inout PacketReader) throws -> StonecuttingRecipe {
    let group = try packetReader.readString()

    var itemStacks: [ItemStack] = []
    let count = packetReader.readVarInt()
    for _ in 0..<count {
      let itemStack = try packetReader.readItemStack()
      itemStacks.append(itemStack)
    }
    let ingredient = Ingredient(ingredients: itemStacks)

    let result = try packetReader.readItemStack()

    return StonecuttingRecipe(group: group, ingredient: ingredient, result: result)
  }

  private static func readSmithingRecipe(from packetReader: inout PacketReader) throws -> SmithingRecipe {
    var baseItemStacks: [ItemStack] = []
    let baseCount = packetReader.readVarInt()
    for _ in 0..<baseCount {
      let itemStack = try packetReader.readItemStack()
      baseItemStacks.append(itemStack)
    }
    let baseIngredient = Ingredient(ingredients: baseItemStacks)
    
    var additionItemStacks: [ItemStack] = []
    let additionCount = packetReader.readVarInt()
    for _ in 0..<additionCount {
      let itemStack = try packetReader.readItemStack()
      additionItemStacks.append(itemStack)
    }
    let additionIngredient = Ingredient(ingredients: additionItemStacks)
    
    let result = try packetReader.readItemStack()
    
    return SmithingRecipe(base: baseIngredient, addition: additionIngredient, result: result)
  }

  // swiftlint:disable:next cyclomatic_complexity
  private static func specialRecipe(for recipeType: String) throws -> SpecialRecipe {
    switch recipeType {
      case "crafting_special_armordye":
        return ArmorDyeRecipe()
      case "crafting_special_bookcloning":
        return BookCloningRecipe()
      case "crafting_special_mapcloning":
        return MapCloningRecipe()
      case "crafting_special_mapextending":
        return MapExtendingRecipe()
      case "crafting_special_firework_rocket":
        return FireworkRocketRecipe()
      case "crafting_special_firework_star":
        return FireworkStarRecipe()
      case "crafting_special_firework_star_fade":
        return FireworkStarFadeRecipe()
      case "crafting_special_repairitem":
        return RepairItemRecipe()
      case "crafting_special_tippedarrow":
        return TippedArrowRecipe()
      case "crafting_special_bannerduplicate":
        return BannerDuplicateRecipe()
      case "crafting_special_banneraddpattern":
        return BannerAddPatternRecipe()
      case "crafting_special_shielddecoration":
        return ShieldDecorationRecipe()
      case "crafting_special_shulkerboxcoloring":
        return ShulkerBoxColouringRecipe()
      case "crafting_special_suspiciousstew":
        return SuspiciousStewRecipe()
      default:
        throw DeclareRecipesPacketError.unknownSpecialRecipeType(recipeType)
    }
  }
}
