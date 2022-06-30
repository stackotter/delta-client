import Foundation

struct SmokingRecipe: HeatRecipe {
  var group: String
  var ingredient: Ingredient
  var result: Slot
  
  var experience: Float
  var cookingTime: Int
}
