import FirebladeECS
import simd

/// The game's input state.
public final class InputState: SingleComponent {
  // MARK: Public properties

  /// The inputs pressed since the last call to ``flushInputs()``.
  public var newlyPressed: Set<Input> = []
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
  /// - Parameter input: The input to press.
  public func press(_ input: Input) {
    inputs.insert(input)
    newlyPressed.insert(input)
  }

  /// Releases an input.
  /// - Parameter input: The input to release.
  public func release(_ input: Input) {
    inputs.remove(input)
    newlyReleased.insert(input)
  }

  /// Clears ``newlyPressed`` and ``newlyReleased``.
  public func flushInputs() {
    newlyPressed = []
    newlyReleased = []
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
