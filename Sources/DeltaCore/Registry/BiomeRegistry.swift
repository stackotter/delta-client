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
public struct BiomeRegistry {
  /// All biomes.
  public var biomes: [Biome] = []
  /// Used to index `biomes`. Maps a biome id to an index in `biomes`.
  private var biomeIdToIndex: [Int: Int] = [:]
  /// Maps biome identifier to an index in `biomes`.
  private var identifierToIndex: [Identifier: Int] = [:]
  
  // MARK: Init
  
  /// Creates an empty ``BiomeRegistry``.
  public init() { }
  
  /// Creates a populated ``BiomeRegistry``.
  public init(biomes: [Biome]) {
    self.biomes = biomes
    for (index, biome) in biomes.enumerated() {
      biomeIdToIndex[biome.id] = index
      identifierToIndex[biome.identifier] = index
    }
  }
  
  // MARK: Access
  
  /// Get information about the biome specified.
  /// - Parameter identifier: Biome identifier.
  /// - Returns: Biome information. `nil` if biome doesn't exist.
  public func biome(for identifier: Identifier) -> Biome? {
    if let index = identifierToIndex[identifier] {
      return biomes[index]
    } else {
      return nil
    }
  }
  
  /// Get information about the biome specified.
  /// - Parameter id: A biome id.
  /// - Returns: Biome information. `nil` if biome id is out of range.
  public func biome(withId id: Int) -> Biome? {
    if let index = biomeIdToIndex[id] {
      return biomes[index]
    } else {
      return nil
    }
  }
}

extension BiomeRegistry: PixlyzerRegistry {
  public static func load(from pixlyzerFile: URL) throws -> BiomeRegistry {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    
    let pixlyzerBiomes: [String: PixlyzerBiome]
    do {
      let data = try Data(contentsOf: pixlyzerFile)
      pixlyzerBiomes = try decoder.decode([String: PixlyzerBiome].self, from: data)
    } catch {
      throw BiomeError.failedToLoadPixlyzerBiomes(error)
    }
    
    do {
      let biomes = try pixlyzerBiomes.map { Biome(from: $0.value, identifier: try Identifier($0.key)) }
      return BiomeRegistry(biomes: biomes)
    } catch {
      throw BiomeError.failedToLoadPixlyzerBiomes(error)
    }
  }
  
  static func getDownloadURL(for version: String) -> URL {
    return URL(string: "https://gitlab.bixilon.de/bixilon/pixlyzer-data/-/raw/master/version/\(version)/biomes.min.json")!
  }
}
