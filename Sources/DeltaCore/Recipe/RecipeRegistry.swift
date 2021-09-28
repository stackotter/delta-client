//
//  RecipeRegistry.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 12/1/21.
//

import Foundation

public struct RecipeRegistry {
  public var craftingRecipes: [String: CraftingRecipe] = [:]
  public var heatRecipes: [String: HeatRecipe] = [:]
  public var specialRecipes: [String: SpecialRecipe] = [:]
  public var stonecuttingRecipes: [String: StonecuttingRecipe] = [:]
  public var smithingRecipes: [String: SmithingRecipe] = [:]
}
