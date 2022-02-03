import Foundation

/// A input action event.
public enum InputEvent: Event {
  case press(Input)
  case release(Input)
}
