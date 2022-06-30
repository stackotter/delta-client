import Foundation

// encompasses smelting, blasting, smoking and campfire cooking
public protocol HeatRecipe {
  var group: String { get }
  var ingredient: Ingredient { get }
  var result: Slot { get }

  var experience: Float { get }
  var cookingTime: Int { get }
}
