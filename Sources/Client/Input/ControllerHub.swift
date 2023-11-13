import GameController
import DeltaCore

class ControllerHub: ObservableObject {
  @Published var controllers: [Controller] = []
  @Published var currentController: Controller?

  init() {
    // Register notification observers.
    observe(NSNotification.Name.GCControllerDidConnect)
    observe(NSNotification.Name.GCControllerDidDisconnect)
    observe(NSNotification.Name.GCControllerDidBecomeCurrent)
    observe(NSNotification.Name.GCControllerDidStopBeingCurrent)

    // Check for controllers that might already be connected.
    updateControllers()
  }

  /// Registers an observer to update all controllers when a given event occurs.
  private func observe(_ event: NSNotification.Name) {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(updateControllers),
      name: event,
      object: nil
    )
  }

  @objc private func updateControllers() {
    // If we jump to the main thread synchronously then some sort of internal GCController
    // lock never gets dropped and `GCController.current` causes a deadlock (strange).
    DispatchQueue.main.async {
      let gcControllers = GCController.controllers()

      // Handle newly connected controllers
      for gcController in gcControllers {
        guard
          !self.controllers.contains(where: { $0.gcController == gcController }),
          let controller = Controller(for: gcController)
        else {
          continue
        }

        self.controllers.append(controller)
        log.info("Connected \(controller.name) controller")
      }

      // Handle newly disconnected controllers
      for (i, controller) in self.controllers.enumerated() {
        if !gcControllers.contains(controller.gcController) {
          self.controllers.remove(at: i)
          log.info("Disconnected \(controller.name) controller")
        }
      }

      // Update the current controller (last used)
      var current: Controller? = nil
      for controller in self.controllers {
        if controller.gcController == GCController.current {
          current = controller
        }
      }

      if self.currentController != current {
        self.currentController = current
      }
    }
  }
}
