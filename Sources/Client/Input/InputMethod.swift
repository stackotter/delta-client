enum InputMethod: Hashable {
  case keyboardAndMouse
  case controller(Controller)    

  var name: String {
    switch self {
      case .keyboardAndMouse:
        return "Keyboard and mouse"
      case let .controller(controller):
        return controller.name
    }
  }

  var detail: String? {
    switch self {
      case .keyboardAndMouse:
        return nil
      case let .controller(controller):
        let player = controller.gcController.playerIndex
        if player != .indexUnset {
          return "\(player.rawValue)"
        } else {
          return nil
        }
    }
  }

  var isController: Bool {
    switch self {
      case .keyboardAndMouse:
        return false
      case .controller:
        return true
    }
  }

  var controller: Controller? {
    switch self {
      case .keyboardAndMouse:
        return nil
      case let .controller(controller):
        return controller
    }
  }
}
