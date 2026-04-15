import Foundation
import ZIPFoundation

enum ResourcePackError: LocalizedError {
  /// The specified resource pack directory does not exist.
  case noSuchDirectory
  /// The resource pack's `pack.mcmeta` is invalid.
  case failedToReadMCMeta
  /// Failed to list the contents of a texture directory.
  case failedToEnumerateTextures
  /// Failed to figure out what namespaces are included in this resource pack.
  case failedToEnumerateNamespaces
  /// Failed to convert an image into a texture.
  case failedToLoadTexture(Identifier)
  /// Failed to read the image for the given texture from a file.
  case failedToReadTextureImage(URL)
  /// Failed to create a `CGDataProvider` for the given image file.
  case failedToCreateImageProvider(URL)
  /// Failed to download the specified client jar.
  case clientJarDownloadFailure
  /// Failed to extract assets from a client jar.
  case clientJarExtractionFailure
  /// Failed to copy the vanilla assets from the extracted client jar.
  case assetCopyFailure
  /// Failed to create a dummy pack.mcmeta for the downloaded vanilla assets.
  case failedToCreatePackMCMeta
  /// No client jar is available to download for the specified version.
  case noURLForVersion(String)
  /// Failed to decode a version manifest.
  case versionManifestFailure
  /// Failed to decode the versions manifest.
  case versionsManifestFailure
  /// Failed to download default JSON entity models (downloaded separately from the default
  /// vanilla resources).
  case failedToDownloadJSONEntityModels

  var errorDescription: String? {
    switch self {
      case .noSuchDirectory:
        return "The specified resource pack directory does not exist."
      case .failedToReadMCMeta:
        return "The resource pack's `pack.mcmeta` is invalid."
      case .failedToEnumerateTextures:
        return "Failed to list the contents of a texture directory."
      case .failedToEnumerateNamespaces:
        return "Failed to figure out what namespaces are included in this resource pack."
      case .failedToLoadTexture(let identifier):
        return
          "Failed to convert an image into a texture with identifier: `\(identifier.description)`."
      case .failedToReadTextureImage(let url):
        return """
          Failed to read the image for the given texture from a file.
          File URL: \(url.absoluteString)
          """
      case .failedToCreateImageProvider(let url):
        return """
          Failed to create a `CGDataProvider` for the given image file.
          File URL: \(url.absoluteString)
          """
      case .clientJarDownloadFailure:
        return "Failed to download the specified client jar."
      case .clientJarExtractionFailure:
        return "Failed to extract assets from a client jar."
      case .assetCopyFailure:
        return "Failed to copy the vanilla assets from the extracted client jar."
      case .failedToCreatePackMCMeta:
        return "Failed to create a dummy pack.mcmeta for the downloaded vanilla assets"
      case .noURLForVersion(let version):
        return "No client jar is available to download for version: \(version)."
      case .versionManifestFailure:
        return "Failed to decode a version manifest."
      case .versionsManifestFailure:
        return "Failed to decode the versions manifest."
      case .failedToDownloadJSONEntityModels:
        return "Failed to download default JSON entity models."
    }
  }
}

// TODO: Version resource pack caches so that we can easily invalidate outdated caches
//   when the format changes.
/// A resource pack.
public struct ResourcePack {
  /// The metadata of languages contained within this resource pack.
  public var languages: [String: PackMCMeta.Language]

  /// All resources contained in this resource pack, keyed by namespace.
  public var resources: [String: Resources] = [:] {
    didSet {
      vanillaResources = resources["minecraft"] ?? Resources()
    }
  }

  /// Resources in the 'minecraft' namespace.
  public private(set) var vanillaResources: Resources

  // MARK: Init

  /// Creates a resource pack with the given resources. Defaults to no resources.
  /// - Parameters:
  ///   - languages: The metadata of languages to include in the resource pack.
  ///   - resources: The resources contained in the pack, keyed by namespace.
  public init(
    languages: [String: ResourcePack.PackMCMeta.Language] = [:],
    resources: [String: ResourcePack.Resources] = [:]
  ) {
    self.languages = languages
    self.resources = resources
    self.vanillaResources = resources["minecraft"] ?? Resources()
  }

  // MARK: Access

  public func getBlockModel(for stateId: Int, at position: BlockPosition) -> BlockModel? {
    return vanillaResources.blockModelPalette.model(for: stateId, at: position)
  }

  public func getBlockTexturePalette() -> TexturePalette {
    return vanillaResources.blockTexturePalette
  }

  public func getDefaultLocale() -> MinecraftLocale {
    return vanillaResources.locales[Constants.locale] ?? MinecraftLocale()
  }

  // MARK: Loading

  /// Loads the resource pack in the given directory. ``RegistryStore/shared`` must be populated for this to work.
  ///
  /// If provided, cached resources are loaded from the given cache directory if present. To create a resource pack cache use ``cache(to:)``.
  /// Resource pack caches do not cache the whole pack yet, only the most resource intensive parts to load.
  public static func load(from directory: URL, cacheDirectory: URL?) throws -> ResourcePack {
    // Check resource pack exists
    guard FileManager.default.directoryExists(at: directory) else {
      throw ResourcePackError.noSuchDirectory
    }

    // Read pack.mcmeta
    let mcMetaFile = directory.appendingPathComponent("pack.mcmeta")
    let mcMeta = try readPackMCMeta(at: mcMetaFile)

    // Read resources from present namespaces
    guard
      let contents = try? FileManager.default.contentsOfDirectory(
        at: directory,
        includingPropertiesForKeys: nil,
        options: []
      )
    else {
      throw ResourcePackError.failedToEnumerateNamespaces
    }

    var namespacedResources: [String: ResourcePack.Resources] = [:]
    for directory in contents where FileManager.default.directoryExists(at: directory) {
      let namespace = directory.lastPathComponent
      let resources = try Resources.load(
        from: directory,
        inNamespace: namespace,
        cacheDirectory: cacheDirectory?.appendingPathComponent(namespace)
      )
      namespacedResources[namespace] = resources
    }

    // Create pack
    return ResourcePack(
      languages: mcMeta.languages ?? [:],
      resources: namespacedResources
    )
  }

  /// Reads a pack.mcmeta file.
  public static func readPackMCMeta(at mcMetaFile: URL) throws -> ResourcePack.PackMCMeta {
    let mcMeta: ResourcePack.PackMCMeta
    do {
      let data = try Data(contentsOf: mcMetaFile)
      mcMeta = try CustomJSONDecoder().decode(ResourcePack.PackMCMeta.self, from: data)
    } catch {
      throw ResourcePackError.failedToReadMCMeta.becauseOf(error)
    }

    return mcMeta
  }

  // MARK: Caching

  /// Caches the parts of the pack that are most resource intensive to process (such as block models).
  public func cache(to directory: URL) throws {
    for (namespace, resources) in resources {
      log.debug("Caching resources from '\(namespace)' namespace")
      let cacheDirectory = directory.appendingPathComponent(namespace)
      try FileManager.default.createDirectory(
        at: cacheDirectory,
        withIntermediateDirectories: true,
        attributes: nil
      )

      try resources.cache(to: cacheDirectory)
    }
  }

  // MARK: Download

  /// Tasks to be exectued during the `downloadVanillaAssets` process
  public enum DownloadStep: CaseIterable, TaskStep {
    case fetchManifest
    case downloadJar
    case extractJar
    case copyingAssets
    case downloadEntityModels
    case creatingMcmeta

    public var relativeDuration: Double { 1 }

    public var message: String {
      switch self {
        case .fetchManifest: return "Fetching version manifest"
        case .downloadJar: return "Downloading client jar"
        case .extractJar: return "Extracting client jar"
        case .copyingAssets: return "Copying assets"
        case .downloadEntityModels: return "Download entity models"
        case .creatingMcmeta: return "Creating pack.mcmeta"
      }
    }
  }

  /// Downloads the vanilla client and extracts its assets (textures, block models, etc.).
  public static func downloadVanillaAssets(
    forVersion version: String,
    to directory: URL,
    progress: TaskProgress<DownloadStep>? = nil
  ) throws {
    // Get the url for the client jar
    progress?.update(to: .fetchManifest)
    let versionManifest = try getVersionManifest(for: version)
    let clientJarURL = versionManifest.downloads.client.url

    // Download the client jar
    progress?.update(to: .downloadJar)
    let temporaryDirectory = FileManager.default.temporaryDirectory
    let clientJarTempFile = temporaryDirectory.appendingPathComponent("client.jar")
    do {
      let data = try RequestUtil.data(contentsOf: clientJarURL)
      try data.write(to: clientJarTempFile)
    } catch {
      throw ResourcePackError.clientJarDownloadFailure.becauseOf(error)
    }

    // Extract the contents of the client jar (jar files are just zip archives)
    progress?.update(to: .extractJar)
    let extractedClientJarDirectory =
      temporaryDirectory
      .appendingPathComponent("client", isDirectory: true)
    try? FileManager.default.removeItem(at: extractedClientJarDirectory)
    do {
      try FileManager.default.unzipItem(
        at: clientJarTempFile,
        to: extractedClientJarDirectory,
        skipCRC32: true
      )
    } catch {
      throw ResourcePackError.clientJarExtractionFailure.becauseOf(error)
    }

    // Copy the assets from the extracted client jar to application support
    progress?.update(to: .copyingAssets)
    do {
      try FileManager.default.copyItem(
        at: extractedClientJarDirectory.appendingPathComponent("assets"),
        to: directory
      )
    } catch {
      throw ResourcePackError.assetCopyFailure.becauseOf(error)
    }

    // Download default JSON entity models
    progress?.update(to: .downloadEntityModels)
    do {
      let entityModelsDirectory = directory.appendingPathComponent("minecraft/models/entity")
      try FileManager.default.createDirectory(
        at: entityModelsDirectory,
        withIntermediateDirectories: false
      )
      try EntityModelPalette.downloadJSONEntityModels(to: entityModelsDirectory)
    } catch {
      throw ResourcePackError.failedToDownloadJSONEntityModels.becauseOf(error)
    }

    // Create a default pack.mcmeta for it
    progress?.update(to: .creatingMcmeta)
    let contents = #"{"pack": {"pack_format": 5, "description": "The default vanilla assets"}}"#
    guard let data = contents.data(using: .utf8) else {
      throw ResourcePackError.failedToCreatePackMCMeta
    }

    do {
      try data.write(to: directory.appendingPathComponent("pack.mcmeta"))
    } catch {
      throw ResourcePackError.failedToCreatePackMCMeta.becauseOf(error)
    }
  }

  /// Get the manifest describing all versions.
  private static func getVersionsManifest() throws -> VersionsManifest {
    let versionsManifestURL = URL(
      string: "https://launchermeta.mojang.com/mc/game/version_manifest.json"
    )!

    let versionsManifest: VersionsManifest
    do {
      let data = try RequestUtil.data(contentsOf: versionsManifestURL)
      versionsManifest = try CustomJSONDecoder().decode(VersionsManifest.self, from: data)
    } catch {
      throw ResourcePackError.versionsManifestFailure.becauseOf(error)
    }

    return versionsManifest
  }

  /// Get the manifest for the specified version.
  private static func getVersionManifest(for versionString: String) throws -> VersionManifest {
    let versionURLs = try getVersionURLs()

    guard let versionURL = versionURLs[versionString] else {
      log.error("Failed to find manifest download url for version \(versionString)")
      throw ResourcePackError.noURLForVersion(versionString)
    }

    let versionManifest: VersionManifest
    do {
      let data = try RequestUtil.data(contentsOf: versionURL)
      versionManifest = try CustomJSONDecoder().decode(VersionManifest.self, from: data)
    } catch {
      throw ResourcePackError.versionManifestFailure.becauseOf(error)
    }

    return versionManifest
  }

  /// Returns a map from version name to the version's manifest url.
  private static func getVersionURLs() throws -> [String: URL] {
    let manifest = try getVersionsManifest()
    var urls: [String: URL] = [:]
    for version in manifest.versions {
      urls[version.id] = version.url
    }
    return urls
  }
}
