import Foundation
import SwiftUI


// MARK: - PopupObject


struct PopupObject {
  let title: String
  let subtitle: String
  private(set) var image: Image? = nil
  typealias Action = (confirm: (() -> Void), cancel: () -> Void)
  private(set) var action: Action? = nil
}


// MARK: - PopupState


enum PopupState {
  case shown(PopupObject), hidden
}
