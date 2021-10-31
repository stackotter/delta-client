import Foundation
import SwiftUI

enum Colors {
  case primaryDarkGray, secondaryDarkGray
  case warningYellow
  
  var color: Color {
    switch self {
    case .primaryDarkGray: return Color(red: 32/255, green: 32/255, blue: 32/255)
    case .secondaryDarkGray: return Color(red: 83/255, green: 83/255, blue: 83/255)
    case .warningYellow: return Color(red: 231/255, green: 241/255, blue: 89/255)
    }
  }
}
