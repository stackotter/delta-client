import SwiftUI
import Combine

struct WithCurrentController<Content: View>: View {
  @EnvironmentObject var controllerHub: ControllerHub

  @State var cancellable: AnyCancellable?

  var content: (Controller?) -> Content

  private var onButtonPress: ((Controller.Button) -> Void)?
  private var onButtonRelease: ((Controller.Button) -> Void)?
  private var onThumbstickMove: ((Controller.Thumbstick, _ x: Float, _ y: Float) -> Void)?

  init(@ViewBuilder _ content: @escaping (Controller?) -> Content) {
    self.content = content
  }

  init(@ViewBuilder _ content: @escaping () -> Content) {
    self.content = { _ in
      content()
    }
  }

  func onButtonPress(_ action: @escaping (Controller.Button) -> Void) -> Self {
    appendingAction(to: \.onButtonPress, action)
  }

  func onButtonRelease(_ action: @escaping (Controller.Button) -> Void) -> Self {
    appendingAction(to: \.onButtonRelease, action)
  }

  func onThumbstickMove(
    _ action: @escaping (Controller.Thumbstick, _ x: Float, _ y: Float) -> Void
  ) -> Self {
    appendingAction(to: \.onThumbstickMove, action)
  }

  var body: some View {
    content(controllerHub.currentController)
      .onAppear {
        observe(controllerHub.currentController)
      }
      .onChange(of: controllerHub.currentController) { controller in
        observe(controller)
      }
  }

  func observe(_ controller: Controller?) {
    guard let controller = controller else {
      cancellable = nil
      return
    }

    cancellable = controller.eventPublisher.sink { event in
      switch event {
        case let .buttonPressed(button):
          onButtonPress?(button)
        case let .buttonReleased(button):
          onButtonRelease?(button)
        case let .thumbstickMoved(thumbstick, x, y):
          onThumbstickMove?(thumbstick, x, y)
      }
    }
  }
}
