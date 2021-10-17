import Foundation

/// Holds static Minecraft data such as biomes, fluids and blocks. Delta Client populates at launch.
public struct Registry {
  public static var shared = Registry()
  
  // Shoutout to whoever made 'block', 'biome' and 'fluid' the same length. So satisfying!
  public var blockRegistry = BlockRegistry()
  public var biomeRegistry = BiomeRegistry()
  public var fluidRegistry = FluidRegistry()
  
  public static func populateShared(_ directory: URL) throws {
    shared = try loadCached(directory)
  }
  
  /// Loads the registries cached in a directory. If any registries are missing, they're all redownloaded and cached.
  /// - Parameter directory: The directory containing the cached registries.
  /// - Returns: The loaded registry.
  public static func loadCached(_ directory: URL) throws -> Registry {
    let blocksFile = directory.appendingPathComponent("blocks.json")
    let biomesFile = directory.appendingPathComponent("biomes.json")
    let fluidsFile = directory.appendingPathComponent("fluids.json")
    
    do {
      let decoder = JSONDecoder()
      let blockRegistry = try decoder.decode(BlockRegistry.self, from: try Data(contentsOf: blocksFile))
      let biomeRegistry = try decoder.decode(BiomeRegistry.self, from: try Data(contentsOf: biomesFile))
      let fluidRegistry = try decoder.decode(FluidRegistry.self, from: try Data(contentsOf: fluidsFile))
      
      return Registry(
        blockRegistry: blockRegistry,
        biomeRegistry: biomeRegistry,
        fluidRegistry: fluidRegistry)
    } catch {
      let registry = try PixlyzerFormatter.downloadAndFormatRegistries(Constants.versionString)
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
      let encoder = JSONEncoder()
      log.info("Caching block registry")
      try encoder.encode(registry.blockRegistry).write(to: blocksFile)
      log.info("Caching biome registry")
      try encoder.encode(registry.biomeRegistry).write(to: biomesFile)
      log.info("Caching fluid registry")
      try encoder.encode(registry.fluidRegistry).write(to: fluidsFile)
      return registry
    }
  }
}
