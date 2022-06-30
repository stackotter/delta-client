import Foundation

public struct Ingredient {
  public var ingredients: [Slot]
  public var count: Int {
    return ingredients.count
  }
}
