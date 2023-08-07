import FirebladeECS
import FirebladeMath

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
  public private(set) var mouseDelta: Vec2f = Vec2f(0, 0)
  /// The position of the left thumbstick.
  public private(set) var leftThumbstick: Vec2f = Vec2f(0, 0)
  /// The position of the right thumbstick.
  public private(set) var rightThumbstick: Vec2f = Vec2f(0, 0)

  /// The time since the last time the player pressed the forwards key.
  public private(set) var forwardsDownTime: Int = 0
    /// Whether the spring was triggered by a double tap
  public private(set) var sprintFromDoubleTap: Bool = false
  /// Counts the ticks
  public private(set) var tickCount: Int = 0


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
    mouseDelta += Vec2f(deltaX, deltaY)
  }

  /// Updates the current position of the left thumbstick.
  /// - Parameters:
  ///   - x: The x position.
  ///   - y: The y position.
  public func moveLeftThumbstick(_ x: Float, _ y: Float) {
    leftThumbstick = [x, y]
  }

  /// Updates the current position of the right thumbstick.
  /// - Parameters:
  ///   - x: The x position.
  ///   - y: The y position.
  public func moveRightThumbstick(_ x: Float, _ y: Float) {
    rightThumbstick = [x, y]
  }

  /// Resets the mouse delta to 0.
  public func resetMouseDelta() {
    mouseDelta = Vec2f(0, 0)
  }

  /// Ticks the input state by flushing ``newlyPressed`` into ``keys`` and ``inputs``, and clearing
  /// ``newlyReleased``. Also emits events to the given ``EventBus``.
  func tick(_ isInputSuppressed: [Bool], _ eventBus: EventBus) {
    //Iincrement the tick count
    tickCount += 1
    // Increment the time since the forwards key was pressed if it is currently pressed
    assert(isInputSuppressed.count == newlyPressed.count, "`isInputSuppressed` should be the same length as `newlyPressed`")
    for (var event, suppressInput) in zip(newlyPressed, isInputSuppressed) {
      if suppressInput {
        event.input = nil
      }
      // Test for forwards key
      if event.input == .moveForward {
        if !inputs.contains(.moveForward) {
          // If the forwards key has been released within 6 ticks, sprint
          if (forwardsDownTime + 6) >= tickCount {
            inputs.insert(.sprint)
          }
          sprintFromDoubleTap = true
        }
        forwardsDownTime = tickCount
      }

      if event.input == .sprint {
        sprintFromDoubleTap = false
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
      // Test for forwards key being released
      if event.input == .moveForward {
        if sprintFromDoubleTap {
          inputs.remove(.sprint)
        }
      }
      
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
