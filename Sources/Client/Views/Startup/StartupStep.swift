import Foundation
import DeltaCore

/// All major startup steps in order.
enum StartupStep: CaseIterable, TaskStep {
  case loadPlugins
  case downloadAssets
  case loadRegistries
  case loadResourcePacks

  /// The task description.
  var message: String {
    switch self {
      case .loadPlugins: return "Loading plugins"
      case .downloadAssets: return "Downloading vanilla assets (might take a little while)"
      case .loadRegistries: return "Loading registries"
      case .loadResourcePacks: return "Loading resource pack"
    }
  }

  /// The task's expected duration relative to the total.
  var relativeDuration: Double {
    switch self {
      case .loadPlugins: return 3
      case .downloadAssets: return 15
      case .loadRegistries: return 3
      case .loadResourcePacks: return 15
    }
  }
}
