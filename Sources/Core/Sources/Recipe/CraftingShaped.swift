import Foundation

struct CraftingShaped: CraftingRecipe {
  var group: String
  
  var width: Int
  var height: Int
  var ingredients: [Ingredient]
  
  var result: Slot
}
