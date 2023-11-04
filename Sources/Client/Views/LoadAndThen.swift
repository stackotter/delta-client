import SwiftUI
import Combine
import DeltaCore

struct LoadResult {
  var resourcePack: Box<ResourcePack>
  var pluginEnvironment: PluginEnvironment
}

extension TaskProgress: ObservableObject {
  public var objectWillChange: ObservableObjectPublisher {
    let publisher = ObservableObjectPublisher()
    onChange { _ in
      ThreadUtil.runInMain {
        publisher.send()
      }
    }
    return publisher
  }
}

extension Box: ObservableObject {
  public var objectWillChange: ObservableObjectPublisher {
    ObservableObjectPublisher()
  }
}

struct LoadAndThen<Child: View>: View {
  @EnvironmentObject var modal: Modal

  @ObservedObject var startup = TaskProgress<StartupStep>()
  @State var loadResult: LoadResult?

  @Binding var hasLoaded: Bool
  @Binding var storage: StorageDirectory?
  let arguments: CommandLineArguments
  var content: (Box<ResourcePack>, PluginEnvironment) -> Child

  init(
    _ arguments: CommandLineArguments,
    _ hasLoaded: Binding<Bool>,
    _ storage: Binding<StorageDirectory?>,
    content: @escaping (Box<ResourcePack>, PluginEnvironment) -> Child
  ) {
    self.arguments = arguments
    _hasLoaded = hasLoaded
    _storage = storage
    self.content = content
  }

  func load() throws {
    var previousStep: StartupStep?
    startup.onChange { progress in
      if progress.currentStep != previousStep {
        let percentage = String(format: "%.01f", progress.progress * 100)
        log.info("\(progress.message) (\(percentage)%)")
      }

      previousStep = progress.currentStep
    }

    let stopwatch = Stopwatch()

    let config = ConfigManager.default.config

    guard var storage = StorageDirectory.platformDefault else {
      throw RichError("Failed to get storage directory")
    }
    try storage.ensureCreated()
    storage.pluginDirectoryOverride = arguments.pluginsDirectory
    self.storage = storage

    // Enable file logging as there isn't really a better place to put this. Despite
    // not being part of loading per-say, it needs to be enabled as early as possible
    // to be maximally useful, so we can't exactly wait till a better time.
    do {
      try enableFileLogger(loggingTo: storage.currentLogFile)
    } catch {
      modal.warning("Failed to enable file logger")
    }

    Task {
      await ConfigManager.default.refreshAccounts()
    }

    let pluginEnvironment = PluginEnvironment()
    startup.perform(.loadPlugins) {
      try pluginEnvironment.loadPlugins(
        from: storage.pluginDirectory,
        excluding: config.unloadedPlugins
      )
    } handleError: { error in
      modal.error("Error occurred during plugin loading, no plugins will be available: \(error)")
    }

    try startup.perform(.downloadAssets, if: !FileSystem.directoryExists(storage.assetDirectory)) { progress in
      try ResourcePack.downloadVanillaAssets(
        forVersion: Constants.versionString,
        to: storage.assetDirectory,
        progress: progress
      )
    }

    try startup.perform(.loadRegistries) { progress in
      try RegistryStore.populateShared(storage.registryDirectory, progress: progress)
    }

    // TODO: Track resource pack loading progress to improve loading screen granularity
    // Load resource pack and cache it if necessary
    let resourcePack = try startup.perform(.loadResourcePacks) {
      let packCache = storage.cache(forResourcePackNamed: "vanilla")
      let resourcePack = try ResourcePack.load(from: storage.assetDirectory, cacheDirectory: packCache)
      if !FileSystem.directoryExists(packCache) {
        do {
          try resourcePack.cache(to: packCache)
        } catch {
          modal.warning("Failed to cache vanilla resource pack")
        }
      }
      return resourcePack
    }

    log.info("Finished loading (\(stopwatch.elapsed))")

    ThreadUtil.runInMain {
      loadResult = LoadResult(
        resourcePack: Box(resourcePack),
        pluginEnvironment: pluginEnvironment
      )
      hasLoaded = true
    }
  }

  var body: some View {
    VStack {
      if let loadResult = loadResult {
        content(loadResult.resourcePack, loadResult.pluginEnvironment)
      } else {
        ProgressLoadingView(progress: startup.progress, message: startup.message)
      }
    }
    .onAppear {
      DispatchQueue(label: "app-loading").async {
        do {
          try load()
        } catch {
          modal.error(RichError("Failed to load.").becauseOf(error)) {
            Foundation.exit(1)
          }
        }
      }
    }
  }
}
