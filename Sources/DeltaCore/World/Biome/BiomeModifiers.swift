import Foundation

/// A collection of modifiers targeted at biomes that satisfy criteria.
///
/// Always returns the most specific modifier. Used by ``BiomeColors``.
public struct BiomeModifiers<Modifier>: ExpressibleByDictionaryLiteral {
  private var storage: [Biome.Criteria: Modifier] = [:]
  
  /// Creates a new empty collection of biome modifiers.
  public init() {}
  
  /// Creates a new collection of biome modifiers from a dictionary literal.
  /// - Parameter elements: Map of criteria to modifier.
  public init(dictionaryLiteral elements: (Biome.Criteria, Modifier)...) {
    for (key, value) in elements {
      storage[key] = value
    }
  }
  
  public subscript(_ biome: Biome) -> Modifier? {
    get {
      if let modifier = storage[.identifier(biome.identifier)] {
        return modifier
      } else if let modifier = storage[.category(biome.category)] {
        return modifier
      } else {
        return nil
      }
    }
  }
  
  public subscript(_ criteria: Biome.Criteria) -> Modifier? {
    get {
      return storage[criteria]
    } set(modifier) {
      storage[criteria] = modifier
    }
  }
}
