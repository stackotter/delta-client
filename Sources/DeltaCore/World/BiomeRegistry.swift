import Foundation

public enum BiomeError: LocalizedError {
  /// Failed to load biome data from pixlyzer data.
  case failedToLoadPixlyzerBiomes(Error)
}

/// Holds information about biomes.
public struct BiomeRegistry {
  /// All possible biomes, indexed by biome id.
  public var biomes: [Biome] = []
  
  /// Maps biome identifier to biome id.
  public var identifierToBiomeId: [Identifier: Int] = [:]
  
  // MARK: Init
  
  /// Creates an empty ``BiomeRegistry``.
  public init() { }
  
  /// Creates a populated ``BiomeRegistry``.
  public init(biomes: [Biome]) {
    self.biomes = biomes
    for (id, biome) in biomes.enumerated() {
      identifierToBiomeId[biome.identifier] = id
    }
  }
  
  // MARK: Access
  
  /// Get the id of the biome specified.
  /// - Parameter identifier: Biome identifier.
  /// - Returns: Biome id. `nil` if biome doesn't exist.
  public func biomeId(for identifier: Identifier) -> Int? {
    return identifierToBiomeId[identifier]
  }
  
  /// Get information about the biome specified.
  /// - Parameter identifier: Biome identifier.
  /// - Returns: Biome information. `nil` if biome doesn't exist.
  public func biome(for identifier: Identifier) -> Biome? {
    if let id = biomeId(for: identifier) {
      return biomes[id]
    } else {
      return nil
    }
  }
  
  /// Get information about the biome specified.
  /// - Parameter id: A biome id.
  /// - Returns: Biome information. `nil` if biome id is out of range.
  public func biome(withId id: Int) -> Biome? {
    if id < biomes.count {
      return biomes[id]
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
