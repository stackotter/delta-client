import Dispatch
import Foundation
import SwiftCrossUI
import DeltaCore

@main
struct DeltaClientApp: App {
  enum DeltaClientState {
    case loading(message: String)
    case selectServer(ResourcePack)
    case play(ServerDescriptor, ResourcePack)
  }

  class StateStorage: Observable {
    @Observed var state = DeltaClientState.loading(message: "Loading")
  }

  var identifier = "dev.stackotter.DeltaClientApp"
  var windowProperties = WindowProperties(title: "Delta Client", defaultSize: .init(400, 200))

  var state = StateStorage()

  public init() {
    load()
  }

  func load() {
    DispatchQueue(label: "loading").async {
      let assetsDirectory = URL(fileURLWithPath: "assets")
      let registryDirectory = URL(fileURLWithPath: "registry")
      let cacheDirectory = URL(fileURLWithPath: "cache")

      do {
        // Download vanilla assets if they haven't already been downloaded
        if !StorageManager.directoryExists(at: assetsDirectory) {
          loading("Downloading assets")
          try ResourcePack.downloadVanillaAssets(forVersion: Constants.versionString, to: assetsDirectory) { progress, message in
            loading(message)
          }
        }

        // Load registries
        loading("Loading registries")
        try RegistryStore.populateShared(registryDirectory) { progress, message in
          loading(message)
        }

        // Load resource pack and cache it if necessary
        loading("Loading resource pack")
        let packCache = cacheDirectory.appendingPathComponent("vanilla.rpcache/")
        var cacheExists = StorageManager.directoryExists(at: packCache)
        let resourcePack = try ResourcePack.load(
          from: assetsDirectory,
          cacheDirectory: cacheExists ? packCache : nil
        )
        cacheExists = StorageManager.directoryExists(at: packCache)
        if !cacheExists {
          do {
            try resourcePack.cache(to: packCache)
          } catch {
            log.warning("Failed to cache vanilla resource pack")
          }
        }

        self.state.state = .selectServer(resourcePack)
      } catch {
        loading("Failed to load: \(error.localizedDescription) (\(error))")
      }
    }
  }

  func loading(_ message: String) {
    self.state.state = .loading(message: message)
  }

  var body: some ViewContent {
    VStack {
      switch state.state {
        case .loading(let message):
          Text(message)
        case .selectServer(let resourcePack):
          ServerListView { server in
            state.state = .play(server, resourcePack)
          }
        case .play(let server, let resourcePack):
          GameView(server, resourcePack) {
            state.state = .selectServer(resourcePack)
          }
      }
    }.padding(10)
  }

  /// Logs a fatal error and then fatal errors.
  static func fatal(_ message: String) -> Never {
    log.critical(message)
    fatalError(message)
  }
}
