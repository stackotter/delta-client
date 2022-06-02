import Foundation

public struct RecipeRegistry {
  public var craftingRecipes: [String: CraftingRecipe] = [:]
  public var heatRecipes: [String: HeatRecipe] = [:]
  public var specialRecipes: [String: SpecialRecipe] = [:]
  public var stonecuttingRecipes: [String: StonecuttingRecipe] = [:]
  public var smithingRecipes: [String: SmithingRecipe] = [:]
}
