import Foundation

public struct Ingredient {
  public var ingredients: [ItemStack]
  public var count: Int {
    return ingredients.count
  }
}
