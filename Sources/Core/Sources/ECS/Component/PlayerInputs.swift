import FirebladeECS

/// A component storing the player's current keyboard inputs.
public class PlayerInputs: Component {
  /// The player's current keyboard inputs.
  public var inputs: Set<Input> = []
  
  /// Creates an empty input state.
  public init() {}
}
