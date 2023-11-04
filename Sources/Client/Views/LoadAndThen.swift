import SwiftUI
import Combine
import DeltaCore

struct LoadResult {
  var storageDirectory: StorageDirectory
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
  var content: (StorageDirectory, Box<ResourcePack>, PluginEnvironment) -> Child

  init(
    _ hasLoaded: Binding<Bool>,
    content: @escaping (StorageDirectory, Box<ResourcePack>, PluginEnvironment) -> Child
  ) {
    self._hasLoaded = hasLoaded
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

    guard let storage = StorageDirectory.platformDefault else {
      throw RichError("Failed to get storage directory")
    }
    try storage.ensureCreated()

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
        storageDirectory: storage,
        resourcePack: Box(resourcePack),
        pluginEnvironment: pluginEnvironment
      )
      hasLoaded = true
    }
  }

  var body: some View {
    VStack {
      if let loadResult = loadResult {
        content(loadResult.storageDirectory, loadResult.resourcePack, loadResult.pluginEnvironment)
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
