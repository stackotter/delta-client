import Foundation

extension ResourcePack {
  /// A namespace of resources.
  public struct Resources {
    public static let blockTextureCacheFileName = "BlockTexturePalette.bin"
    public static let itemTextureCacheFileName = "ItemTexturePalette.bin"
    public static let entityTextureCacheFileName = "EntityTexturePalette.bin"
    public static let guiTextureCacheFileName = "GUITexturePalette.bin"
    public static let environmentTextureCacheFileName = "EnvironmentTexturePalette.bin"
    /// The palette holding block textures.
    public var blockTexturePalette = TexturePalette()
    /// The palette holding block models.
    public var blockModelPalette = BlockModelPalette()
    /// The palette holding item textures.
    public var itemTexturePalette = TexturePalette()
    /// The palette holding item models.
    public var itemModelPalette = ItemModelPalette()
    /// The palette holding entity textures.
    public var entityTexturePalette = TexturePalette()
    /// The palette holding entity models.
    public var entityModelPalette = EntityModelPalette()
    /// The GUI texture palette.
    public var guiTexturePalette = TexturePalette()
    /// The environment texture palette (containing textures for the sun and moon etc.).
    public var environmentTexturePalette = TexturePalette()
    /// The locales.
    public var locales: [String: MinecraftLocale] = [:]
    /// The colors of biomes.
    public var biomeColors = BiomeColors()
    /// The fonts.
    public var fontPalette = FontPalette()

    /// Creates a new empty namespace of resources.
    public init() {}

    public func cache(to cacheDirectory: URL) throws {
      // Cache models
      try blockModelPalette.cache(toDirectory: cacheDirectory)
      try itemModelPalette.cache(toDirectory: cacheDirectory)

      // Cache textures
      try blockTexturePalette.cache(
        to: cacheDirectory.appendingPathComponent(Self.blockTextureCacheFileName)
      )
      try itemTexturePalette.cache(
        to: cacheDirectory.appendingPathComponent(Self.itemTextureCacheFileName)
      )
      try entityTexturePalette.cache(
        to: cacheDirectory.appendingPathComponent(Self.entityTextureCacheFileName)
      )
      try guiTexturePalette.cache(
        to: cacheDirectory.appendingPathComponent(Self.guiTextureCacheFileName)
      )
      try environmentTexturePalette.cache(
        to: cacheDirectory.appendingPathComponent(Self.environmentTextureCacheFileName)
      )

      // Cache fonts
      try fontPalette.cache(toDirectory: cacheDirectory)
    }

    public static func loadCached(from cacheDirectory: URL) throws -> ResourcePack.Resources {
      var resources = Resources()
      resources.blockTexturePalette = try TexturePalette.loadCached(
        from: cacheDirectory.appendingPathComponent(Self.blockTextureCacheFileName)
      )
      resources.itemTexturePalette = try TexturePalette.loadCached(
        from: cacheDirectory.appendingPathComponent(Self.itemTextureCacheFileName)
      )
      resources.entityTexturePalette = try TexturePalette.loadCached(
        from: cacheDirectory.appendingPathComponent(Self.entityTextureCacheFileName)
      )
      resources.guiTexturePalette = try TexturePalette.loadCached(
        from: cacheDirectory.appendingPathComponent(Self.guiTextureCacheFileName)
      )
      resources.environmentTexturePalette = try TexturePalette.loadCached(
        from: cacheDirectory.appendingPathComponent(Self.environmentTextureCacheFileName)
      )
      resources.blockModelPalette = try BlockModelPalette.loadCached(fromDirectory: cacheDirectory)
      resources.itemModelPalette = try ItemModelPalette.loadCached(fromDirectory: cacheDirectory)
      resources.fontPalette = try FontPalette.loadCached(fromDirectory: cacheDirectory)
      return resources
    }

    /// Loads the resources in the given directory and gives them the specified namespace.
    public static func load(
      from directory: URL,
      inNamespace namespace: String,
      cacheDirectory: URL?
    ) throws -> ResourcePack.Resources {
      log.debug("Loading resources from '\(namespace)' namespace")

      var resources = Resources()
      var loadedCachedResources = false
      if let cacheDirectory = cacheDirectory,
        FileManager.default.directoryExists(at: cacheDirectory)
      {
        do {
          resources = try loadCached(from: cacheDirectory)
          loadedCachedResources = true
        } catch {
          do {
            try FileManager.default.removeItem(at: cacheDirectory.deletingLastPathComponent())
          } catch {
            log.warning("Failed to delete invalid resource caches")
          }
        }
      }

      let textureDirectory = directory.appendingPathComponent("textures")
      let modelDirectory = directory.appendingPathComponent("models")

      // Load biome colors
      let colorMapDirectory = textureDirectory.appendingPathComponent("colormap")
      if FileManager.default.directoryExists(at: colorMapDirectory) {
        log.debug("Loading biome colors")
        resources.biomeColors = try BiomeColors(from: colorMapDirectory)
      }

      // Load locales
      let localeDirectory = directory.appendingPathComponent("lang")
      if FileManager.default.directoryExists(at: localeDirectory) {
        log.debug("Loading locales")
        let contents = try FileManager.default.contentsOfDirectory(
          at: localeDirectory, includingPropertiesForKeys: nil)
        for file in contents where file.pathExtension == "json" {
          let locale = try MinecraftLocale(localeFile: file)
          resources.locales[file.deletingPathExtension().lastPathComponent] = locale
        }
      }

      // Load entity models
      let entityModelDirectory = modelDirectory.appendingPathComponent("entity")
      if FileManager.default.directoryExists(at: entityModelDirectory) {
        log.debug("Loading entity models")
        resources.entityModelPalette = try EntityModelPalette.load(
          from: entityModelDirectory,
          namespace: namespace
        )
      }

      if !loadedCachedResources {
        log.debug("Loading textures")

        // Load block textures
        let blockTextureDirectory = textureDirectory.appendingPathComponent("block")
        if FileManager.default.directoryExists(at: blockTextureDirectory) {
          resources.blockTexturePalette = try TexturePalette.load(
            from: blockTextureDirectory,
            inNamespace: namespace,
            withType: "block"
          )
        }

        /// Load item textures
        let itemTextureDirectory = textureDirectory.appendingPathComponent("item")
        if FileManager.default.directoryExists(at: itemTextureDirectory) {
          resources.itemTexturePalette = try TexturePalette.load(
            from: itemTextureDirectory,
            inNamespace: namespace,
            withType: "item"
          )
        }

        /// Load entity textures
        // let entityTextureDirectory = textureDirectory.appendingPathComponent("entity")
        // if FileManager.default.directoryExists(at: entityTextureDirectory) {
        //   resources.entityTexturePalette = try TexturePalette.load(
        //     from: entityTextureDirectory,
        //     inNamespace: namespace,
        //     withType: "entity"
        //   )
        // }

        // Load GUI textures
        let guiTextureDirectory = textureDirectory.appendingPathComponent("gui")
        if FileManager.default.directoryExists(at: guiTextureDirectory) {
          resources.guiTexturePalette = try TexturePalette.load(
            from: guiTextureDirectory,
            inNamespace: namespace,
            withType: "gui",
            recursive: true,
            isAnimated: false
          )
        }

        // Load GUI textures
        let environmentTextureDirectory = textureDirectory.appendingPathComponent("environment")
        if FileManager.default.directoryExists(at: environmentTextureDirectory) {
          resources.environmentTexturePalette = try TexturePalette.load(
            from: environmentTextureDirectory,
            inNamespace: namespace,
            withType: "environment",
            isAnimated: false
          )
        }

        // Load block models
        let blockModelDirectory = modelDirectory.appendingPathComponent("block")
        if FileManager.default.directoryExists(at: blockModelDirectory) {
          log.debug("Loading block models")
          resources.blockModelPalette = try BlockModelPalette.load(
            from: blockModelDirectory,
            namespace: namespace,
            blockTexturePalette: resources.blockTexturePalette
          )
        }

        // Load item models
        let itemModelDirectory = modelDirectory.appendingPathComponent("item")
        if FileManager.default.directoryExists(at: itemModelDirectory) {
          log.debug("Loading item models")
          resources.itemModelPalette = try ItemModelPalette.load(
            from: itemModelDirectory,
            itemTexturePalette: resources.itemTexturePalette,
            blockTexturePalette: resources.blockTexturePalette,
            blockModelPalette: resources.blockModelPalette,
            namespace: namespace
          )
        }

        // Load fonts
        let fontDirectory = directory.appendingPathComponent("font")
        if FileManager.default.directoryExists(at: fontDirectory) {
          log.debug("Loading fonts")
          resources.fontPalette = try FontPalette.load(
            from: fontDirectory,
            namespaceDirectory: directory,
            textureDirectory: textureDirectory
          )
        }
      }

      return resources
    }
  }
}
