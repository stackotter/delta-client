import SwiftUI
import Combine

struct WithController<Content: View>: View {
  @State var cancellable: AnyCancellable?
  /// If `false`, events aren't passed on to registered listeners.
  @Binding var listening: Bool

  var controller: Controller?
  var content: () -> Content

  private var onButtonPress: ((Controller.Button) -> Void)?
  private var onButtonRelease: ((Controller.Button) -> Void)?
  private var onThumbstickMove: ((Controller.Thumbstick, _ x: Float, _ y: Float) -> Void)?

  init(
    _ controller: Controller?,
    listening: Binding<Bool>,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.controller = controller
    _listening = listening
    self.content = content
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
    content()
      .onAppear {
        observe(controller)
      }
      .onChange(of: controller) { controller in
        observe(controller)
      }
  }

  func observe(_ controller: Controller?) {
    guard let controller = controller else {
      cancellable = nil
      return
    }

    cancellable = controller.eventPublisher.sink { event in
      guard listening else {
        return
      }

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
