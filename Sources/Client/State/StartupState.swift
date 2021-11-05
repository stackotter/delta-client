import Foundation
import DeltaCore

enum StartupState {
  case loading
  case loadingWithMessage(String)
  case done(LoadedResources)
  case fatalError
}
