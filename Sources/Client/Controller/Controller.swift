import GameController
import Combine

/// A control on a controller (a button, a thumbstick, a trigger, etc).
protocol Control {
  associatedtype Element: GCControllerElement

  mutating func update(with element: Element)
}

/// A game controller (e.g. a PlayStation 5 controller).
class Controller: ObservableObject {
  /// A display name for the controller.
  var name: String {
    var name = gcController.productCategory
    if gcController.playerIndex != GCControllerPlayerIndex.indexUnset {
      name = "\(name) (player \(gcController.playerIndex.rawValue))"
    }
    return name
  }

  /// The underlying controller getting wrapped. I usually wouldn't prefix
  /// a property like that to match its type, but ``ControllerHub`` was getting
  /// so confusing with the two different types of controllers both getting
  /// referred to as `controller` and `controller.controller` and stuff.
  let gcController: GCController

  /// A publisher for subscribing to controller input events.
  var eventPublisher: AnyPublisher<Event, Never> {
    eventSubject.eraseToAnyPublisher()
  }

  /// The states of all buttons, indexed by ``Button/rawValue``. Assumes that the
  /// raw values form a contiguous range starting from 0.
  private var buttonStates = Array(repeating: false, count: Button.allCases.count)
  /// The states of all thumbsticks, indexed by ``Thumbstick/rawValue``. Assumes that the
  /// raw values form a contiguous range starting from 0.
  private var thumbstickStates = Array(
    repeating: ThumbstickState(),
    count: Thumbstick.allCases.count
  )

  /// Private to prevent users from publishing their own events and messing things up.
  private var eventSubject = PassthroughSubject<Event, Never>()

  /// Wraps a controller to make it easily observable. Returns `nil` if the
  /// controller isn't supported (doesn't have an extended gamepad).
  init?(for gcController: GCController) {
    guard let pad = gcController.extendedGamepad else {
      return nil
    }

    self.gcController = gcController

    pad.valueChangedHandler = { [weak self] pad, element in
      guard let self = self else { return }

      // We could use `element` to skip buttons which haven't been updated,
      // but that wouldn't work for the dpad buttons, because in that case
      // the element is the dpad instead of the invidual dpad button that
      // changed.
      for button in Button.allCases {
        // Get the button's new state, skipping buttons which the controller doesn't have.
        let newState: Bool
        switch button.keyPath {
          case let .required(keyPath):
            newState = pad[keyPath: keyPath].isPressed
          case let .optional(keyPath):
            guard let buttonElement = pad[keyPath: keyPath] else {
              continue
            }
            newState = buttonElement.isPressed
        }

        // Some buttons set multiple updates when changing states because they're
        // analog (like the triggers on the PS5 controller), so we need to filter
        // those updates out.
        guard newState != buttonStates[button.rawValue] else {
          continue
        }

        buttonStates[button.rawValue] = newState
        if newState {
          eventSubject.send(.buttonPressed(button))
        } else {
          eventSubject.send(.buttonReleased(button))
        }
      }

      for thumbstick in Thumbstick.allCases {
        let thumbstickElement = pad[keyPath: thumbstick.keyPath]

        // Ignore updates which don't affect this thumbstick
        guard thumbstickElement == element else {
          continue
        }

        let x = thumbstickElement.xAxis.value
        let y = thumbstickElement.yAxis.value
        thumbstickStates[thumbstick.rawValue].x = x
        thumbstickStates[thumbstick.rawValue].y = y
        eventSubject.send(.thumbstickMoved(thumbstick, x: x, y: y))
      }
    }

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handlePossibleDisconnect),
      name: NSNotification.Name.GCControllerDidDisconnect,
      object: nil
    )
  }

  /// Due to how vague the NotificationCenter observation API is, we just know
  /// that *a* controller was disconnected. If it was this one, do something
  /// about it.
  @objc private func handlePossibleDisconnect() {
    guard !GCController.controllers().contains(gcController) else {
      // We survive another day, do nothing
      return
    }

    // TODO: Do something when a controller disconnects
  }
}

extension Controller {
  enum Event {
    /// A specific button was pressed.
    case buttonPressed(Button)
    /// A specific button was released.
    case buttonReleased(Button)
    /// The thumbstick moved to a new position `(x, y)`.
    case thumbstickMoved(Thumbstick, x: Float, y: Float)
  }

  /// `GCControllerButtonInput`s are sometimes optional, but we want to treat
  /// them all the same way so we need an enum.
  enum GCControllerButtonKeyPath {
    case required(KeyPath<GCExtendedGamepad, GCControllerButtonInput>)
    case optional(KeyPath<GCExtendedGamepad, GCControllerButtonInput?>)
  }

  /// A controller button (includes triggers, shoulders, thumbstick buttons, etc). The
  /// raw value is used as an index when storing buttons in arrays.
  enum Button: Int, CaseIterable {
    case leftTrigger
    case rightTrigger
    case leftShoulder
    case rightShoulder

    case leftThumbstickButton
    case rightThumbstickButton

    case buttonA
    case buttonB
    case buttonX
    case buttonY

    case dpadUp
    case dpadDown
    case dpadLeft
    case dpadRight

    var keyPath: GCControllerButtonKeyPath {
      switch self {
        case .leftTrigger:
          return .required(\.leftTrigger)
        case .rightTrigger:
          return .required(\.rightTrigger)
        case .leftShoulder:
          return .required(\.leftShoulder)
        case .rightShoulder:
          return .required(\.rightShoulder)
        case .leftThumbstickButton:
          return .optional(\.leftThumbstickButton)
        case .rightThumbstickButton:
          return .optional(\.rightThumbstickButton)
        case .buttonA:
          return .required(\.buttonA)
        case .buttonB:
          return .required(\.buttonB)
        case .buttonX:
          return .required(\.buttonX)
        case .buttonY:
          return .required(\.buttonY)
        case .dpadUp:
          return .required(\.dpad.up)
        case .dpadDown:
          return .required(\.dpad.down)
        case .dpadLeft:
          return .required(\.dpad.left)
        case .dpadRight:
          return .required(\.dpad.right)
      }
    }
  }

  /// A controller thumbstick (often called a joystick). The raw value is used as
  /// an index when storing thumbsticks in arrays.
  enum Thumbstick: Int, CaseIterable {
    case left
    case right

    var keyPath: KeyPath<GCExtendedGamepad, GCControllerDirectionPad> {
      switch self {
        case .left:
          return \.leftThumbstick
        case .right:
          return \.rightThumbstick
      }
    }
  }

  /// The current state of a thumbstick.
  struct ThumbstickState {
    var x: Float = 0
    var y: Float = 0
  }
}

extension Controller: Equatable {
  static func ==(_ lhs: Controller, _ rhs: Controller) -> Bool {
    lhs.gcController == rhs.gcController
  }
}
