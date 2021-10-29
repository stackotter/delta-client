import Foundation
import SwiftUI

public protocol CustomHUDViewBuilder {
  func buildView(plugin: Plugin) -> AnyView
  var hudItemName: String { get }
}
