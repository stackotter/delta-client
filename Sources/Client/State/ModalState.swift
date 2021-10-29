import Foundation

enum ModalState {
  case none
  case warning(String)
  case error(String, safeState: AppState?)
}
