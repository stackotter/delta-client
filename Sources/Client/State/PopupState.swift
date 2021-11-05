import Foundation
import SwiftUI

// MARK: - PopupObject


struct PopupObject {
  typealias Action = (confirm: (() -> Void), cancel: () -> Void)
  
  let title: String
  let subtitle: String
  public let image: Image?
  public let action: Action?
  
  init(title: String, subtitle: String, image: Image? = nil, action: Action? = nil) {
    self.title = title
    self.subtitle = subtitle
    self.image = image
    self.action = action
  }
}


// MARK: - PopupState


enum PopupState {
  case shown(PopupObject), hidden
}
