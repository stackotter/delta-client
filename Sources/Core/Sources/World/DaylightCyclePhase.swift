import FirebladeMath

// TODO: Figure out whether finer distinctions are required for any features
// (e.g. knowing whether it's noon).
/// A phase of the daylight cycle along with any important information about
/// that phase (e.g. sunrise color).
public enum DaylightCyclePhase {
  case sunrise(color: Vec4f)
  case day
  case sunset(color: Vec4f)
  case night

  /// Whether the phase is a sunrise or not.
  public var isSunrise: Bool {
    switch self {
      case .sunrise:
        return true
      case .day, .sunset, .night:
        return false
    }
  }

  /// Whether the phase is a sunset or not.
  public var isSunset: Bool {
    switch self {
      case .sunset:
        return true
      case .sunrise, .day, .night:
        return false
    }
  }
}
