import SwiftUI
import DeltaCore
import DeltaRenderer

/// A helper view which can be used to create a render coordinator for a client
/// without having to introduce additional loading states into views.
struct WithRenderCoordinator<Content: View>: View {
  var client: Client
  var content: (RenderCoordinator) -> Content

  init(for client: Client, @ViewBuilder content: @escaping (RenderCoordinator) -> Content) {
    self.client = client
    self.content = content
  }

  @State var renderCoordinator: RenderCoordinator?

  var body: some View {
    VStack {
      if let renderCoordinator = renderCoordinator {
        content(renderCoordinator)
      } else {
        Text("Creating render coordinator")
      }
    }
    .onAppear {
      renderCoordinator = RenderCoordinator(client)
    }
  }
}
