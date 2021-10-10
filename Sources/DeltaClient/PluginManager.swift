import Foundation
import DeltaCore

class PluginManager: ObservableObject {
  /// The errors that occured while loading plugins
  @Published var pluginErrors: Array<(pluginDirectoryName: String, error: Error)>
  let pluginEnvironment: PluginEnvironment
  private let path: URL
  
  private init(path: URL) {
    pluginErrors = []
    pluginEnvironment = PluginEnvironment()
	self.path = path
  }
  
  static let shared = PluginManager(path: StorageManager.default.absoluteFromRelative("Plugins"))
  
  private func discoverBundles() -> Array<URL> {
    do {
      return try StorageManager.default.contentsOfDirectory(
        at: path
      ).filter() { url in
        return url.pathExtension == "dpl"
      }
    } catch {
      return []
    }
  }
  
  /// Load plugins available in the Plugins directory
  func addPlugins() {
    if !StorageManager.default.directoryExists(at: path) {
      try? StorageManager.default.createDirectory(at: path)
    }
    for bundleURL in discoverBundles() {
      do {
        try pluginEnvironment.addPlugin(at: bundleURL)
      } catch let error {
        pluginErrors.append((pluginDirectoryName: bundleURL.lastPathComponent, error: error))
      }
    }
  }
}
