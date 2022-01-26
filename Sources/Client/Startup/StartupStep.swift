import Foundation
import DeltaCore

/// All major startup steps in order.
enum StartupStep: CaseIterable, TaskStep {
  case loadPlugins
  case downloadAssets
  case loadRegistries
  case loadResourcePacks
  case finish
  
  /// The task description.
  var message: String {
    switch self {
      case .loadPlugins: return "Loading plugins"
      case .downloadAssets: return "Downloading vanilla assets (might take a little while)"
      case .loadRegistries: return "Loading registries"
      case .loadResourcePacks: return "Loading resource pack"
      case .finish: return "Starting"
    }
  }
  
  /// The task's expected duration relative to the total.
  var relativeDuration: Double {
    switch self {
      case .loadPlugins: return 3
      case .downloadAssets: return 10
      case .loadRegistries: return 8
      case .loadResourcePacks: return 5
      case .finish: return 1
    }
  }
}
