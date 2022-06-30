import Foundation

public protocol CraftingRecipe {
  var group: String { get }
  var ingredients: [Ingredient] { get }
  var result: Slot { get }
}
