import Foundation

/// An error thrown by ``ChatComponent`` and related types.
public enum ChatComponentError: LocalizedError {
  case invalidChatComponentType
  
  public var errorDescription: String? {
    switch self {
      case .invalidChatComponentType:
        return "Invalid chat component type."
    }
  }
}
