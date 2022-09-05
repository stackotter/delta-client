import Foundation

/// A player input. On a laptop or desktop, this represents a key press.
public enum Input: Codable, CaseIterable {
  case moveForward
  case moveBackward
  case strafeLeft
  case strafeRight
  case jump
  case sneak
  case sprint
  case toggleDebugHUD
  case changePerspective
  case performGPUFrameCapture
  case slot1
  case slot2
  case slot3
  case slot4
  case slot5
  case slot6
  case slot7
  case slot8
  case slot9
  case nextSlot
  case previousSlot
  case openChat

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
      case .changePerspective:
        return "Change Perspective"
      case .performGPUFrameCapture:
        return "Perform GPU trace"
      case .slot1:
        return "Slot 1"
      case .slot2:
        return "Slot 2"
      case .slot3:
        return "Slot 3"
      case .slot4:
        return "Slot 4"
      case .slot5:
        return "Slot 5"
      case .slot6:
        return "Slot 6"
      case .slot7:
        return "Slot 7"
      case .slot8:
        return "Slot 8"
      case .slot9:
        return "Slot 9"
      case .nextSlot:
        return "Next slot"
      case .previousSlot:
        return "Previous slot"
      case .openChat:
        return "Open chat"
    }
  }
}
