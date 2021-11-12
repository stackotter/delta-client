import Foundation

/// Holds static Minecraft data such as biomes, fluids and blocks. Delta Client populates it launch.
public struct Registry {
  public static var shared = Registry()
  
  public var blockRegistry = BlockRegistry()
  public var biomeRegistry = BiomeRegistry()
  public var fluidRegistry = FluidRegistry()
  public var entityRegistry = EntityRegistry()
  
  public init(
    blockRegistry: BlockRegistry = BlockRegistry(),
    biomeRegistry: BiomeRegistry = BiomeRegistry(),
    fluidRegistry: FluidRegistry = FluidRegistry(),
    entityRegistry: EntityRegistry = EntityRegistry()
  ) {
    self.blockRegistry = blockRegistry
    self.biomeRegistry = biomeRegistry
    self.fluidRegistry = fluidRegistry
    self.entityRegistry = entityRegistry
  }
  
  /// Populate the shared registry.
  /// - Parameter directory: Directory used for caching registries.
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
    let entitiesFile = directory.appendingPathComponent("entities.json")
    
    do {
      let decoder = JSONDecoder()
      log.info("Loading cached block registry")
      let blockRegistry = try decoder.decode(BlockRegistry.self, from: try Data(contentsOf: blocksFile))
      log.info("Loading cached biome registry")
      let biomeRegistry = try decoder.decode(BiomeRegistry.self, from: try Data(contentsOf: biomesFile))
      log.info("Loading cached fluid registry")
      let fluidRegistry = try decoder.decode(FluidRegistry.self, from: try Data(contentsOf: fluidsFile))
      log.info("Loading cached entity registry")
      let entityRegistry = try decoder.decode(EntityRegistry.self, from: try Data(contentsOf: entitiesFile))
      
      return Registry(
        blockRegistry: blockRegistry,
        biomeRegistry: biomeRegistry,
        fluidRegistry: fluidRegistry,
        entityRegistry: entityRegistry)
    } catch {
      log.warning("Failed to load cached registries")
      log.info("Downloading registries")
      let registry = try PixlyzerFormatter.downloadAndFormatRegistries(Constants.versionString)
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
      let encoder = JSONEncoder()
      log.info("Caching block registry")
      try encoder.encode(registry.blockRegistry).write(to: blocksFile)
      log.info("Caching biome registry")
      try encoder.encode(registry.biomeRegistry).write(to: biomesFile)
      log.info("Caching fluid registry")
      try encoder.encode(registry.fluidRegistry).write(to: fluidsFile)
      log.info("Caching entity registry")
      try encoder.encode(registry.entityRegistry).write(to: entitiesFile)
      return registry
    }
  }
}
