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
  /// - Parameters:
  ///   - directory: Directory used for caching registries.
  ///   - onProgress: Callback triggered whenever the operation progress is updated.
  public static func populateShared(_ directory: URL, _ onProgress: ((Double, String) -> Void)?) throws {
    shared = try loadCached(directory, onProgress: onProgress)
  }
  
  /// Steps to be exectued during the `populateShared` process.
  private enum RegistryLoadingStep: CaseIterable, TaskStep {
    case loadBlock, loadBiome, loadFluid, loadEntity
    case cacheBlock, cacheBiome, cacheFluid, cacheEntity
    
    /// Task progress in respect to the whole loading process
    public var relativeDuration: Double { 1 }
    
    /// The task description
    public var message: String {
      var prefix: String
      var identifier: String
      
      switch self {
        case .loadBlock, .loadBiome, .loadFluid, .loadEntity: prefix = "Loading cached"
        case .cacheBlock, .cacheBiome, .cacheFluid, .cacheEntity: prefix = "Caching"
      }
      
      switch self {
        case .loadBlock, .cacheBlock: identifier = "block"
        case .loadBiome, .cacheBiome: identifier = "biome"
        case .loadFluid, .cacheFluid: identifier = "fluid"
        case .loadEntity, .cacheEntity: identifier = "entity"
      }
      
      return "\(prefix) \(identifier) registry"
    }
  }
  
  /// Loads the registries cached in a directory. If any registries are missing, they're all redownloaded and cached.
  /// - Parameters:
  ///   - directory: The directory containing the cached registries.
  ///   - onProgress: Callback triggered whenever the operation progress is updated.
  /// - Returns: The loaded registry.
  public static func loadCached(_ directory: URL, onProgress: ((Double, String) -> Void)?) throws -> RegistryStore {
    var progress = TaskProgress<RegistryLoadingStep>()
    
    func updateProgressState(step: RegistryLoadingStep) {
      progress.update(to: step)
      log.info(progress.message)
      onProgress?(progress.progress, progress.message)
    }
    
    do {
      updateProgressState(step: .loadBlock)
      let blockRegistry = try BlockRegistry.loadCached(from: directory)
      
      updateProgressState(step: .loadBiome)
      let biomeRegistry = try BiomeRegistry.loadCached(from: directory)
      
      updateProgressState(step: .loadFluid)
      let fluidRegistry = try FluidRegistry.loadCached(from: directory)
      
      updateProgressState(step: .loadEntity)
      let entityRegistry = try EntityRegistry.loadCached(from: directory)
      
      return RegistryStore(
        blockRegistry: blockRegistry,
        biomeRegistry: biomeRegistry,
        fluidRegistry: fluidRegistry,
        entityRegistry: entityRegistry)
    } catch {
      log.warning("Failed to load cached registries; \(error)")
      log.info("Downloading registries")
      
      let registry = try PixlyzerFormatter.downloadAndFormatRegistries(Constants.versionString)
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
      
      updateProgressState(step: .cacheBlock)
      try registry.blockRegistry.cache(to: directory)
      
      updateProgressState(step: .cacheBiome)
      try registry.biomeRegistry.cache(to: directory)
      
      updateProgressState(step: .cacheFluid)
      try registry.fluidRegistry.cache(to: directory)
      
      updateProgressState(step: .cacheEntity)
      try registry.entityRegistry.cache(to: directory)
      
      return registry
    }
  }
}
