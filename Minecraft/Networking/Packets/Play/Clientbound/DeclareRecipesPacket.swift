//
//  DeclareRecipes.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 3/1/21.
//

import Foundation
import os

struct DeclareRecipesPacket: Packet {
  typealias PacketType = DeclareRecipesPacket
  static let id: Int = 0x5a
  
  var recipeRegistry: RecipeRegistry
  
  static func from(_ packetReader: PacketReader) throws -> DeclareRecipesPacket? {
    #if DEBUG
    // helps to detect changes in the protocol (already helped once)
    let logger = Logger.init(for: type(of: self))
    #endif
    
    var mutableReader = packetReader
    
    var recipeRegistry = RecipeRegistry()
    let numRecipes = mutableReader.readVarInt()
    for _ in 0..<numRecipes {
      let type = try mutableReader.readIdentifier()
      let recipeId = mutableReader.readString()
      
      if type.namespace == "minecraft" {
        switch type.name {
          case "crafting_shapeless":
            let group = mutableReader.readString()
            var ingredients: [Ingredient] = []
            let ingredientCount = mutableReader.readVarInt()
            for _ in 0..<ingredientCount {
              let count = mutableReader.readVarInt()
              var itemStacks: [ItemStack] = []
              for _ in 0..<count {
                let slot = try mutableReader.readSlot()
                itemStacks.append(ItemStack(fromSlot: slot))
              }
              let ingredient = Ingredient(ingredients: itemStacks)
              ingredients.append(ingredient)
            }
            let result = try mutableReader.readSlot()
            let recipe = CraftingShapeless(group: group, ingredients: ingredients, result: ItemStack(fromSlot: result))
            recipeRegistry.craftingRecipes[recipeId] = recipe
          case "crafting_shaped":
            let width = Int(mutableReader.readVarInt())
            let height = Int(mutableReader.readVarInt())
            let group = mutableReader.readString()
            var ingredients: [Ingredient] = []
            let ingredientCount = width * height
            for _ in 0..<ingredientCount {
              let count = mutableReader.readVarInt()
              var itemStacks: [ItemStack] = []
              for _ in 0..<count {
                let slot = try mutableReader.readSlot()
                itemStacks.append(ItemStack(fromSlot: slot))
              }
              let ingredient = Ingredient(ingredients: itemStacks)
              ingredients.append(ingredient)
            }
            let result = try mutableReader.readSlot()
            let resultItemStack = ItemStack(fromSlot: result)
            let recipe = CraftingShaped(group: group, width: width, height: height, ingredients: ingredients, result: resultItemStack)
            recipeRegistry.craftingRecipes[recipeId] = recipe
          case "smelting", "blasting", "smoking", "campfire_cooking":
            let group = mutableReader.readString()
            var itemStacks: [ItemStack] = []
            let count = mutableReader.readVarInt()
            for _ in 0..<count {
              let slot = try mutableReader.readSlot()
              itemStacks.append(ItemStack(fromSlot: slot))
            }
            let ingredient = Ingredient(ingredients: itemStacks)
            let result = try mutableReader.readSlot()
            let resultItemStack = ItemStack(fromSlot: result)
            let experience = mutableReader.readFloat()
            let cookingTime = Int(mutableReader.readVarInt())
            
            var recipe: HeatRecipe? = nil
            switch type.name {
              case "smelting":
                recipe = BlastingRecipe(group: group, ingredient: ingredient, result: resultItemStack, experience: experience, cookingTime: cookingTime)
              case "blasting":
                recipe = BlastingRecipe(group: group, ingredient: ingredient, result: resultItemStack, experience: experience, cookingTime: cookingTime)
              case "smoking":
                recipe = SmokingRecipe(group: group, ingredient: ingredient, result: resultItemStack, experience: experience, cookingTime: cookingTime)
              case "campfire_cooking":
                recipe = CampfireCookingRecipe(group: group, ingredient: ingredient, result: resultItemStack, experience: experience, cookingTime: cookingTime)
              default:
                #if DEBUG
                logger.debug("unknown heat recipe type: \(type.toString())")
                #endif
                break
            }
            if recipe != nil {
              recipeRegistry.heatRecipes[recipeId] = recipe
            }
          case "stonecutting":
            let group = mutableReader.readString()
            var itemStacks: [ItemStack] = []
            let count = mutableReader.readVarInt()
            for _ in 0..<count {
              let slot = try mutableReader.readSlot()
              itemStacks.append(ItemStack(fromSlot: slot))
            }
            let ingredient = Ingredient(ingredients: itemStacks)
            let result = try mutableReader.readSlot()
            let resultItemStack = ItemStack(fromSlot: result)
            let recipe = StonecuttingRecipe(group: group, ingredient: ingredient, result: resultItemStack)
            recipeRegistry.stonecuttingRecipes[recipeId] = recipe
          case "smithing":
            var baseItemStacks: [ItemStack] = []
            let baseCount = mutableReader.readVarInt()
            for _ in 0..<baseCount {
              let slot = try mutableReader.readSlot()
              baseItemStacks.append(ItemStack(fromSlot: slot))
            }
            let baseIngredient = Ingredient(ingredients: baseItemStacks)
            
            var additionItemStacks: [ItemStack] = []
            let additionCount = mutableReader.readVarInt()
            for _ in 0..<additionCount {
              let slot = try mutableReader.readSlot()
              additionItemStacks.append(ItemStack(fromSlot: slot))
            }
            let additionIngredient = Ingredient(ingredients: additionItemStacks)
            
            let result = try mutableReader.readSlot()
            let resultItemStack = ItemStack(fromSlot: result)
            
            let recipe = SmithingRecipe(base: baseIngredient, addition: additionIngredient, result: resultItemStack)
            recipeRegistry.smithingRecipes[recipeId] = recipe
          case let recipeType where recipeType.starts(with: "crafting_special_"):
            // special recipes
            var recipe: SpecialRecipe? = nil
            switch recipeType {
              case "crafting_special_armordye":
                recipe = ArmorDyeRecipe()
              case "crafting_special_bookcloning":
                recipe = BookCloningRecipe()
              case "crafting_special_mapcloning":
                recipe = MapCloningRecipe()
              case "crafting_special_mapextending":
                recipe = MapExtendingRecipe()
              case "crafting_special_firework_rocket":
                recipe = FireworkRocketRecipe()
              case "crafting_special_firework_star":
                recipe = FireworkStarRecipe()
              case "crafting_special_firework_star_fade":
                recipe = FireworkStarFadeRecipe()
              case "crafting_special_repairitem":
                recipe = RepairItemRecipe()
              case "crafting_special_tippedarrow":
                recipe = TippedArrowRecipe()
              case "crafting_special_bannerduplicate":
                recipe = BannerDuplicateRecipe()
              case "crafting_special_banneraddpattern":
                recipe = BannerAddPatternRecipe()
              case "crafting_special_shielddecoration":
                recipe = ShieldDecorationRecipe()
              case "crafting_special_shulkerboxcoloring":
                recipe = ShulkerBoxColouringRecipe()
              case "crafting_special_suspiciousstew":
                recipe = SuspiciousStewRecipe()
              default:
                #if DEBUG
                logger.debug("unknown special recipe type: \(type.toString())")
                #endif
                break
            }
            if recipe != nil {
              recipeRegistry.specialRecipes[recipeId] = recipe!
            }
          default:
            print("unknown recipe type")
        }
      }
    }
    
    return DeclareRecipesPacket(recipeRegistry: recipeRegistry)
  }
}
