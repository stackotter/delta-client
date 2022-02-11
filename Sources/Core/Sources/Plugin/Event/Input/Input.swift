import Foundation

public enum Input: Codable, CaseIterable {
  case moveForward
  case moveBackward
  case strafeLeft
  case strafeRight
  
  case jump
  case sneak
  case sprint
  
  case toggleDebugHUD
  
  public var humanReadableLabel: String {
    switch self {
      case .moveForward:
        return "Move forward"
      case .moveBackward:
        return "Move backward"
      case .strafeLeft:
        return "Strafe left"
      case .strafeRight:
        return "Strafe right"
        
      case .jump:
        return "Jump"
      case .sneak:
        return "Sneak"
      case .sprint:
        return "Sprint"
        
      case .toggleDebugHUD:
        return "Toggle debug HUD"
    }
  }
}
