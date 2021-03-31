//
//  DeclareRecipesPacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 3/1/21.
//

import Foundation
import os

struct DeclareRecipesPacket: ClientboundPacket {
  static let id: Int = 0x5a
  
  var recipeRegistry: RecipeRegistry
  
  init(from packetReader: inout PacketReader) throws {
    recipeRegistry = RecipeRegistry()
    let numRecipes = packetReader.readVarInt()
    for _ in 0..<numRecipes {
      let type = try packetReader.readIdentifier()
      let recipeId = packetReader.readString()
      
      if type.namespace == "minecraft" {
        switch type.name {
          case "crafting_shapeless":
            let group = packetReader.readString()
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
            let recipe = CraftingShapeless(group: group, ingredients: ingredients, result: result)
            recipeRegistry.craftingRecipes[recipeId] = recipe
          case "crafting_shaped":
            let width = Int(packetReader.readVarInt())
            let height = Int(packetReader.readVarInt())
            let group = packetReader.readString()
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
            let recipe = CraftingShaped(group: group, width: width, height: height, ingredients: ingredients, result: result)
            recipeRegistry.craftingRecipes[recipeId] = recipe
          case "smelting", "blasting", "smoking", "campfire_cooking":
            let group = packetReader.readString()
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
            
            var recipe: HeatRecipe? = nil
            switch type.name {
              case "smelting":
                recipe = BlastingRecipe(group: group, ingredient: ingredient, result: result, experience: experience, cookingTime: cookingTime)
              case "blasting":
                recipe = BlastingRecipe(group: group, ingredient: ingredient, result: result, experience: experience, cookingTime: cookingTime)
              case "smoking":
                recipe = SmokingRecipe(group: group, ingredient: ingredient, result: result, experience: experience, cookingTime: cookingTime)
              case "campfire_cooking":
                recipe = CampfireCookingRecipe(group: group, ingredient: ingredient, result: result, experience: experience, cookingTime: cookingTime)
              default:
                Logger.debug("unknown heat recipe type: \(type.toString())")
                break
            }
            if recipe != nil {
              recipeRegistry.heatRecipes[recipeId] = recipe
            }
          case "stonecutting":
            let group = packetReader.readString()
            var itemStacks: [ItemStack] = []
            let count = packetReader.readVarInt()
            for _ in 0..<count {
              let itemStack = try packetReader.readItemStack()
              itemStacks.append(itemStack)
            }
            let ingredient = Ingredient(ingredients: itemStacks)
            let result = try packetReader.readItemStack()
            let recipe = StonecuttingRecipe(group: group, ingredient: ingredient, result: result)
            recipeRegistry.stonecuttingRecipes[recipeId] = recipe
          case "smithing":
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
            
            let recipe = SmithingRecipe(base: baseIngredient, addition: additionIngredient, result: result)
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
                Logger.debug("unknown special recipe type: \(type.toString())")
                break
            }
            if recipe != nil {
              recipeRegistry.specialRecipes[recipeId] = recipe!
            }
          default:
            Logger.debug("unknown recipe type")
        }
      }
    }
  }
  
  func handle(for server: Server) throws {
    server.recipeRegistry = recipeRegistry
  }
}
