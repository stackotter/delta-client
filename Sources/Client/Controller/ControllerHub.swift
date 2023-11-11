import GameController

class ControllerHub: ObservableObject {
  var connectedControllers: [Controller] = []

  init() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(updateControllers),
      name: NSNotification.Name.GCControllerDidConnect,
      object: nil
    )

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(updateControllers),
      name: NSNotification.Name.GCControllerDidDisconnect,
      object: nil
    )

    // Check for controllers that might already be connected.
    updateControllers()
  }

  func isConnected(_ controller: GCController) -> Bool {
    connectedControllers.contains { connectedController in
      connectedController.controller == controller
    }
  }

  @objc private func updateControllers() {
    let currentControllers = GCController.controllers()

    // Handle newly connected controllers
    for controller in currentControllers {
      guard
        !isConnected(controller),
        let connectedController = Controller(for: controller)
      else {
        continue
      }

      connectedControllers.append(connectedController)
      log.info("Connected \(controller.productCategory) controller")
    }

    // Handle newly disconnected controllers
    for (i, controller) in connectedControllers.enumerated() {
      if !currentControllers.contains(controller.controller) {
        connectedControllers.remove(at: i)
      }
    }
  }
}
