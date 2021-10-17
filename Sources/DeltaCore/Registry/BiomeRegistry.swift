import Foundation

/// An error to do with biome loading most likely.
public enum BiomeError: LocalizedError {
  /// Failed to load biome data from pixlyzer data.
  case failedToLoadPixlyzerBiomes(Error)
  /// Failed to load the foliage color map from the resource pack.
  case failedToLoadFoliageColorMap(Error)
  /// Failed to load the grass color map from the resource pack.
  case failedToLoadGrassColorMap(Error)
  /// Biome colormaps from resourcepacks ('grass.png' and 'foliage.png') must be 256x256.
  case colorMapNot256By256Pixels
}

/// Holds information about biomes.
public struct BiomeRegistry: Codable {
  /// All biomes. Thanks Mojang for having some missing ids and forcing me to use a dictionary.
  public var biomes: [Int: Biome] = [:]
  /// Maps biome identifier to biome id.
  private var identifierToBiomeId: [Identifier: Int] = [:]
  
  // MARK: Init
  
  /// Creates an empty ``BiomeRegistry``.
  public init() {}
  
  /// Creates a populated ``BiomeRegistry``.
  public init(biomes: [Int: Biome]) {
    self.biomes = biomes
    for (id, biome) in biomes {
      identifierToBiomeId[biome.identifier] = id
    }
  }
  
  // MARK: Access
  
  /// Get information about the biome specified.
  /// - Parameter identifier: Biome identifier.
  /// - Returns: Biome information. `nil` if biome doesn't exist.
  public func biome(for identifier: Identifier) -> Biome? {
    if let id = identifierToBiomeId[identifier] {
      return biomes[id]
    } else {
      return nil
    }
  }
  
  /// Get information about the biome specified.
  /// - Parameter id: A biome id.
  /// - Returns: Biome information. `nil` if biome id is out of range.
  public func biome(withId id: Int) -> Biome? {
    return biomes[id]
  }
}
