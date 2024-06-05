import Dispatch
import Foundation
import SwiftCrossUI
import DeltaCore

@main
struct DeltaClientApp: App {
  enum DeltaClientState {
    case loading(message: String)
    case selectServer
    case settings
    case play(ServerDescriptor, ResourcePack)
  }

  class StateStorage: Observable {
    @Observed var state = DeltaClientState.loading(message: "Loading")
    var resourcePack: ResourcePack?
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
          try ResourcePack.downloadVanillaAssets(
            forVersion: Constants.versionString,
            to: assetsDirectory,
            progress: nil
          )
        }

        // Load registries
        loading("Loading registries")
        try RegistryStore.populateShared(registryDirectory, progress: nil)

        // Load resource pack and cache it if necessary
        loading("Loading resource pack")
        let packCache = cacheDirectory.appendingPathComponent("vanilla.rpcache/")
        var cacheExists = StorageManager.directoryExists(at: packCache)
        state.resourcePack = try ResourcePack.load(
          from: assetsDirectory,
          cacheDirectory: cacheExists ? packCache : nil
        )
        cacheExists = StorageManager.directoryExists(at: packCache)
        if !cacheExists {
          do {
            if let resourcePack = state.resourcePack {
              try resourcePack.cache(to: packCache)
            }
          } catch {
            log.warning("Failed to cache vanilla resource pack")
          }
        }

        self.state.state = .selectServer
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
        case .selectServer:
          ServerListView { server in
            if let resourcePack = state.resourcePack {
              state.state = .play(server, resourcePack)
            }
          } openSettings: {
            state.state = .settings
          }
        case .settings:
          SettingsView {
            state.state = .selectServer
          }
        case .play(let server, let resourcePack):
          GameView(server, resourcePack) {
            state.state = .selectServer
          }
      }
    }.padding(10)
  }
}
