import FirebladeECS
import FirebladeMath

/// The game's input state.
public final class InputState: SingleComponent {
  /// The maximum number of ticks between consecutive inputs to count as a
  /// double tap.
  public static let maximumDoubleTapDelay = 6

  /// The newly pressed keys in the order that they were pressed. Only includes
  /// presses since last call to ``flushInputs()``.
  public private(set) var newlyPressed: [KeyPressEvent] = []
  /// The newly released keys in the order that they were released. Only includes
  /// releases since last call to ``flushInputs()``.
  public private(set) var newlyReleased: [KeyReleaseEvent] = []

  /// The currently pressed keys.
  public private(set) var keys: Set<Key> = []
  /// The currently pressed inputs.
  public private(set) var inputs: Set<Input> = []

  /// The current absolute mouse position relative to the play area's top left corner.
  public private(set) var mousePosition: Vec2f = Vec2f(0, 0)
  /// The mouse delta since the last call to ``resetMouseDelta()``.
  public private(set) var mouseDelta: Vec2f = Vec2f(0, 0)
  /// The position of the left thumbstick.
  public private(set) var leftThumbstick: Vec2f = Vec2f(0, 0)
  /// The position of the right thumbstick.
  public private(set) var rightThumbstick: Vec2f = Vec2f(0, 0)

  /// The time since forwards last changed from not pressed to pressed.
  public private(set) var ticksSinceForwardsPressed: Int = 0
  /// Whether the sprint was triggered by double tapping forwards.
  public private(set) var sprintIsFromDoubleTap: Bool = false

  /// The time since jump last changed from not pressed to pressed.
  public private(set) var ticksSinceJumpPressed: Int = 0

  /// Whether sprint is currently toggled. Only used if toggle sprint is enabled.
  public private(set) var isSprintToggled: Bool = false
  /// Whether sneak is currently toggled. Only used if toggle sneak is enabled.
  public private(set) var isSneakToggled: Bool = false

  /// Creates an empty input state.
  public init() {}

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

  /// Releases all inputs.
  public func releaseAll() {
    for key in keys {
      newlyReleased.append(KeyReleaseEvent(key: key, input: nil))
    }

    for input in inputs {
      print("Releasing \(input)")
      newlyReleased.append(KeyReleaseEvent(key: nil, input: input))
    }

    newlyPressed = []
  }

  /// Clears ``newlyPressed`` and ``newlyReleased``.
  public func flushInputs() {
    newlyPressed = []
    newlyReleased = []
  }

  /// Updates the current mouse delta by adding the given delta.
  ///
  /// See ``Client/moveMouse(x:y:deltaX:deltaY:)`` for the reasoning behind
  /// having both absolute and relative parameters (it's currently necessary
  /// but could be fixed by cleaning up the input handling architecture).
  /// - Parameters:
  ///   - x: The absolute mouse x (relative to the play area's top left corner).
  ///   - y: The absolute mouse y (relative to the play area's top left corner).
  ///   - deltaX: The change in mouse x.
  ///   - deltaY: The change in mouse y.
  public func moveMouse(x: Float, y: Float, deltaX: Float, deltaY: Float) {
    mouseDelta += Vec2f(deltaX, deltaY)
    mousePosition = Vec2f(x, y)
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
  func tick(_ isInputSuppressed: [Bool], _ eventBus: EventBus, _ configuration: ClientConfiguration) {
    assert(isInputSuppressed.count == newlyPressed.count, "`isInputSuppressed` should be the same length as `newlyPressed`")

    ticksSinceForwardsPressed += 1
    ticksSinceJumpPressed += 1

    // Reset toggles if they're disabled
    if (!configuration.toggleSprint && isSprintToggled) {
      inputs.remove(.sprint)
      isSprintToggled = false
    }
    if (!configuration.toggleSneak && isSneakToggled) {
      inputs.remove(.sneak)
      isSneakToggled = false
    }

    for (var event, suppressInput) in zip(newlyPressed, isInputSuppressed) {
      if suppressInput {
        event.input = nil
      }

      // Detect double pressing forwards (to activate sprint).
      if event.input == .moveForward && !inputs.contains(.moveForward) {
        // If the forwards key has been pressed within 6 ticks, press sprint.
        if !inputs.contains(.sprint) && ticksSinceForwardsPressed <= Self.maximumDoubleTapDelay {
          inputs.insert(.sprint)

          // Mark the sprint input for removal once forwards is pressed.
          sprintIsFromDoubleTap = true
        }
        ticksSinceForwardsPressed = 0
      }

      // Detect double pressing jump (to fly).
      if event.input == .jump && !inputs.contains(.jump) {
        if ticksSinceJumpPressed <= Self.maximumDoubleTapDelay {
          inputs.insert(.fly)
        }
        ticksSinceJumpPressed = 0
      }

      // Make sure that sprint isn't removed when forwards is released if it was pressed by the user.
      if event.input == .sprint {
        sprintIsFromDoubleTap = false
      }

      eventBus.dispatch(event)

      if let key = event.key {
        keys.insert(key)
      }

      if let input = event.input {
        // Toggle sprint if enabled
        if configuration.toggleSprint && input == .sprint {
          isSprintToggled = !isSprintToggled
          if !isSprintToggled {
            inputs.remove(input)
            continue
          }
        }

        // Toggle sneak if enabled
        if configuration.toggleSneak && input == .sneak {
          isSneakToggled = !isSneakToggled
          if !isSneakToggled {
            inputs.remove(input)
            continue
          }
        }
        
        inputs.insert(input)
      }
    }

    for event in newlyReleased {
      // Remove sprint if the forwards key is released and the sprint came from a double tap.
      if event.input == .moveForward && sprintIsFromDoubleTap {
        inputs.remove(.sprint)
      }
      
      // TODO: The release event of any inputs that were suppressed should probably also be suppressed
      eventBus.dispatch(event)

      // Don't remove sprint or sneak if toggling is enabled
      if (event.input == .sprint && configuration.toggleSprint) || (event.input == .sneak && configuration.toggleSneak) {
        continue
      }

      if let key = event.key {
        keys.remove(key)
      }
      if let input = event.input {
        inputs.remove(input)
      }
    }

    flushInputs()

    // `fly` is a synthetic input and is always immediately released.
    if inputs.contains(.fly) {
      release(key: nil, input: .fly)
    }
  }
}
