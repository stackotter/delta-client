import SwiftUI

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

struct SelectInputMethodAndThen<Content: View>: View {
  @EnvironmentObject var controllerHub: ControllerHub

  var excludedMethods: [InputMethod]
  var content: (InputMethod) -> Content
  var cancellationHandler: () -> Void

  var inputMethods: [InputMethod] {
    [.keyboardAndMouse] + controllerHub.controllers.map(InputMethod.controller)
  }

  init(
    excluding excludedMethods: [InputMethod] = [],
    @ViewBuilder content: @escaping (InputMethod) -> Content,
    cancellationHandler: @escaping () -> Void
  ) {
    self.excludedMethods = excludedMethods
    self.content = content
    self.cancellationHandler = cancellationHandler
  }

  var body: some View {
    SelectOption(
      from: inputMethods,
      excluding: excludedMethods,
      title: "Select an input method"
    ) { method in
      HStack {
        Text(method.name)
        if let detail = method.detail {
          Text(detail)
            .foregroundColor(.gray)
        }
      }
    } andThen: { method in
      content(method)
    } cancellationHandler: {
      cancellationHandler()
    }
  }
}
