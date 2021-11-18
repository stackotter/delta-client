import Foundation

public enum Input: Codable, CaseIterable {
  case forward
  case backward
  case left
  case right
  case jump
  case shift
  case sprint
  
  public var humanReadableLabel: String {
    switch self {
    case .forward:
      return "Move forward"
    case .backward:
      return "Move backward"
    case .left:
      return "Strafe left"
    case .right:
      return "Strafe right"
    case .sprint:
      return "Sprint"
    case .jump:
      return "Jump"
    case .shift:
      return "Sneak"
    }
  }
}
