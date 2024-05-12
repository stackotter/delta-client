import SwiftUI
import DeltaCore
import DeltaRenderer

/// A helper view which can be used to create a render coordinator for a client
/// without having to introduce additional loading states into views.
struct WithRenderCoordinator<Content: View>: View {
  var client: Client
  var content: (RenderCoordinator) -> Content
  var cancel: () -> Void

  init(for client: Client, @ViewBuilder content: @escaping (RenderCoordinator?) -> Content, cancellationHandler cancel: @escaping () -> Void) {
    self.client = client
    self.content = content
    self.cancel = cancel
  }

  @State var renderCoordinator: RenderCoordinator?
  @State var renderCoordinatorError: RendererError?

  var body: some View {
    VStack {
      if let renderCoordinator = renderCoordinator {
        content(renderCoordinator)
      } else {
        if let error = renderCoordinatorError {
          Text(error.localizedDescription)
          
          Button("Done", action: cancel)
            .buttonStyle(SecondaryButtonStyle())
            .frame(width: 150)
        } else {
          Text("Creating render coordinator")
        }
      }
    }
    .onAppear {
      do {
        try renderCoordinator = RenderCoordinator(client)
      } catch {
        // The only errors thrown in the RenderCoordinator constructor are of type RendererError
        if let rendererError = error as? RendererError {
          renderCoordinatorError = rendererError
        }
      }
    }
  }
}
