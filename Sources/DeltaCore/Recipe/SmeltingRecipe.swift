import Foundation

struct SmeltingRecipe: HeatRecipe {
  var group: String
  var ingredient: Ingredient
  var result: ItemStack

  var experience: Float
  var cookingTime: Int
}
