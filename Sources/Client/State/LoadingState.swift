import Foundation
import DeltaCore

enum LoadingState {
  case loading
  case loadingWithMessage(String, progress: Double)
  case error(String)
  case done(LoadedResources)
}
