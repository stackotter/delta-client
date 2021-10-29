import Foundation
import DeltaCore

enum LoadingState {
  case loading
  case loadingWithMessage(String)
  case error(String)
  case done(LoadedResources)
}
