import Foundation
import ZippyJSON

/// Holds static Minecraft data such as biomes, fluids and blocks. Delta Client populates it launch.
public struct RegistryStore {
  public static var shared = RegistryStore()
  
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
  
  /// Populate the shared registry store.
  /// - Parameter directory: Directory used for caching registries.
  public static func populateShared(_ directory: URL) throws {
    shared = try loadCached(directory)
  }
  
  /// Loads the registries cached in a directory. If any registries are missing, they're all redownloaded and cached.
  /// - Parameter directory: The directory containing the cached registries.
  /// - Returns: The loaded registry.
  public static func loadCached(_ directory: URL) throws -> RegistryStore {
    do {
      log.info("Loading cached block registry")
      let blockRegistry = try BlockRegistry.loadCached(from: directory)
      
      log.info("Loading cached biome registry")
      let biomeRegistry = try BiomeRegistry.loadCached(from: directory)
      
      log.info("Loading cached fluid registry")
      let fluidRegistry = try FluidRegistry.loadCached(from: directory)
      
      log.info("Loading cached entity registry")
      let entityRegistry = try EntityRegistry.loadCached(from: directory)
      
      return RegistryStore(
        blockRegistry: blockRegistry,
        biomeRegistry: biomeRegistry,
        fluidRegistry: fluidRegistry,
        entityRegistry: entityRegistry)
    } catch {
      log.warning("Failed to load cached registries; \(error.localizedDescription)")
      log.info("Downloading registries")
      
      let registry = try PixlyzerFormatter.downloadAndFormatRegistries(Constants.versionString)
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
      
      log.info("Caching block registry")
      try registry.blockRegistry.cache(to: directory)
      
      log.info("Caching biome registry")
      try registry.biomeRegistry.cache(to: directory)
      
      log.info("Caching fluid registry")
      try registry.fluidRegistry.cache(to: directory)
      
      log.info("Caching entity registry")
      try registry.entityRegistry.cache(to: directory)
      
      return registry
    }
  }
}
