import Foundation

extension Biome {
  /// Used to specify a type of biome. Sometimes it's required to specify one specific biome, and sometimes a group. That's where this comes in handy.
  public enum Criteria: Hashable {
    /// Only match biomes with a specific identifier.
    case identifier(Identifier)
    /// Match all biomes in a specific category.
    case category(Category)
  }
}
