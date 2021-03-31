//
//  RecipeRegistry.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 12/1/21.
//

import Foundation

struct RecipeRegistry {
  var craftingRecipes: [String: CraftingRecipe] = [:]
  var heatRecipes: [String: HeatRecipe] = [:]
  var specialRecipes: [String: SpecialRecipe] = [:]
  var stonecuttingRecipes: [String: StonecuttingRecipe] = [:]
  var smithingRecipes: [String: SmithingRecipe] = [:]
}
