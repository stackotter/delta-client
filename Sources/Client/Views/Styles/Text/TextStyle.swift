import SwiftUI

protocol TextStyle {
  @ViewBuilder func makeBody(configuration: Text) -> Text
}

extension Text {
  @ViewBuilder func textStyle(_ textStyle: TextStyle) -> Text {
    textStyle.makeBody(configuration: self)
  }
}
