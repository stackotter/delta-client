/// An event that is triggered when the user presses or releases an input.
public enum InputEvent: Event {
  case press(Input)
  case release(Input)
}
