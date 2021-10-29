import Foundation

/// An error related to plugin loading.
public enum PluginLoadingError: LocalizedError {
  /// Failed to open the plugin's dylib (the part containing the plugin's functionality).
  case failedToOpenDylib(String?)
  /// The plugin does not contain a `@_cdecl`'d function called `buildPlugin`.
  case missingBuilderFunction
  /// A plugin with the same identifier is already loaded.
  case alreadyLoaded
  /// The plugin's manifest file is invalid.
  case invalidManifest(Error)
  
  public var errorDescription: String? {
    switch self {
    case let .failedToOpenDylib(reason):
      return "Failed to open the plugin's dynamic library: \(reason ?? "(no reason provided)")"
    case .missingBuilderFunction:
      return "Builder function not found (the plugin may be incorrectly built or corrupted)"
    case .alreadyLoaded:
      return "A plugin with the same identifier is already loaded"
    case let .invalidManifest(error):
      return "The plugin's manifest file is invalid: \(error)"
    }
  }
}
