import Foundation

// MARK: - LoadingState


enum LoadingState {
  case none
  case loadingWithMessage(String)
  case done
}
