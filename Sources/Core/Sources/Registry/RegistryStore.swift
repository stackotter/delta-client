import Foundation

public enum RegistryStoreError: LocalizedError {
  case outDatedBlockRegistry

  public var errorDescription: String? {
    switch self {
      case .outDatedBlockRegistry:
        return "The block registry cache is outdated and must be regenerated."
    }
  }
}

/// Holds static Minecraft data such as biomes, fluids and blocks. Delta Client populates it launch.
public struct RegistryStore {
  /// The shared registry instance.
  public static var shared = RegistryStore() // TODO: Abolish shared registries

  public var blockRegistry = BlockRegistry()
  public var biomeRegistry = BiomeRegistry()
  public var fluidRegistry = FluidRegistry()
  public var entityRegistry = EntityRegistry()
  public var itemRegistry = ItemRegistry()

  /// Creates an empty registry store.
  public init() {}

  /// Creates a populated registry store.
  public init(
    blockRegistry: BlockRegistry,
    biomeRegistry: BiomeRegistry,
    fluidRegistry: FluidRegistry,
    entityRegistry: EntityRegistry,
    itemRegistry: ItemRegistry
  ) {
    self.blockRegistry = blockRegistry
    self.biomeRegistry = biomeRegistry
    self.fluidRegistry = fluidRegistry
    self.entityRegistry = entityRegistry
    self.itemRegistry = itemRegistry
  }

  /// Populate the shared registry store.
  /// - Parameters:
  ///   - directory: Directory used for caching registries.
  ///   - onProgress: Callback triggered whenever the operation progress is updated.
  public static func populateShared(_ directory: URL, _ onProgress: ((Double, String) -> Void)? = nil) throws {
    shared = try loadCached(directory, onProgress: onProgress)
  }

  /// Steps to be exectued during the `populateShared` process.
  private enum RegistryLoadingStep: CaseIterable, TaskStep {
    case loadBlock, loadBiome, loadFluid, loadEntity, loadItem
    case cacheBlock, cacheBiome, cacheFluid, cacheEntity, cacheItem

    /// Task progress in respect to the whole loading process
    public var relativeDuration: Double { 1 }

    /// The task description
    public var message: String {
      var prefix: String
      var identifier: String

      switch self {
        case .loadBlock, .loadBiome, .loadFluid, .loadEntity, .loadItem: prefix = "Loading cached"
        case .cacheBlock, .cacheBiome, .cacheFluid, .cacheEntity, .cacheItem: prefix = "Caching"
      }

      switch self {
        case .loadBlock, .cacheBlock: identifier = "block"
        case .loadBiome, .cacheBiome: identifier = "biome"
        case .loadFluid, .cacheFluid: identifier = "fluid"
        case .loadEntity, .cacheEntity: identifier = "entity"
        case .loadItem, .cacheItem: identifier = "item"
      }

      return "\(prefix) \(identifier) registry"
    }
  }

  /// Loads the registries cached in a directory. If any registries are missing, they're all redownloaded and cached.
  /// - Parameters:
  ///   - directory: The directory containing the cached registries.
  ///   - onProgress: Callback triggered whenever the operation progress is updated.
  /// - Returns: The loaded registry.
  public static func loadCached(
    _ directory: URL,
    onProgress: ((Double, String) -> Void)?
  ) throws -> RegistryStore {
    var progress = TaskProgress<RegistryLoadingStep>()

    func updateProgressState(step: RegistryLoadingStep) {
      progress.update(to: step)
      log.info(progress.message)
      onProgress?(progress.progress, progress.message)
    }

    do {
      updateProgressState(step: .loadBlock)
      let blockRegistry = try BlockRegistry.loadCached(fromDirectory: directory)

      updateProgressState(step: .loadBiome)
      let biomeRegistry = try BiomeRegistry.loadCached(fromDirectory: directory)

      updateProgressState(step: .loadFluid)
      let fluidRegistry = try FluidRegistry.loadCached(fromDirectory: directory)

      updateProgressState(step: .loadEntity)
      let entityRegistry = try EntityRegistry.loadCached(fromDirectory: directory)

      updateProgressState(step: .loadItem)
      let itemRegistry = try ItemRegistry.loadCached(fromDirectory: directory)

      return RegistryStore(
        blockRegistry: blockRegistry,
        biomeRegistry: biomeRegistry,
        fluidRegistry: fluidRegistry,
        entityRegistry: entityRegistry,
        itemRegistry: itemRegistry
      )
    } catch {
      log.info("Failed to load cached registries. Loading from Pixlyzer data")
      log.info("Downloading registries")

      let registry = try PixlyzerFormatter.downloadAndFormatRegistries(Constants.versionString)
      try FileManager.default.createDirectory(
        at: directory,
        withIntermediateDirectories: true,
        attributes: nil
      )

      updateProgressState(step: .cacheBlock)
      try registry.blockRegistry.cache(toDirectory: directory)

      updateProgressState(step: .cacheBiome)
      try registry.biomeRegistry.cache(toDirectory: directory)

      updateProgressState(step: .cacheFluid)
      try registry.fluidRegistry.cache(toDirectory: directory)

      updateProgressState(step: .cacheEntity)
      try registry.entityRegistry.cache(toDirectory: directory)

      updateProgressState(step: .cacheItem)
      try registry.itemRegistry.cache(toDirectory: directory)

      return registry
    }
  }
}
