import FirebladeECS
import simd

/// The game's input state.
public final class InputState: SingleComponent {
  // MARK: Public properties

  /// The newly pressed keys in the order that they were pressed. Only includes presses since last
  /// call to ``flushInputs()``.
  public private(set) var newlyPressed: [KeyPressEvent] = []
  /// The newly released keys in the order that they were released. Only includes releases since
  /// last call to ``flushInputs()``.
  public private(set) var newlyReleased: [KeyReleaseEvent] = []

  /// The currently pressed keys.
  public private(set) var keys: Set<Key> = []
  /// The currently pressed inputs.
  public private(set) var inputs: Set<Input> = []

  /// The mouse delta since the last call to ``resetMouseDelta()``.
  public private(set) var mouseDelta: SIMD2<Float> = SIMD2(0, 0)

  // MARK: Init

  /// Creates an empty input state.
  public init() {}

  // MARK: Public methods

  /// Presses an input.
  /// - Parameters:
  ///   - key: The key pressed.
  ///   - input: The input bound to the pressed key if any.
  ///   - characters: Characters associated with the input.
  public func press(key: Key?, input: Input?, characters: [Character] = []) {
    newlyPressed.append(KeyPressEvent(key: key, input: input, characters: characters))
  }

  /// Releases an input.
  /// - Parameters:
  ///   - key: The key released.
  ///   - input: The input released.
  public func release(key: Key?, input: Input?) {
    newlyReleased.append(KeyReleaseEvent(key: key, input: input))
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

  /// Ticks the input state by flushing ``newlyPressed`` into ``keys`` and ``inputs``, and clearing
  /// ``newlyReleased``. Also emits events to the given ``EventBus``.
  func tick(_ isInputSuppressed: [Bool], _ eventBus: EventBus) {
    assert(isInputSuppressed.count == newlyPressed.count, "`isInputSuppressed` should be the same length as `newlyPressed`")
    for (var event, suppressInput) in zip(newlyPressed, isInputSuppressed) {
      if suppressInput {
        event.input = nil
      }

      eventBus.dispatch(event)

      if let key = event.key {
        keys.insert(key)
      }
      if let input = event.input {
        inputs.insert(input)
      }
    }

    for event in newlyReleased {
      // TODO: The release event of any inputs that were suppressed should probably also be suppressed
      eventBus.dispatch(event)

      if let key = event.key {
        keys.remove(key)
      }
      if let input = event.input {
        inputs.remove(input)
      }
    }

    flushInputs()
  }
}
