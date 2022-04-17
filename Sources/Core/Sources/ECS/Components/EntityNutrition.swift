import FirebladeECS

/// A component storing an entity's food and saturation levels.
public class EntityNutrition: Component {
  public var food: Int
  public var saturation: Float
  
  /// Creates an entity's nutrition with the provided values.
  /// - Parameters:
  ///   - food: Defaults to 20.
  ///   - saturation: Defaults to 0.
  public init(food: Int = 20, saturation: Float = 0) {
    self.food = food
    self.saturation = saturation
  }
}
