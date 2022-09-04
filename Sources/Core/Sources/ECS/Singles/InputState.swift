import FirebladeECS
import simd

/// The game's input state.
public final class InputState: SingleComponent {
  // MARK: Public properties

  /// The inputs pressed since the last call to ``flushInputs()``.
  public var newlyPressed: Set<Input> = []
  /// Character representations of the keys pressed since last call to ``flushInputs()``.
  public var newlyPressedCharacters: [Character] = []
  /// The inputs pressed since the last call to ``flushInputs()``.
  public var newlyReleased: Set<Input> = []
  /// The currently pressed inputs.
  public var inputs: Set<Input> = []

  /// The mouse delta since the last call to ``resetMouseDelta()``.
  public var mouseDelta: SIMD2<Float> = SIMD2(0, 0)

  // MARK: Init

  /// Creates an empty input state.
  public init() {}

  // MARK: Public methods

  /// Presses an input.
  /// - Parameters:
  ///   - input: The input pressed if any is bound.
  ///   - characters: Characters associated with the input.
  public func press(_ input: Input?, _ characters: [Character]) {
    if let input = input {
      inputs.insert(input)
      newlyPressed.insert(input)
    }
    newlyPressedCharacters.append(contentsOf: characters)
  }

  /// Releases an input.
  /// - Parameter input: The input to release.
  public func release(_ input: Input) {
    inputs.remove(input)
    newlyReleased.insert(input)
  }

  /// Clears ``newlyPressed``, ``newlyPressedCharacters`` and ``newlyReleased``.
  public func flushInputs() {
    newlyPressed = []
    newlyReleased = []
    newlyPressedCharacters = []
  }

  /// Updates the current mouse delta by adding the given delta.
  /// - Parameters:
  ///   - deltaX: The change in mouse x.
  ///   - deltaY: The change in mouse y.
  public func moveMouse(_ deltaX: Float, _ deltaY: Float) {
    mouseDelta += SIMD2(deltaX, deltaY)
  }

  /// Resets the mouse delta to 0.
  public func resetMouseDelta() {
    mouseDelta = SIMD2(0, 0)
  }
}
